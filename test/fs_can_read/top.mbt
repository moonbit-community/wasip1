///|
pub fn start() -> Unit {
  let a = @fs.can_read("fixtures/hello.txt")
  let b = @fs.can_read("fixtures/missing.txt")
  let output = "\{a},\{b}\n"
  let bytes = @encoding/utf8.encode(output)
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
