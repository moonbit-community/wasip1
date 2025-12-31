///|
pub fn start() -> Unit {
  try {
    let _ = @fs.atime("fixtures/hello.txt")

  } catch {
    e => {
      try! @sync_stdio.stderr.write_sync("\{e}\n")
      @wasi.proc_exit(1)
    }
  }
  try! @sync_stdio.stdout.write_sync("ok\n")
}
