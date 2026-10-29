///|
pub fn start() -> Unit {
  let ret = Ok(@wasi.Fd(1).fd_write([b"Hello\n", b"World", b"!\n"])) catch {
    e => Err(e)
  }
  match ret {
    Ok(len) =>
      (Ok(@wasi.Fd(1).fd_write(["\{Debug::to_repr(len)}" |> @utf8.encode()])) catch {
        e => Err(e)
      })
      |> ignore
    Err(err) => err.value() |> @wasi.proc_exit
  }
}
