function resolve_meta_kernel, meta_kernel_name=meta_kernel_name
  compile_opt strictarr

  kernels_path = strtrim(getenv('KERNELS_PATH'), 2)

  if kernels_path eq '' then begin
    message, 'Step 2 kernel resolution failed: KERNELS_PATH is not set. Run environment validation before kernel resolution.', /NONAME
  endif

  selected_name = 'em16_ops.tm'
  if n_elements(meta_kernel_name) gt 0 then begin
    if strtrim(meta_kernel_name, 2) ne '' then selected_name = strtrim(meta_kernel_name, 2)
  endif

  if strpos(selected_name, '..') ge 0 then begin
    message, 'Step 2 kernel resolution failed: meta-kernel name must not contain "..": ' + selected_name, /NONAME
  endif

  if strmid(selected_name, 0, 1) eq '/' then begin
    message, 'Step 2 kernel resolution failed: meta-kernel must be resolved from KERNELS_PATH, not from an absolute path: ' + selected_name, /NONAME
  endif

  if strpos(selected_name, '/') ge 0 then begin
    candidate_path = file_expand_path(kernels_path + '/' + selected_name)

    if ~file_test(candidate_path, /REGULAR) then begin
      message, 'Step 2 kernel resolution failed: specified meta-kernel was not found beneath KERNELS_PATH: ' + candidate_path, /NONAME
    endif

    if ~file_test(candidate_path, /READ) then begin
      message, 'Step 2 kernel resolution failed: specified meta-kernel is not readable: ' + candidate_path, /NONAME
    endif

    return, candidate_path
  endif

  search_pattern = file_expand_path(kernels_path + '/**/' + selected_name)
  matches = file_search(search_pattern, /FOLD_CASE)
  match_count = n_elements(matches)

  if match_count eq 0 then begin
    message, 'Step 2 kernel resolution failed: no meta-kernel named "' + selected_name + '" was found beneath KERNELS_PATH=' + kernels_path, /NONAME
  endif

  if match_count gt 1 then begin
    sorted_matches = matches[sort(matches)]
    diagnostic = 'Step 2 kernel resolution failed: meta-kernel name "' + selected_name + '" is ambiguous beneath KERNELS_PATH. Matching files:'
    for i = 0L, match_count - 1L do begin
      diagnostic = diagnostic + string(10B) + '  ' + sorted_matches[i]
    endfor
    message, diagnostic, /NONAME
  endif

  resolved_path = matches[0]

  if ~file_test(resolved_path, /READ) then begin
    message, 'Step 2 kernel resolution failed: resolved meta-kernel is not readable: ' + resolved_path, /NONAME
  endif

  return, resolved_path
end


pro resolve_kernels, meta_kernel_name=meta_kernel_name, resolved_meta_kernel=resolved_meta_kernel
  compile_opt strictarr

  resolved_meta_kernel = resolve_meta_kernel(meta_kernel_name=meta_kernel_name)

  print, 'Step 2 kernel resolution passed.'
  print, 'Resolved meta-kernel=' + resolved_meta_kernel
end
