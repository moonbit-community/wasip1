///|
pub fn start() -> Unit {
  try {
    let base = "test/fs_tmp"
    @fs.rmdir(base, recursive=true)
    @fs.mkdir(base, permission=493)
    let file_path = base + "/hello.txt"
    @fs.write_file_sync(file_path, "hello", create=420, truncate=true)
    let sync_text = @fs.read_file_sync(file_path).text() catch {
      _ => "<decode error>"
    }
    let dir_entries = @fs.readdir(
      base,
      include_hidden=true,
      include_special=true,
      sort=true,
    )
    let dir = @fs.opendir(base)
    defer dir.close()
    let read_all_entries = dir.read_all(
      include_hidden=true,
      include_special=true,
    )
    read_all_entries.sort()
    let file = @fs.open(file_path, mode=ReadOnly)
    let sync_size = file.size()
    let sync_kind = file.kind()
    file.close()
    let async_path = base + "/async.txt"
    let mut async_text = ""
    let mut async_read_at = ""
    @async.with_event_loop(_ => {
      @fs.write_file(async_path, "async-data", create=420, truncate=true)
      let data = @fs.read_file(async_path)
      async_text = data.text() catch { _ => "<decode error>" }
      let async_file = @fs.open(async_path, mode=ReadOnly)
      let bytes = async_file.read_exactly_at(5, position=0)
      async_read_at = @encoding/utf8.decode(bytes) catch {
        _ => "<decode error>"
      }
      async_file.close()
    }) catch {
      e => {
        try! @sync_stdio.stderr.write("\{e}\n")
        @wasi.proc_exit(1)
      }
    }
    let output =
      $|sync_text: \{sync_text}
      $|sync_size: \{sync_size}
      $|sync_kind: \{sync_kind}
      $|dir_readdir: \{dir_entries}
      $|dir_read_all: \{read_all_entries}
      $|async_text: \{async_text}
      $|async_read_at: \{async_read_at}
      $|
    (try? @sync_stdio.stdout.write(output)) |> ignore
  } catch {
    e => {
      try! @sync_stdio.stderr.write("\{e}\n")
      @wasi.proc_exit(1)
    }
  }
}
