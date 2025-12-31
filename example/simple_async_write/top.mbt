///|
fn main {
  @async.with_event_loop(_ => @stdio.stdout.write("Hello, World!\n")) catch {
    e => {
      try! @stdio.stderr.write_sync("\{e}\n")
      @wasi.proc_exit(1)
    }
  }
}
