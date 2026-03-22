function nsp_resolve_relative_meta_kernel, kernels_path, relative_name
  compile_opt strictarr

  candidate_path = file_expand_path(kernels_path + '/' + relative_name)

  if ~file_test(candidate_path, /REGULAR) then begin
    message, 'Step 2 kernel resolution failed: specified meta-kernel was not found beneath KERNELS_PATH: ' + candidate_path, /NONAME
  endif

  if ~file_test(candidate_path, /READ) then begin
    message, 'Step 2 kernel resolution failed: specified meta-kernel is not readable: ' + candidate_path, /NONAME
  endif

  return, candidate_path
end


function nsp_resolve_meta_kernel, meta_kernel_name=meta_kernel_name
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
    return, nsp_resolve_relative_meta_kernel(kernels_path, selected_name)
  endif

  root_candidate = file_expand_path(kernels_path + '/' + selected_name)
  mk_candidate = file_expand_path(kernels_path + '/mk/' + selected_name)

  root_found = file_test(root_candidate, /REGULAR)
  mk_found = file_test(mk_candidate, /REGULAR)

  if ~root_found and ~mk_found then begin
    diagnostic = 'Step 2 kernel resolution failed: no meta-kernel named "' + selected_name + '" was found in the deterministic search locations beneath KERNELS_PATH=' + kernels_path
    diagnostic = diagnostic + string(10B) + '  ' + root_candidate
    diagnostic = diagnostic + string(10B) + '  ' + mk_candidate
    message, diagnostic, /NONAME
  endif

  if root_found and mk_found and (root_candidate ne mk_candidate) then begin
    diagnostic = 'Step 2 kernel resolution failed: meta-kernel name "' + selected_name + '" is ambiguous beneath KERNELS_PATH. Matching files:'
    diagnostic = diagnostic + string(10B) + '  ' + root_candidate
    diagnostic = diagnostic + string(10B) + '  ' + mk_candidate
    message, diagnostic, /NONAME
  endif

  if root_found then resolved_path = root_candidate else resolved_path = mk_candidate

  if ~file_test(resolved_path, /READ) then begin
    message, 'Step 2 kernel resolution failed: resolved meta-kernel is not readable: ' + resolved_path, /NONAME
  endif

  return, resolved_path
end


pro nsp_resolve_kernels, meta_kernel_name=meta_kernel_name, resolved_meta_kernel=resolved_meta_kernel
  compile_opt strictarr

  resolved_meta_kernel = nsp_resolve_meta_kernel(meta_kernel_name=meta_kernel_name)

  print, 'Step 2 kernel resolution passed.'
  print, 'Resolved meta-kernel=' + resolved_meta_kernel
end
