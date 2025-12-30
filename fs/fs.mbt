///|
pub(all) enum FileKind {
  Unknown
  Regular
  Directory
  SymLink
  Socket
  Pipe
  BlockDevice
  CharDevice
} derive(Eq, Show)

///|
pub(all) enum Mode {
  ReadOnly
  WriteOnly
  ReadWrite
}

///|
pub(all) enum SyncMode {
  NoSync
  Data
  Full
}

///|
fn normalize_path(path : StringView) -> String {
  let p = path.to_string()
  if p.has_prefix("/") {
    p
  } else {
    "/" + p
  }
}

///|
fn get_preopened_dirs() -> Array[(String, @wasi.Fd)] raise @wasi.Errno {
  let dirs = []
  for fd = 3; ; fd = fd + 1 {
    let _prestat = @wasi.Fd(fd).fd_prestat_get()
    let dir_name = @wasi.Fd(fd).fd_prestat_dir_name()
    let normalized_dir = if dir_name.has_prefix("/") {
      dir_name
    } else {
      "/" + dir_name
    }
    dirs.push((normalized_dir, @wasi.Fd(fd)))
  }
  dirs
}

///|
pub fn resolve_path(path : StringView) -> (@wasi.Fd, String) raise @wasi.Errno {
  let normalized = normalize_path(path)
  let preopened_dirs = get_preopened_dirs()
  let mut best_fd = @wasi.Fd(0)
  let mut best_path : String = ""
  let mut best_len = 0
  for i in 0..<preopened_dirs.length() {
    let dir_name = preopened_dirs[i].0
    let fd = preopened_dirs[i].1
    if normalized.has_prefix(dir_name) {
      let len = dir_name.length()
      if len > best_len {
        best_fd = fd
        if len == normalized.length() {
          best_path = "."
        } else {
          let normalized_str = normalized.to_string()
          let bytes = @encoding/utf8.encode(normalized_str)
          best_path = @encoding/utf8.decode(bytes[len:]) catch {
            _ => raise @wasi.Ilseq
          }
        }
        best_len = len
      }
    }
  }
  if best_len == 0 {
    raise @wasi.Noent
  }
  let relative : String = if best_path.strip_prefix("/") is Some(str) {
    str.to_string()
  } else {
    best_path
  }
  (best_fd, relative)
}

///|
///|
pub fn open_sync(
  path : StringView,
  mode? : Mode = ReadOnly,
  sync? : SyncMode = NoSync,
  append? : Bool = false,
  create? : Int,
  truncate? : Bool = false,
) -> File raise @wasi.Errno {
  let (base_fd, relative_path) = resolve_path(path)
  let rights = match mode {
    ReadOnly =>
      @wasi.Rights::new()
      |> @wasi.Rights::set(@wasi.Right::Fd_read)
      |> @wasi.Rights::set(@wasi.Right::Path_filestat_get)
    WriteOnly =>
      @wasi.Rights::new()
      |> @wasi.Rights::set(@wasi.Right::Fd_write)
      |> @wasi.Rights::set(@wasi.Right::Path_filestat_get)
      |> @wasi.Rights::set(@wasi.Right::Fd_filestat_set_size)
    ReadWrite =>
      @wasi.Rights::new()
      |> @wasi.Rights::set(@wasi.Right::Fd_read)
      |> @wasi.Rights::set(@wasi.Right::Fd_write)
      |> @wasi.Rights::set(@wasi.Right::Path_filestat_get)
      |> @wasi.Rights::set(@wasi.Right::Fd_filestat_set_size)
      |> @wasi.Rights::set(@wasi.Right::Fd_seek)
  }
  let rights_inheriting = @wasi.Rights::new()
    |> @wasi.Rights::set(@wasi.Right::Fd_read)
    |> @wasi.Rights::set(@wasi.Right::Fd_write)
  let mut oflags = @wasi.OpenFlags::new()
  if create is Some(_) {
    oflags = oflags |> @wasi.OpenFlags::set(@wasi.OpenFlag::Create)
  }
  if truncate {
    oflags = oflags |> @wasi.OpenFlags::set(@wasi.OpenFlag::Trunc)
  }
  let mut fdflags = @wasi.FdFlags::new()
  if append {
    fdflags = fdflags |> @wasi.FdFlags::set(@wasi.FdFlag::Append)
  }
  if sync is Data {
    fdflags = fdflags |> @wasi.FdFlags::set(@wasi.FdFlag::Dsync)
  } else if sync is Full {
    fdflags = fdflags |> @wasi.FdFlags::set(@wasi.FdFlag::Sync)
  }
  let fd = base_fd.path_open(
    @wasi.LookupFlags::new(),
    relative_path,
    oflags,
    rights,
    rights_inheriting,
    fdflags,
  )
  File::{ fd, read_buf: @async_io.ReaderBuffer::new() }
}

