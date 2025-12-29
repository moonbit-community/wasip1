///|
let event_loop : Map[Int, Subscribe] = {}

///|
priv struct Subscribe {
  mut event : @wasi.Event?
  sub : @wasi.Subscription
  coro : @coroutine.Coroutine
}

///|
pub async fn suspend_for_write(fd : @wasi.Fd) -> UInt64 {
  let coro = @coroutine.current_coroutine()
  let subscribe = {
    event: None,
    sub: @wasi.Subscription::{
      userdata: coro.id().to_uint64(),
      u: @wasi.Subscription_u::Fd_write({ file_descriptor: fd }),
    },
    coro,
  }
  @coroutine.suspend()
  guard subscribe.event is Some(event)
  if event.fd_readwrite.flags.is_set(@wasi.EventRWFlag::Fd_readwrite_hangup) {
    raise @wasi.Errno::Badf
  }
  event.fd_readwrite.nbytes.0
}

///|
pub async fn suspend_for_read(fd : @wasi.Fd) -> UInt64 {
  let coro = @coroutine.current_coroutine()
  let subscribe = {
    event: None,
    sub: @wasi.Subscription::{
      userdata: coro.id().to_uint64(),
      u: @wasi.Subscription_u::Fd_read({ file_descriptor: fd }),
    },
    coro,
  }
  @coroutine.suspend()
  guard subscribe.event is Some(event)
  if event.fd_readwrite.flags.is_set(@wasi.EventRWFlag::Fd_readwrite_hangup) {
    raise @wasi.Errno::Badf
  }
  event.fd_readwrite.nbytes.0
}

///|
/// sleep in millisecond
pub async fn sleep(time : Int) -> Unit {
  let coro = @coroutine.current_coroutine()
  let subscribe = {
    event: None,
    sub: @wasi.Subscription::{
      userdata: coro.id().to_uint64(),
      u: @wasi.Subscription_u::Clock(@wasi.Subscription_clock::{
        id: @wasi.ClockId::Monotonic,
        timeout: @wasi.TimeStamp(time.to_uint64() * 1000000),
        precision: @wasi.TimeStamp(1000000),
        flags: @wasi.SubclockFlags::new(),
      }),
    },
    coro,
  }
  @coroutine.suspend()
  guard subscribe.event is Some(_)
}

///|

///|
pub fn async_run(f : async () -> Unit) -> Unit {
  let mut err = false
  let _ = @coroutine.spawn(async fn() -> Unit { f() catch { _ => err = true } })
  while !@coroutine.no_more_work() {
    @coroutine.reschedule()
    if event_loop.is_empty() {
      continue
    }
    let values = event_loop.values().map(sub => sub.sub).collect()
    let events = @wasi.poll_oneoff(values) catch {
      _ => {
        @wasi.proc_exit(114)
        panic()
      }
    }
    for e in events {
      let id = e.userdata.0.to_int()
      guard event_loop.get(id) is Some(subscribe)
      event_loop.remove(id)
      subscribe.event = Some(e)
      subscribe.coro.wake()
    }
  }
  if err {
    @wasi.proc_exit(1)
    panic()
  }
}
