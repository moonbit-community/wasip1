///|
pub fn start() -> Unit {
  let file_kind = try {
    @fs.kind("fixtures/hello.txt")
  } catch {
    e => {
      try! @sync_stdio.stderr.write("\{e}\n")
      @wasi.proc_exit(1)
      @fs.FileKind::Unknown
    }
  }
  let dir_kind = try {
    @fs.kind("fixtures")
  } catch {
    e => {
      try! @sync_stdio.stderr.write("\{e}\n")
      @wasi.proc_exit(1)
      @fs.FileKind::Unknown
    }
  }
  let output = "file=\{file_kind},dir=\{dir_kind}\n"
  let bytes = @encoding/utf8.encode(output)
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
