function nsp_default_icy_dlm_path
  compile_opt strictarr

  return, '/Users/mwolff/lib/Darwin_arm64'
end


function nsp_resolve_icy_dlm_path, icy_dlm_path=icy_dlm_path
  compile_opt strictarr

  resolved_path = ''

  if n_elements(icy_dlm_path) gt 0 then begin
    if strtrim(icy_dlm_path, 2) ne '' then resolved_path = strtrim(icy_dlm_path, 2)
  endif

  if resolved_path eq '' then begin
    resolved_path = strtrim(getenv('ICY_DLM_PATH'), 2)
  endif

  if resolved_path eq '' then begin
    resolved_path = nsp_default_icy_dlm_path()
  endif

  return, resolved_path
end
