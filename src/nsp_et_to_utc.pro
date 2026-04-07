function nsp_et_to_utc, et_values
  compile_opt strictarr

  if n_elements(et_values) eq 0 then begin
    message, 'Step 4 time handling failed: et_values was not provided.', /NONAME
  endif

  n = n_elements(et_values)
  utc_strings = strarr(n)

  for i = 0L, n - 1L do begin
    cspice_et2utc, et_values[i], 'ISOC', 3, utc_string
    utc_strings[i] = utc_string
  endfor

  if n eq 1 then return, utc_strings[0]
  return, utc_strings
end
