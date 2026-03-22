function nsp_utc_to_et, utc_string
  compile_opt strictarr

  if n_elements(utc_string) eq 0 then begin
    message, 'Step 4 time handling failed: utc_string was not provided.', /NONAME
  endif

  trimmed_utc = strtrim(utc_string, 2)
  if trimmed_utc eq '' then begin
    message, 'Step 4 time handling failed: utc_string is empty.', /NONAME
  endif

  status = execute("cspice_str2et, trimmed_utc, et_value")
  if status eq 0 then begin
    message, 'Step 4 time handling failed: unable to convert UTC to ET with cspice_str2et for ' + trimmed_utc, /NONAME
  endif

  if ~finite(et_value) then begin
    message, 'Step 4 time handling failed: cspice_str2et returned a non-finite ET value for ' + trimmed_utc, /NONAME
  endif

  return, double(et_value)
end
