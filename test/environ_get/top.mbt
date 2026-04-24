///|
pub fn start() -> Unit {
  let (envc, size) = try! @wasi.environ_sizes_get()
  try! assert_eq(envc, 1)
  try! assert_eq(size, 12)
  let args = try! @wasi.environ_get()
  try! assert_eq(args, [("hello", "world")])
}
