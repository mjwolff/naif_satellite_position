;+
; NAME:
;   NSP_TIME_GRID
;
; PURPOSE:
;   Reporting wrapper around NSP_BUILD_TIME_GRID. Builds a uniformly
;   spaced ET grid and prints a summary to the IDL console. Intended for
;   interactive use and pipeline step validation.
;
; CATEGORY:
;   NAIF Satellite Position / Time Handling
;
; CALLING SEQUENCE:
;   NSP_TIME_GRID, START_UTC=start_utc, STEP_SECONDS=step_seconds, $
;                  POINT_COUNT=point_count [, ET_VALUES=et_values]
;
; OPTIONAL KEYWORDS:
;   START_UTC    - STRING. UTC start time. Required.
;   STEP_SECONDS - DOUBLE. Time step in seconds. Required.
;   POINT_COUNT  - LONG. Number of grid points. Required.
;   ET_VALUES    - Output. DOUBLE array of ET grid values.
;
; OUTPUTS:
;   ET_VALUES - DOUBLE array of length POINT_COUNT containing the
;               computed ET grid.
;
; EXAMPLE:
;   NSP_TIME_GRID, START_UTC='2025-01-01T00:00:00', $
;                  STEP_SECONDS=60D, POINT_COUNT=3L, ET_VALUES=grid
;   print, grid
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_time_grid, start_utc=start_utc, step_seconds=step_seconds, point_count=point_count, et_values=et_values
  compile_opt strictarr

  if n_elements(start_utc) eq 0 then begin
    message, 'Step 4 time handling failed: start_utc was not provided.', /NONAME
  endif

  et_values = nsp_build_time_grid(start_utc, step_seconds, point_count)

  print, 'Step 4 time handling passed.'
  print, 'Grid start UTC=' + strtrim(start_utc, 2)
  print, 'Grid point count=' + strtrim(n_elements(et_values), 2)
  print, 'Grid step seconds=' + strtrim(double(step_seconds), 2)
end
