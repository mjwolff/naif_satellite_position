pro nsp_occultation, et=et, state_vector=state_vector, sun_state_vector=sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 8 occultation geometry failed: ET was not provided.', /NONAME
  endif

  nsp_get_tgo_state, et, state_vector=state_vector, light_time=spacecraft_light_time
  nsp_get_sun_state, et, sun_state_vector=sun_state_vector, light_time=sun_light_time
  nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  nsp_compute_occultation_geometry, state_vector, spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance

  print, 'Step 8 occultation geometry passed.'
  print, 'Occultation valid=' + strtrim(fix(occultation_valid), 2)
  print, 'Closest approach distance km=' + strtrim(closest_approach_distance, 2)

  if occultation_valid then begin
    print, 'Tangent longitude radians=' + strtrim(tangent_longitude, 2)
    print, 'Tangent latitude radians=' + strtrim(tangent_latitude, 2)
    print, 'Tangent radius km=' + strtrim(tangent_radius, 2)
    print, 'Tangent altitude km=' + strtrim(tangent_altitude, 2)
  endif else begin
    print, 'Non-occultation case flagged explicitly; tangent-point geometry is not reported as valid.'
  endelse
end