///|
struct File {
  fd : @wasi.Fd
  read_buf : @async_io.ReaderBuffer
}

///|
pub fn open(
  path : StringView,
  mode~ : Mode,
  sync? : SyncMode = NoSync,
  append? : Bool = false,
  create? : Int,
  truncate? : Bool = false,
) -> File raise @wasi.Errno {
  match create {
    Some(value) => open_sync(path, mode~, sync~, append~, create=value, truncate~)
    None => open_sync(path, mode~, sync~, append~, truncate~)
  }
}

///|
pub fn create(
  path : StringView,
  permission~ : Int,
  sync? : SyncMode = NoSync,
) -> File raise @wasi.Errno {
  open(path, mode=ReadWrite, sync~, create=permission, truncate=true)
}

///|
pub fn File::close(self : File) -> Unit {
  self.fd.fd_close() catch {
    _ => ()
  }
}

///|
pub fn File::fd(self : File) -> Int {
  self.fd.0
}

///|
pub impl @async_io.Reader for File with _get_internal_buffer(self) {
  self.read_buf
}

///|
pub impl @async_io.Reader for File with _direct_read(
  self,
  buf,
  offset~,
  max_len~,
) {
  let available = @event_loop.suspend_for_read(self.fd)
  let len = @cmp.minimum(available, max_len.to_uint64()).to_int()
  let buffer = FixedArray::make(len, b'\x00')
  let result = self.fd.fd_read([buffer]).0.reinterpret_as_int()
  buffer.blit_to(buf, len=result, dst_offset=offset)
  result
}

///|
pub impl @async_io.Writer for File with write_once(self, data, offset~, len~) {
  let available = @event_loop.suspend_for_write(self.fd)
  let write_len = @cmp.minimum(available, len.to_uint64()).to_int()
  let iovs = [data[offset:offset + write_len]]
  let result = self.fd.fd_write(iovs)
  result.0.reinterpret_as_int()
}

///|
pub impl @sync_io.Reader for File with _get_internal_buffer(self) {
  let _ = self
  @sync_io.ReaderBuffer::new()
}

///|
pub impl @sync_io.Reader for File with _direct_read(
  self,
  buf,
  offset~,
  max_len~,
) {
  let buffer = FixedArray::make(max_len, b'\x00')
  let iovs = [buf]
  let result = self.fd.fd_read(iovs).0.reinterpret_as_int()
  buffer.blit_to(buf, len=result, dst_offset=offset)
  result
}

///|
pub impl @sync_io.Writer for File with write_once(self, data, offset~, len~) {
  let iovs = [data[offset:offset + len]]
  let result = self.fd.fd_write(iovs)
  result.0.reinterpret_as_int()
}

///|
struct Directory {
  fd : @wasi.Fd
}

///|
pub fn opendir(path : StringView) -> Directory raise @wasi.Errno {
  let (base_fd, relative_path) = resolve_path(path)
  let rights = @wasi.Rights::new()
    |> @wasi.Rights::set(@wasi.Right::Fd_read)
    |> @wasi.Rights::set(@wasi.Right::Fd_readdir)
  let oflags = @wasi.OpenFlags::new()
    |> @wasi.OpenFlags::set(@wasi.OpenFlag::Directory)
  let fd = base_fd.path_open(
    @wasi.LookupFlags::new(),
    relative_path,
    oflags,
    rights,
    rights,
    @wasi.FdFlags::new(),
  )
  Directory::{ fd, }
}

///|
pub fn Directory::close(self : Directory) -> Unit {
  self.fd.fd_close() catch {
    _ => ()
  }
}

///|
pub async fn read_file(
  path : StringView,
  sync_timestamp? : Bool,
) -> &@async_io.Data {
  let _ = sync_timestamp
  let file = try open(path, mode=ReadOnly) catch {
    e => fail("read_file failed: \{e}")
  }
  defer file.close()
  @async_io.Reader::read_all(file)
}

///|
pub async fn write_file(
  path : StringView,
  data : &@async_io.Data,
  sync? : SyncMode = NoSync,
  append? : Bool = false,
  create? : Int,
  truncate? : Bool = false,
) -> Unit {
  let file = try {
    match create {
      Some(value) =>
        open(path, mode=WriteOnly, sync~, append~, create=value, truncate~)
      None => open(path, mode=WriteOnly, sync~, append~, truncate~)
    }
  } catch {
    e => fail("write_file failed: \{e}")
  }
  defer file.close()
  @async_io.Writer::write(file, data)
}

