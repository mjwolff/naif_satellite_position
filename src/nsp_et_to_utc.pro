;+
; NAME:
;   NSP_ET_TO_UTC
;
; PURPOSE:
;   Converts one or more SPICE ephemeris time (ET) values to UTC strings
;   in ISO 8601 combined format with millisecond precision. Wraps
;   cspice_et2utc via EXECUTE so that the call resolves correctly
;   regardless of when the ICY DLM was loaded.
;
; CATEGORY:
;   NAIF Satellite Position / Time Handling
;
; CALLING SEQUENCE:
;   utc = NSP_ET_TO_UTC(et_values [, /NOLOAD])
;
; INPUTS:
;   et_values - DOUBLE scalar or array of ephemeris times in seconds
;               past J2000.
;
; OPTIONAL KEYWORDS:
;   NOLOAD - When set, raises an error if kernels are not loaded rather
;            than attempting to load them automatically via
;            NSP_RUN_PIPELINE.
;
; OUTPUTS:
;   Result - STRING scalar if a single ET was supplied, or STRING array
;            of the same length as et_values. Each element is a UTC
;            string of the form '2025-01-01T00:00:00.000'.
;
; NOTES:
;   If the leapseconds kernel is not loaded (detected by probing
;   DELTET/DELTA_T_A in the kernel pool), the function automatically
;   calls NSP_RUN_PIPELINE to furnish kernels unless /NOLOAD is set.
;   Output format is ISOC with precision 3 (milliseconds).
;
; EXAMPLE:
;   utc = NSP_ET_TO_UTC(788923267.184D)
;   utc_array = NSP_ET_TO_UTC([788923267.184D, 788926867.184D])
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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
