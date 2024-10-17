# WASI Preview 1 implementation for MoonBit

⚠️ It's a complete rewrite since 0.17.0

- [x] Wasm Backend
- [ ] Wasm-GC Backend

## Implemented functions

- [x] `args_get`
- [x] `args_sizes_get`
- [x] `environ_get`
- [x] `environ_sizes_get`
- [x] `clock_res_get`
- [x] `clock_time_get`
- [x] `fd_advise`
- [x] `fd_allocate`
- [x] `fd_close`
- [x] `fd_datasync`
- [x] `fd_fdstat_get`
- [x] `fd_fdstat_set_flags`
- [x] `fd_fdstat_set_rights`
- [x] `fd_filestat_get`
- [ ] `fd_filestat_set_size`
- [ ] `fd_filestat_set_times`
- [x] `fd_pread`
- [x] `fd_prestat_get`
- [x] `fd_prestat_dir_name`
- [x] `fd_pwrite`
- [x] `fd_read`
- [x] `fd_readdir`
- [x] `fd_renumber`
- [x] `fd_seek`
- [x] `fd_sync`
- [x] `fd_tell`
- [x] `fd_write`
- [x] `path_create_directory`
- [x] `path_filestat_get`
- [x] `path_filestat_set_times`
- [x] `path_link`
- [x] `path_open`
- [x] `path_readlink`
- [x] `path_remove_directory`
- [x] `path_rename`
- [x] `path_symlink`
- [x] `path_unlink_file`
- [ ] `poll_oneoff`
- [x] `proc_exit`
- [ ] `proc_raise`
- [ ] `sched_yield`
- [x] `random_get`
- [ ] `sock_accept`
- [ ] `sock_recv`
- [ ] `sock_send`
- [ ] `sock_shutdown`

## Develop

### Testing

- Requirements: you need wasmtime & deno. You may use wasmedge or wamr if you replace the `wasmtime` in `test.ts`, but it may cause different testing result.
- Comamnds: `deno task test:build && deno task test`