///|
fn convert_timestamp(ts : @wasi.TimeStamp) -> (Int64, Int) {
  let nanos = ts.0
  let secs = nanos / 1000000000UL
  let remainder = nanos % 1000000000UL
  (secs.reinterpret_as_int64(), remainder.to_int())
}

///|
fn filetype_to_filekind(ft : @wasi.FileType) -> FileKind {
  match ft {
    @wasi.FileType::Unknown => FileKind::Unknown
    @wasi.FileType::Block_device => FileKind::BlockDevice
    @wasi.FileType::Character_device => FileKind::CharDevice
    @wasi.FileType::Directory => FileKind::Directory
    @wasi.FileType::Regular_file => FileKind::Regular
    @wasi.FileType::Socket_dgram => FileKind::Socket
    @wasi.FileType::Socket_stream => FileKind::Socket
    @wasi.FileType::Symbolic_link => FileKind::SymLink
  }
}

///|
fn get_filestat(
  path : StringView,
  follow_symlink : Bool,
) -> @wasi.FileStat raise @wasi.Errno {
  let (base_fd, relative_path) = resolve_path(path)
  let lookup_flags = if follow_symlink {
    @wasi.LookupFlags::new()
    |> @wasi.LookupFlags::set(@wasi.LookupFlag::Symlink_follow)
  } else {
    @wasi.LookupFlags::new()
  }
  base_fd.path_filestat_get(lookup_flags, relative_path)
}

///|
pub fn atime(
  path : StringView,
  follow_symlink? : Bool = true,
) -> (Int64, Int) raise @wasi.Errno {
  let stat = get_filestat(path, follow_symlink)
  convert_timestamp(stat.atim)
}

///|
pub fn ctime(
  path : StringView,
  follow_symlink? : Bool = true,
) -> (Int64, Int) raise @wasi.Errno {
  let stat = get_filestat(path, follow_symlink)
  convert_timestamp(stat.ctim)
}

///|
pub fn mtime(
  path : StringView,
  follow_symlink? : Bool = true,
) -> (Int64, Int) raise @wasi.Errno {
  let stat = get_filestat(path, follow_symlink)
  convert_timestamp(stat.mtim)
}

///|
pub fn exists(path : StringView) -> Bool {
  try {
    let _ = get_filestat(path, true)
    true
  } catch {
    _ => false
  }
}

///|
pub fn kind(
  path : StringView,
  follow_symlink? : Bool = true,
) -> FileKind raise @wasi.Errno {
  let stat = get_filestat(path, follow_symlink)
  filetype_to_filekind(stat.filetype)
}

///|
pub fn mkdir(
  path : StringView,
  permission~ : Int,
) -> Unit raise @wasi.Errno {
  let (base_fd, relative_path) = resolve_path(path)
  let _permission = permission
  base_fd.path_create_directory(relative_path)
}

///|
pub fn remove(path : StringView) -> Unit raise @wasi.Errno {
  let file_kind = kind(path, follow_symlink=false)
  let (base_fd, relative_path) = resolve_path(path)
  if file_kind is FileKind::Directory {
    base_fd.path_remove_directory(relative_path)
  } else {
    base_fd.path_unlink_file(relative_path)
  }
}

///|
pub fn rmdir(
  path : StringView,
  recursive? : Bool = false,
) -> Unit raise @wasi.Errno {
  if recursive {
    let entries = readdir(
      path,
      include_hidden=true,
      include_special=true,
      sort=false,
    )
    for entry in entries {
      let entry_path = path.to_string() + "/" + entry
      remove(entry_path) catch {
        _ => ()
      }
    }
  }
  let (base_fd, relative_path) = resolve_path(path)
  base_fd.path_remove_directory(relative_path)
}

///|
pub fn readdir(
  path : StringView,
  include_hidden? : Bool = true,
  include_special? : Bool = false,
  sort? : Bool = false,
) -> Array[String] raise @wasi.Errno {
  let dir = opendir(path)
  let result : Array[String] = []
  let entries_tuple = dir.fd.fd_readdir()
  for entry in entries_tuple.0 {
    let name = entry.0
    if name == "." || name == ".." {
      continue
    }
    if !include_hidden && name.has_prefix(".") {
      continue
    }
    if !include_special {
      let entry_path = path.to_string() + "/" + name
      let entry_kind = kind(entry_path, follow_symlink=false) catch {
        _ => FileKind::Unknown
      }
      if entry_kind is FileKind::Socket {
        continue
      }
      if entry_kind is FileKind::Pipe {
        continue
      }
    }
    result.push(name)
  }
  dir.close()
  if sort {
    result.sort()
  }
  result
}

