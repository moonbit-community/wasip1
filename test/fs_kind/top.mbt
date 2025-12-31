///|
pub fn start() -> Unit {
  let file_kind = @fs.kind("fixtures/hello.txt") catch {
    e => {
      try! @stdio.stderr.write_sync("\{e}\n")
      @wasi.proc_exit(1)
      @fs.FileKind::Unknown
    }
  }
  let dir_kind = @fs.kind("fixtures") catch {
    e => {
      try! @stdio.stderr.write_sync("\{e}\n")
      @wasi.proc_exit(1)
      @fs.FileKind::Unknown
    }
  }
  let output = "file=\{file_kind},dir=\{dir_kind}\n"
  let bytes = @encoding/utf8.encode(output)
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
