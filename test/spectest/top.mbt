///|
let buffer : Ref[UInt16] = { val: 0 }

///|
pub fn print_char(ch : UInt16) -> Unit {
  if ch.is_leading_surrogate() {
    if buffer.val.is_surrogate() {
      // No good
      let _ = @wasi.stdout.fd_write([b"�"]) catch { _ => 0 }
      buffer.val = 0
    } else {
      buffer.val = ch
    }
  } else if ch.is_trailing_surrogate() {
    if buffer.val.is_leading_surrogate() {
      let codepoint = (((buffer.val.to_int() - 0xD800) << 10) +
      (ch.to_int() - 0xDC00) +
      0x10000).unsafe_to_char()
      let _ = @wasi.stdout.fd_write([@encoding/utf8.encode("\{codepoint}")]) catch {
        _ => 0
      }
      buffer.val = 0
    } else {
      // No good
      let _ = @wasi.stdout.fd_write([b"�"]) catch { _ => 0 }
      buffer.val = 0
    }
  } else {
    let _ = @wasi.stdout.fd_write([
      @encoding/utf8.encode("\{ch.unsafe_to_char()}"),
    ]) catch {
      _ => 0
    }

  }
}
