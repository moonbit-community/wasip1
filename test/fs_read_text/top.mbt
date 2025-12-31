///|
pub fn start() -> Unit {
  let path = "fixtures/hello.txt"
  let bytes = try {
    let data = @fs.read_file_sync(path)
    data.binary()
  } catch {
    e => {
      try! @stdio.stderr.write_sync("\{e}\n")
      @wasi.proc_exit(1)
      b""
    }
  }
  try! @stdio.stdout.write_sync(bytes)
}
