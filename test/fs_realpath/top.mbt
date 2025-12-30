///|
pub fn start() -> Unit {
  let resolved = @fs.realpath("fixtures/hello.txt")
  let bytes = @encoding/utf8.encode(resolved + "\n")
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
