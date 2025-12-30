///|
pub fn start() -> Unit {
  @fs.chmod("fixtures/hello.txt", 420)
  let bytes = @encoding/utf8.encode("ok\n")
  (try? @wasi.stdout.fd_write([bytes])) |> ignore
}
