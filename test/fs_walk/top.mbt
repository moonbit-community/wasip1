///|
pub async fn run() -> Unit {
  let paths : Array[String] = []
  @fs.walk("fixtures/walk", async fn(dir, entries) {
    let names = entries
    names.sort()
    for entry in names {
      paths.push("\{dir}/\{entry}")
    }
  })
  paths.sort()
  @stdio.stdout.write_sync(paths.join("\n") + "\n")
}

///|
pub fn start() -> Unit {
  @async.with_event_loop(fn(_) { run() }) catch {
    e => {
      try! @stdio.stderr.write_sync("\{e}\n")
      @wasi.proc_exit(1)
    }
  }
}
