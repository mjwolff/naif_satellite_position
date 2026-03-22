pro nsp_solar_geometry, et=et, state_vector=state_vector, sun_state_vector=sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 7 solar geometry failed: ET was not provided.', /NONAME
  endif

  nsp_get_tgo_state, et, state_vector=state_vector, light_time=spacecraft_light_time
  nsp_get_sun_state, et, sun_state_vector=sun_state_vector, light_time=sun_light_time
  nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle

  print, 'Step 7 solar geometry passed.'
  print, 'Frame=IAU_MARS'
  print, 'Aberration correction=' + nsp_solar_geometry_abcorr()
  print, 'Observer=MARS'
  print, 'Target=SUN'
  print, 'Solar zenith angle radians=' + strtrim(solar_zenith_angle, 2)
  print, 'Spacecraft-to-Sun range km=' + strtrim(sqrt(total(spacecraft_to_sun_vector * spacecraft_to_sun_vector)), 2)
end
