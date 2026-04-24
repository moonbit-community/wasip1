///|
pub fn start() -> Unit {
  let file_kind = @fs.kind("fixtures/hello.txt") catch {
    e => {
      try! @stdio.stderr.write_sync("\{Debug::to_repr(e)}\n")
      @wasi.proc_exit(1)
    }
  }
  let dir_kind = @fs.kind("fixtures") catch {
    e => {
      try! @stdio.stderr.write_sync("\{Debug::to_repr(e)}\n")
      @wasi.proc_exit(1)
    }
  }
  let output = "file=\{Debug::to_repr(file_kind)},dir=\{Debug::to_repr(dir_kind)}\n"
  let bytes = @utf8.encode(output)
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
