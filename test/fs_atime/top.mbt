///|
pub fn start() -> Unit {
  try {
    let _ = @fs.atime("fixtures/hello.txt")
  } catch {
    e => {
      try! @sync_stdio.stderr.write("\{e}\n")
      @wasi.proc_exit(1)
    }
  }
  let bytes = @encoding/utf8.encode("ok\n")
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
