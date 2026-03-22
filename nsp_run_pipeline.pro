pro nsp_run_pipeline, meta_kernel_name=meta_kernel_name
  compile_opt strictarr

  src_directory = file_expand_path('src')
  path_with_separators = ':' + !PATH + ':'
  src_with_separators = ':' + src_directory + ':'

  if ~file_test(src_directory, /DIRECTORY) then begin
    message, 'nsp_run_pipeline failed: required source directory was not found relative to the current working directory: ' + src_directory, /NONAME
  endif

  if strpos(path_with_separators, src_with_separators) lt 0 then begin
    !PATH = src_directory + ':' + !PATH
  endif

  nsp_validate_environment
  nsp_resolve_kernels, meta_kernel_name=meta_kernel_name, resolved_meta_kernel=resolved_meta_kernel
  nsp_load_kernels, resolved_meta_kernel, kernel_count=kernel_count
end
