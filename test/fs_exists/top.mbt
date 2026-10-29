///|
pub fn start() -> Unit {
  let a = @fs.exists("fixtures/hello.txt")
  let b = @fs.exists("fixtures/missing.txt")
  let output = "\{a},\{b}\n"
  let bytes = @utf8.encode(output)
  (Ok(@wasi.stdout.fd_write([bytes])) catch { e => Err(e) }) |> ignore
}
