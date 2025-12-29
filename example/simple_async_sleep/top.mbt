///|
fn main {
  @async.with_event_loop(_ => @async.sleep(1000)) catch {
    _ => @wasi.proc_exit(1)
  }
}
