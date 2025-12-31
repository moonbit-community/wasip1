///|
pub fn start() -> Unit {
  try {
    let _ = @fs.atime("fixtures/hello.txt")

  } catch {
    e => {
      try! @stdio.stderr.write_sync("\{e}\n")
      @wasi.proc_exit(1)
    }
  }
  try! @stdio.stdout.write_sync("ok\n")
}
