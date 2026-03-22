pro nsp_geometry, et=et, state_vector=state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 6 geometry conversion failed: ET was not provided.', /NONAME
  endif

  nsp_get_tgo_state, et, state_vector=state_vector, light_time=light_time
  nsp_compute_geometry_from_state, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, position_vector=position_vector

  print, 'Step 6 geometry conversion passed.'
  print, 'Mars mean radius km=' + strtrim(nsp_mars_mean_radius_km(), 2)
  print, 'Longitude radians=' + strtrim(longitude, 2)
  print, 'Latitude radians=' + strtrim(latitude, 2)
  print, 'Radius km=' + strtrim(radius, 2)
  print, 'Altitude km=' + strtrim(altitude, 2)
end
