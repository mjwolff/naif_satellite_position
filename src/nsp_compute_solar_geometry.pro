pro nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  compile_opt strictarr

  if n_elements(state_vector) ne 6 then begin
    message, 'Step 7 solar geometry failed: expected a 6-element spacecraft state vector.', /NONAME
  endif

  if n_elements(sun_state_vector) ne 6 then begin
    message, 'Step 7 solar geometry failed: expected a 6-element Sun state vector.', /NONAME
  endif

  spacecraft_state_values = double(state_vector)
  sun_state_values = double(sun_state_vector)

  if total(finite(spacecraft_state_values)) ne 6 then begin
    message, 'Step 7 solar geometry failed: spacecraft state vector contains non-finite values.', /NONAME
  endif

  if total(finite(sun_state_values)) ne 6 then begin
    message, 'Step 7 solar geometry failed: Sun state vector contains non-finite values.', /NONAME
  endif

  spacecraft_position = spacecraft_state_values[0:2]
  sun_position = sun_state_values[0:2]
  spacecraft_to_sun_vector = sun_position - spacecraft_position

  if total(finite(spacecraft_to_sun_vector)) ne 3 then begin
    message, 'Step 7 solar geometry failed: spacecraft-to-Sun vector contains non-finite values.', /NONAME
  endif

  spacecraft_radius = sqrt(total(spacecraft_position * spacecraft_position))
  sun_range = sqrt(total(spacecraft_to_sun_vector * spacecraft_to_sun_vector))

  if (~finite(spacecraft_radius)) or (spacecraft_radius le 0D) then begin
    message, 'Step 7 solar geometry failed: spacecraft radius must be finite and positive.', /NONAME
  endif

  if (~finite(sun_range)) or (sun_range le 0D) then begin
    message, 'Step 7 solar geometry failed: spacecraft-to-Sun range must be finite and positive.', /NONAME
  endif

  cosine_sza = total(spacecraft_position * spacecraft_to_sun_vector) / (spacecraft_radius * sun_range)
  if ~finite(cosine_sza) then begin
    message, 'Step 7 solar geometry failed: computed cosine of solar zenith angle is non-finite.', /NONAME
  endif

  if cosine_sza gt 1D then cosine_sza = 1D
  if cosine_sza lt (-1D) then cosine_sza = -1D

  solar_zenith_angle = acos(cosine_sza)
  if ~finite(solar_zenith_angle) then begin
    message, 'Step 7 solar geometry failed: solar zenith angle is non-finite.', /NONAME
  endif

  if (solar_zenith_angle lt 0D) or (solar_zenith_angle gt !dpi) then begin
    message, 'Step 7 solar geometry failed: solar zenith angle is outside the valid range [0, pi].', /NONAME
  endif
end
