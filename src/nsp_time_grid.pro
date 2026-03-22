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
