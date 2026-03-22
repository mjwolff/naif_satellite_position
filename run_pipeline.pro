pro run_pipeline, meta_kernel_name=meta_kernel_name
  compile_opt strictarr

  validate_environment
  resolve_kernels, meta_kernel_name=meta_kernel_name, resolved_meta_kernel=resolved_meta_kernel
  load_kernels, resolved_meta_kernel, kernel_count=kernel_count
end
