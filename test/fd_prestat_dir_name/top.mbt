///|
pub fn start() -> Unit {
  for i = 3; ; i = i + 1 {
    try {
      let fd = @wasi.Fd(i).fd_prestat_dir_name()
      (try? @wasi.Fd(1).fd_write([
        "Accessing \{i} got \{fd}\n" |> @encoding/utf8.encode(),
      ]))
      |> ignore
    } catch {
      errno => {
        (try? @wasi.Fd(1).fd_write([
          "Error: Accessing \{i} got \{errno}\n"
          |> @encoding/utf8.encode(),
        ]))
        |> ignore
        break
      }
    }
  }
}
