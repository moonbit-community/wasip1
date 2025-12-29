///|
fn main {
  @async.with_event_loop(_ => @stdio.stdout.write("Hello, World!\n")) catch {
    e => {
      try! @sync_stdio.stderr.write("\{e}\n")
      @wasi.proc_exit(1)
    }
  }
}
