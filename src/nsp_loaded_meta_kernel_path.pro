function nsp_loaded_meta_kernel_path, set_value=set_value, clear=clear
  compile_opt strictarr

  common nsp_pipeline_state_common, stored_meta_kernel_path

  if keyword_set(clear) then begin
    stored_meta_kernel_path = ''
  endif

  if arg_present(set_value) then begin
    stored_meta_kernel_path = strtrim(set_value, 2)
  endif

  if n_elements(stored_meta_kernel_path) eq 0 then stored_meta_kernel_path = ''

  return, stored_meta_kernel_path
end
