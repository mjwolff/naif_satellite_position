pro nsp_run_pipeline, meta_kernel_name=meta_kernel_name, icy_dlm_path=icy_dlm_path, debug=debug
  compile_opt strictarr

  nsp_setup_path

  kernel_path_value = strtrim(getenv('KERNEL_PATH'), 2)
  if (kernel_path_value eq '') and keyword_set(debug) then begin
    kernel_path_value = '/Volumes/Wolff_misc1/nomad_naif/tgo_kernels/'
  endif

  nsp_validate_environment, icy_dlm_path=icy_dlm_path, debug=debug
  nsp_resolve_kernels, meta_kernel_name=meta_kernel_name, kernel_path=kernel_path_value, resolved_meta_kernel=resolved_meta_kernel
  nsp_load_kernels, resolved_meta_kernel, kernel_count=kernel_count, icy_dlm_path=icy_dlm_path
end
