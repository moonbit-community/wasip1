///|
pub fn start() -> Unit {
  let a = @fs.can_execute("fixtures/hello.txt")
  let b = @fs.can_execute("fixtures/missing.txt")
  let output = "\{a},\{b}\n"
  let bytes = @encoding/utf8.encode(output)
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
