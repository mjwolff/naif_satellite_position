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
