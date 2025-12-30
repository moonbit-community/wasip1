///|
pub fn start() -> Unit {
  let path = "fixtures/hello.txt"
  let bytes = try {
    let data = @fs.read_file_sync(path)
    data.binary()
  } catch {
    e => {
      try! @sync_stdio.stderr.write("\{e}\n")
      @wasi.proc_exit(1)
      b""
    }
  }
  try! @sync_stdio.stdout.write(bytes)
}
