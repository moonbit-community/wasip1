///|
pub fn start() -> Unit {
  let a = @fs.exists("fixtures/hello.txt")
  let b = @fs.exists("fixtures/missing.txt")
  let output = "\{a},\{b}\n"
  let bytes = @encoding/utf8.encode(output)
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
