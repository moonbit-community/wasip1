///|
pub fn start() -> Unit {
  let (argc, size) = try! @wasi.args_sizes_get()
  try! assert_eq(argc, 1)
  try! assert_eq(size, 14)
  let args = try! @wasi.args_get()
  try! assert_eq(args, ["args_get.wasm"])
}
