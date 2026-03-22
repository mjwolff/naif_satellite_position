pro nsp_compute_geometry_from_state, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, position_vector=position_vector
  compile_opt strictarr

  if n_elements(state_vector) ne 6 then begin
    message, 'Step 6 geometry conversion failed: expected a 6-element state vector.', /NONAME
  endif

  state_values = double(state_vector)
  if total(finite(state_values)) ne 6 then begin
    message, 'Step 6 geometry conversion failed: state vector contains non-finite values.', /NONAME
  endif

  position_vector = state_values[0:2]
  if total(finite(position_vector)) ne 3 then begin
    message, 'Step 6 geometry conversion failed: position vector contains non-finite values.', /NONAME
  endif

  x = position_vector[0]
  y = position_vector[1]
  z = position_vector[2]

  radius = sqrt(x * x + y * y + z * z)
  if (~finite(radius)) or (radius le 0D) then begin
    message, 'Step 6 geometry conversion failed: spacecraft radius must be finite and positive.', /NONAME
  endif

  longitude = atan(y, x)
  latitude = asin(z / radius)

  status = execute("cspice_reclat, position_vector, spice_radius, spice_longitude, spice_latitude")
  if status eq 0 then begin
    message, 'Step 6 geometry conversion failed: cspice_reclat did not complete successfully.', /NONAME
  endif

  if (~finite(spice_radius)) or (~finite(spice_longitude)) or (~finite(spice_latitude)) then begin
    message, 'Step 6 geometry conversion failed: cspice_reclat returned non-finite geometry values.', /NONAME
  endif

  tolerance = 1D-10
  radius_difference = abs(radius - spice_radius)
  longitude_difference = abs(longitude - spice_longitude)
  if longitude_difference gt !dpi then longitude_difference = abs(longitude_difference - (2D * !dpi))
  latitude_difference = abs(latitude - spice_latitude)

  if radius_difference gt tolerance then begin
    message, 'Step 6 geometry conversion failed: manual radius does not agree with cspice_reclat.', /NONAME
  endif

  if longitude_difference gt tolerance then begin
    message, 'Step 6 geometry conversion failed: manual longitude does not agree with cspice_reclat.', /NONAME
  endif

  if latitude_difference gt tolerance then begin
    message, 'Step 6 geometry conversion failed: manual latitude does not agree with cspice_reclat.', /NONAME
  endif

  if (latitude lt (-0.5D * !dpi)) or (latitude gt (0.5D * !dpi)) then begin
    message, 'Step 6 geometry conversion failed: latitude is outside the valid planetocentric range.', /NONAME
  endif

  if (longitude lt (-1D * !dpi)) or (longitude gt !dpi) then begin
    message, 'Step 6 geometry conversion failed: longitude is outside the valid planetocentric range.', /NONAME
  endif

  altitude = radius - nsp_mars_mean_radius_km()
  if ~finite(altitude) then begin
    message, 'Step 6 geometry conversion failed: altitude is non-finite.', /NONAME
  endif
end
