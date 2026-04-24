///|
pub fn start() -> Unit {
  let entries = @fs.readdir(
    "fixtures",
    include_hidden=true,
    include_special=true,
    sort=true,
  ) catch {
    e => {
      try! @stdio.stderr.write_sync("\{Debug::to_repr(e)}\n")
      @wasi.proc_exit(1)
    }
  }
  let output = "\{entries}\n"
  let bytes = @utf8.encode(output)
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
