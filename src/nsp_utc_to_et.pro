;+
; NAME:
;   NSP_UTC_TO_ET
;
; PURPOSE:
;   Converts one or more UTC time strings to SPICE ephemeris time (ET,
;   seconds past J2000). Wraps cspice_str2et via EXECUTE so that the
;   call resolves correctly regardless of when the ICY DLM was loaded.
;
; CATEGORY:
;   NAIF Satellite Position / Time Handling
;
; CALLING SEQUENCE:
;   et = NSP_UTC_TO_ET(utc_strings)
;
; INPUTS:
;   utc_strings - Scalar or array of UTC strings in any format
;                 accepted by cspice_str2et, e.g. '2025-01-01T00:00:00'.
;
; OUTPUTS:
;   Result - DOUBLE scalar if a single string was supplied, or DOUBLE
;            array of the same length as utc_strings. Each element is
;            the corresponding ephemeris time in seconds past J2000.
;
; NOTES:
;   A loaded leapseconds kernel is required; furnish kernels via
;   NSP_RUN_PIPELINE before calling this function. An error is raised
;   for any empty string or non-finite result.
;
; EXAMPLE:
;   et = NSP_UTC_TO_ET('2025-01-01T00:00:00')
;   et_array = NSP_UTC_TO_ET(['2025-01-01T00:00:00', '2025-06-01T12:00:00'])
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation; vector support added
;-
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