///|
pub fn symlink(
  target~ : StringView,
  path : StringView,
) -> Unit raise @wasi.Errno {
  let (base_fd, relative_path) = resolve_path(path)
  @wasi.path_symlink(target.to_string(), base_fd, relative_path)
}

///|
pub fn realpath(path : StringView) -> String {
  normalize_path(path)
}

///|
async fn walk_inner(
  path : String,
  visitor : async (String, Array[String]) -> Unit,
  allow_failure : Bool,
) -> Unit {
  let entries = readdir(
    path,
    include_hidden=true,
    include_special=true,
    sort=false,
  ) catch {
    e => if allow_failure { return } else { fail("walk failed: \{e}") }
  }
  visitor(path, entries)
  for entry in entries {
    let entry_path = path + "/" + entry
    let entry_kind = kind(entry_path, follow_symlink=false) catch {
      e =>
        if allow_failure {
          FileKind::Unknown
        } else {
          fail("walk failed: \{e}")
        }
    }
    if entry_kind is FileKind::Directory {
      walk_inner(entry_path, visitor, allow_failure)
    }
  }
}

///|
pub async fn walk(
  path : StringView,
  visitor : async (String, Array[String]) -> Unit,
  max_concurrency? : Int,
  allow_failure? : Bool,
) -> Unit {
  let _ = max_concurrency
  let allow_failure = match allow_failure {
    Some(value) => value
    None => false
  }
  let normalized = normalize_path(path)
  walk_inner(normalized, visitor, allow_failure)
}

///|
pub fn readlink(path : StringView) -> String raise @wasi.Errno {
  let (base_fd, relative_path) = resolve_path(path)
  let size = base_fd.path_readlink(relative_path)
  size.to_string()
}

///|
pub fn chmod(path : StringView, mode : Int) -> Unit {
  let _ = path
  let _ = mode

}

///|
pub fn can_execute(path : StringView) -> Bool {
  try {
    let file = open_sync(path, mode=ReadOnly)
    file.close()
    true
  } catch {
    _ => false
  }
}

///|
pub fn can_read(path : StringView) -> Bool {
  try {
    let file = open_sync(path, mode=ReadOnly)
    file.close()
    true
  } catch {
    _ => false
  }
}

///|
pub fn can_write(path : StringView) -> Bool {
  try {
    let file = open_sync(path, mode=WriteOnly)
    file.close()
    true
  } catch {
    _ => false
  }
}

///|
///|
pub fn read_file_sync(path : StringView) -> Bytes raise @wasi.Errno {
  let file = open_sync(path, mode=ReadOnly)
  let buffer_size : Int = 8192
  let buffer = FixedArray::make(buffer_size, b'\x00')
  let mut data : Bytes = ""
  while {
          let iovs = [buffer]
          let size = file.fd.fd_read(iovs)
          let read_len = size.0.reinterpret_as_int()
          data = data +
            buffer.unsafe_reinterpret_as_bytes()[:read_len].to_bytes()
          read_len > 0
        } {

  }
  file.close()
  data
}

///|
pub fn write_file_sync(
  path : StringView,
  data : Bytes,
  sync? : SyncMode = NoSync,
  append? : Bool = false,
  create? : Int,
  truncate? : Bool = false,
) -> Unit raise @wasi.Errno {
  let file = match create {
    Some(value) =>
      open_sync(path, mode=WriteOnly, sync~, append~, create=value, truncate~)
    None => open_sync(path, mode=WriteOnly, sync~, append~, truncate~)
  }
  let iovs = [data[0:data.length()]]
  let _ = file.fd.fd_write(iovs)
  file.close()
}

///|

///|
pub fn File::atime(self : File) -> (Int64, Int) raise @wasi.Errno {
  let stat = self.fd.fd_filestat_get()
  convert_timestamp(stat.atim)
}

///|
pub fn File::ctime(self : File) -> (Int64, Int) raise @wasi.Errno {
  let stat = self.fd.fd_filestat_get()
  convert_timestamp(stat.ctim)
}

///|
pub fn File::mtime(self : File) -> (Int64, Int) raise @wasi.Errno {
  let stat = self.fd.fd_filestat_get()
  convert_timestamp(stat.mtim)
}

