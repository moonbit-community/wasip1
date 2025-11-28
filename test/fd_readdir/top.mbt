///|
pub fn start() -> Unit {
  let test_dir = @wasi.Fd(3)
  let entries = []
  for cookie = @wasi.DirCookie(0) {
    let test_dir_entries = (try? test_dir.fd_readdir(
      buffer=Bytes::new(100),
      cookie~,
    )).unwrap()
    test_dir_entries.0.each(fn(name_entry) {
      let (name, entry) = name_entry
      entries.push("\{name} ~> \{entry.d_type}")
    })
    if test_dir_entries.1 {
      continue @wasi.DirCookie(
          cookie.0 + test_dir_entries.0.length().to_uint64(),
        )
    } else {
      break
    }
  }
  entries.sort()
  (try? @wasi.stdout.fd_write(["\{entries}\n" |> @encoding/utf8.encode()]))
  |> ignore
}
