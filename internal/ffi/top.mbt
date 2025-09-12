///|
pub extern "wasm" fn free(position : Int) =
  #|(func (param i32) local.get 0 i32.const 8 i32.sub call $moonbit.decref)

///|
#owned(str)
pub extern "wasm" fn str2ptr(str : String) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.add)

///|
#owned(bytes)
pub extern "wasm" fn byte_array2ptr(bytes : FixedArray[Byte]) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.add)

///|
#owned(array)
pub extern "wasm" fn uint_array2ptr(array : FixedArray[UInt]) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.add)

///|
#owned(array)
pub extern "wasm" fn uint64_array2ptr(array : FixedArray[UInt64]) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.add)

///|
#owned(array)
pub extern "wasm" fn int_array2ptr(array : FixedArray[Int]) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.add)

///|
#owned(array)
pub extern "wasm" fn int64_array2ptr(array : FixedArray[Int64]) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.add)

///|
#owned(array)
pub extern "wasm" fn float_array2ptr(array : FixedArray[Float]) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.add)

///|
#owned(array)
pub extern "wasm" fn double_array2ptr(array : FixedArray[Double]) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.add)

///|
#owned(bytes)
pub extern "wasm" fn bytes2ptr(bytes : Bytes) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.const 8 i32.add)