///|
pub async fn File::read_at(
  self : File,
  buf : FixedArray[Byte],
  position~ : Int64,
  offset? : Int,
  len? : Int,
) -> Int {
  let start = match offset {
    Some(value) => value
    None => 0
  }
  let max_len = match len {
    Some(value) => value
    None => buf.length() - start
  }
  if max_len <= 0 {
    return 0
  }
  try {
    let available = @event_loop.suspend_for_read(self.fd)
    let read_len = @cmp.minimum(available, max_len.to_uint64()).to_int()
    if read_len <= 0 {
      return 0
    }
    let buffer = FixedArray::make(read_len, b'\x00')
    let size = self.fd.fd_pread(
      [buffer],
      @wasi.FileSize(position.reinterpret_as_uint64()),
    )
    let actual = size.0.reinterpret_as_int()
    buffer.blit_to(buf, len=actual, dst_offset=start)
    actual
  } catch {
    e => fail("read_at failed: \{e}")
  }
}

///|
pub async fn File::read_exactly_at(
  self : File,
  len : Int,
  position~ : Int64,
) -> Bytes {
  if len <= 0 {
    return ""
  }
  let buffer = FixedArray::make(len, b'\x00')
  let mut read_total = 0
  while read_total < len {
    let read_len = self.read_at(
      buffer,
      position=position + read_total.to_int64(),
      offset=read_total,
      len=len - read_total,
    )
    if read_len <= 0 {
      fail("read_exactly_at failed: unexpected EOF")
    }
    read_total = read_total + read_len
  }
  buffer.unsafe_reinterpret_as_bytes()
}

///|
pub fn File::size(self : File) -> Int64 raise @wasi.Errno {
  let stat = self.fd.fd_filestat_get()
  stat.size.0.reinterpret_as_int64()
}

///|
pub fn File::kind(self : File) -> FileKind {
  try {
    let stat = self.fd.fd_filestat_get()
    filetype_to_filekind(stat.filetype)
  } catch {
    _ => FileKind::Unknown
  }
}

///|
pub fn File::sync(self : File, only_data? : Bool = false) -> Unit raise @wasi.Errno {
  if only_data {
    self.fd.fd_datasync()
  } else {
    self.fd.fd_sync()
  }
}

///|
pub async fn File::write_at(
  self : File,
  data : BytesView,
  position~ : Int64,
) -> Unit {
  let len = data.length()
  if len <= 0 {
    return
  }
  let current = self.fd.fd_tell() catch { e => fail("write_at failed: \{e}") }
  try {
    let _ = self.fd.fd_seek(@wasi.FileDelta(position), @wasi.Whence::Set)

  } catch {
    e => fail("write_at failed: \{e}")
  }
  let restore = @wasi.FileDelta(current.0.reinterpret_as_int64())
  let mut err : Error? = None
  try {
    let mut written = 0
    while written < len {
      let available = @event_loop.suspend_for_write(self.fd)
      let write_len = @cmp.minimum(available, (len - written).to_uint64()).to_int()
      if write_len <= 0 {
        break
      }
      let chunk = data[written:written + write_len]
      try {
        let size = self.fd.fd_write([chunk])
        let actual = size.0.reinterpret_as_int()
        if actual <= 0 {
          break
        }
        written = written + actual
      } catch {
        e => {
          err = Some(e)
          break
        }
      }
    }
  } catch {
    e => err = Some(e)
  }
  try {
    let _ = self.fd.fd_seek(restore, @wasi.Whence::Set)

  } catch {
    _ => ()
  }
  if err is Some(e) {
    fail("write_at failed: \{e}")
  }
}

///|
pub fn Directory::read_all(
  self : Directory,
  include_hidden? : Bool = true,
  include_special? : Bool = false,
) -> Array[String] raise @wasi.Errno {
  let result : Array[String] = []
  let entries_tuple = self.fd.fd_readdir()
  for entry in entries_tuple.0 {
    let name = entry.0
    let dir_ent = entry.1
    if name == "." || name == ".." {
      continue
    }
    if !include_hidden && name.has_prefix(".") {
      continue
    }
    if !include_special {
      if dir_ent.d_type is @wasi.FileType::Socket_dgram {
        continue
      }
      if dir_ent.d_type is @wasi.FileType::Socket_stream {
        continue
      }
    }
    result.push(name)
  }
  result
}

///|
pub fn File::as_dir(self : File) -> Directory raise @wasi.Errno {
  let stat = self.fd.fd_filestat_get()
  if not(stat.filetype is @wasi.FileType::Directory) {
    raise @wasi.Notdir
  }
  Directory::{ fd: self.fd }
}
