function nsp_utc_to_et, utc_strings
  compile_opt strictarr

  if n_elements(utc_strings) eq 0 then begin
    message, 'Step 4 time handling failed: utc_string was not provided.', /NONAME
  endif

  n = n_elements(utc_strings)
  et_values = dblarr(n)

  for i = 0L, n - 1L do begin
    trimmed_utc = strtrim(utc_strings[i], 2)
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

    et_values[i] = et_value
  endfor

  if n eq 1 then return, et_values[0]
  return, et_values
end
