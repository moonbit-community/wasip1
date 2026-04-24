///|
pub fn start() -> Unit {
  let stdout = @wasi.Fd(1)
  let stdout_stat = try! stdout.fd_fdstat_get()
  (try? stdout.fd_write(["\{Debug::to_repr(stdout_stat)}\n" |> @utf8.encode()]))
  |> ignore
  let test_dir = @wasi.Fd(3)
  let test_dir_stat = try! test_dir.fd_fdstat_get()
  (try? stdout.fd_write(["\{Debug::to_repr(test_dir_stat)}\n" |> @utf8.encode()]))
  |> ignore
}
