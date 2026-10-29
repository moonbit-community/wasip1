///|
pub fn start() -> Unit {
  let stdin = @wasi.Fd(0)
  let buffer1 = FixedArray::make(64, b'\x00')
  let buffer2 = FixedArray::make(64, b'\x00')
  guard (Ok(stdin.fd_read([buffer1, buffer2])) catch { e => Err(e) }) is Ok(len)
  let buffer = FixedArray::make(len.0.reinterpret_as_int(), b'\x00')
  if len.0 <= 64 {
    buffer1.blit_to(buffer, len=len.0.reinterpret_as_int())
    (Ok(@wasi.Fd(1).fd_write([Bytes::from_array(buffer)])) catch {
      e => Err(e)
    })
    |> ignore
  } else if len.0 <= 128 {
    let buffer = FixedArray::make(len.0.reinterpret_as_int(), b'\x00')
    buffer1.blit_to(buffer, len=64)
    buffer2.blit_to(buffer, len=len.0.reinterpret_as_int() - 64, dst_offset=64)
    (Ok(@wasi.Fd(1).fd_write([Bytes::from_array(buffer)])) catch {
      e => Err(e)
    })
    |> ignore
  } else {
    (Ok(@wasi.Fd(1).fd_write(["Input too long\n" |> @utf8.encode()])) catch {
      e => Err(e)
    })
    |> ignore
  }
}
