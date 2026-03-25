pro nsp_compute_geometry_from_position, position_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude
  compile_opt strictarr

  if n_elements(position_vector) ne 3 then begin
    message, 'Step 6 geometry conversion failed: expected a 3-element position vector.', /NONAME
  endif

  position_values = double(position_vector)
  if total(finite(position_values)) ne 3 then begin
    message, 'Step 6 geometry conversion failed: position vector contains non-finite values.', /NONAME
  endif

  x = position_values[0]
  y = position_values[1]
  z = position_values[2]

  radius = sqrt(x * x + y * y + z * z)
  if (~finite(radius)) or (radius le 0D) then begin
    message, 'Step 6 geometry conversion failed: position radius must be finite and positive.', /NONAME
  endif

  longitude = atan(y, x)
  latitude = asin(z / radius)

  status = execute("cspice_reclat, position_values, spice_radius, spice_longitude, spice_latitude")
  if status eq 0 then begin
    message, 'Step 6 geometry conversion failed: cspice_reclat did not complete successfully.', /NONAME
  endif

  if (~finite(spice_radius)) or (~finite(spice_longitude)) or (~finite(spice_latitude)) then begin
    message, 'Step 6 geometry conversion failed: cspice_reclat returned non-finite geometry values.', /NONAME
  endif

  angular_tolerance = 1D-10
  radius_absolute_tolerance = 1D-6
  radius_relative_tolerance = 1D-14
  radius_difference = abs(radius - spice_radius)
  allowed_radius_difference = radius_absolute_tolerance > (radius_relative_tolerance * abs(spice_radius))
  longitude_difference = abs(longitude - spice_longitude)
  if longitude_difference gt !dpi then longitude_difference = abs(longitude_difference - (2D * !dpi))
  latitude_difference = abs(latitude - spice_latitude)

  if radius_difference gt allowed_radius_difference then begin
    message, 'Step 6 geometry conversion failed: manual radius does not agree with cspice_reclat.', /NONAME
  endif

  if longitude_difference gt angular_tolerance then begin
    message, 'Step 6 geometry conversion failed: manual longitude does not agree with cspice_reclat.', /NONAME
  endif

  if latitude_difference gt angular_tolerance then begin
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
