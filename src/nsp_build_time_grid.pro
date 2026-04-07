;+
; NAME:
;   NSP_BUILD_TIME_GRID
;
; PURPOSE:
;   Builds a uniformly spaced ephemeris time (ET) grid from a UTC start
;   time, a step size in seconds, and a point count. This is the primary
;   time-grid constructor used by the NSP batch pipeline.
;
; CATEGORY:
;   NAIF Satellite Position / Time Handling
;
; CALLING SEQUENCE:
;   et_grid = NSP_BUILD_TIME_GRID(start_utc, step_seconds, point_count)
;
; INPUTS:
;   start_utc    - STRING. UTC start time in any format accepted by
;                  NSP_UTC_TO_ET, e.g. '2025-01-01T00:00:00'.
;   step_seconds - DOUBLE (or castable). Time step between grid points
;                  in seconds. Must be finite.
;   point_count  - LONG (or castable). Number of grid points. Must be
;                  greater than zero.
;
; OUTPUTS:
;   Result - DOUBLE array of length point_count containing ET values
;            starting at the ET corresponding to start_utc, spaced by
;            step_seconds.
;
; EXAMPLE:
;   grid = NSP_BUILD_TIME_GRID('2025-01-01T00:00:00', 60D, 10L)
;   print, grid[1] - grid[0]   ; prints 60.000000
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_build_time_grid, start_utc, step_seconds, point_count
  compile_opt strictarr

  if n_elements(step_seconds) eq 0 then begin
    message, 'Step 4 time handling failed: step_seconds was not provided.', /NONAME
  endif

  if n_elements(point_count) eq 0 then begin
    message, 'Step 4 time handling failed: point_count was not provided.', /NONAME
  endif

  step_seconds_value = double(step_seconds)
  point_count_value = long(point_count)

  if ~finite(step_seconds_value) then begin
    message, 'Step 4 time handling failed: step_seconds must be finite.', /NONAME
  endif

  if point_count_value le 0 then begin
    message, 'Step 4 time handling failed: point_count must be greater than zero.', /NONAME
  endif

  start_et = nsp_utc_to_et(start_utc)
  return, start_et + dindgen(point_count_value) * step_seconds_value
end
