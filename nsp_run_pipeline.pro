pro nsp_run_pipeline, meta_kernel_name=meta_kernel_name, icy_dlm_path=icy_dlm_path
  compile_opt strictarr

  nsp_setup_path

  nsp_validate_environment, icy_dlm_path=icy_dlm_path
  nsp_resolve_kernels, meta_kernel_name=meta_kernel_name, resolved_meta_kernel=resolved_meta_kernel
  nsp_load_kernels, resolved_meta_kernel, kernel_count=kernel_count, icy_dlm_path=icy_dlm_path
end
