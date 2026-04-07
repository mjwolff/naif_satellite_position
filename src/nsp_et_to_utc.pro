function nsp_et_to_utc, et_values, noload=noload
  compile_opt strictarr

  if n_elements(et_values) eq 0 then begin
    message, 'Step 4 time handling failed: et_values was not provided.', /NONAME
  endif

  ; Check whether the leapseconds kernel is loaded by probing DELTET/DELTA_T_A
  ; in the kernel pool, which cspice_et2utc requires.
  found = 0B
  status = execute("cspice_gdpool, 'DELTET/DELTA_T_A', 0, 1, pool_values, found")
  if ~found then begin
    if keyword_set(noload) then begin
      message, 'Step 4 time handling failed: leapseconds kernel not loaded. Call NSP_RUN_PIPELINE before NSP_ET_TO_UTC.', /NONAME
    endif
    nsp_run_pipeline
  endif

  n = n_elements(et_values)
  utc_strings = strarr(n)

  for i = 0L, n - 1L do begin
    et_scalar = et_values[i]
    status = execute("cspice_et2utc, et_scalar, 'ISOC', 3, utc_string")
    if status eq 0 then begin
      message, 'Step 4 time handling failed: cspice_et2utc could not convert ET value ' + strtrim(et_scalar, 2), /NONAME
    endif
    utc_strings[i] = utc_string
  endfor

  if n eq 1 then return, utc_strings[0]
  return, utc_strings
end
