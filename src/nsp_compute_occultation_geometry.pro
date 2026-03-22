pro nsp_compute_occultation_geometry, state_vector, spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance
  compile_opt strictarr

  if n_elements(state_vector) ne 6 then begin
    message, 'Step 8 occultation geometry failed: expected a 6-element spacecraft state vector.', /NONAME
  endif

  if n_elements(spacecraft_to_sun_vector) ne 3 then begin
    message, 'Step 8 occultation geometry failed: expected a 3-element spacecraft-to-Sun vector.', /NONAME
  endif

  state_values = double(state_vector)
  direction_values = double(spacecraft_to_sun_vector)

  if total(finite(state_values)) ne 6 then begin
    message, 'Step 8 occultation geometry failed: spacecraft state vector contains non-finite values.', /NONAME
  endif

  if total(finite(direction_values)) ne 3 then begin
    message, 'Step 8 occultation geometry failed: spacecraft-to-Sun vector contains non-finite values.', /NONAME
  endif

  spacecraft_position = state_values[0:2]
  sun_range = sqrt(total(direction_values * direction_values))
  if (~finite(sun_range)) or (sun_range le 0D) then begin
    message, 'Step 8 occultation geometry failed: spacecraft-to-Sun range must be finite and positive.', /NONAME
  endif

  line_direction = direction_values / sun_range
  closest_approach_distance = -total(spacecraft_position * line_direction)

  if ~finite(closest_approach_distance) then begin
    message, 'Step 8 occultation geometry failed: closest-approach distance is non-finite.', /NONAME
  endif

  if closest_approach_distance le 0D then begin
    occultation_valid = 0B
    tangent_point_vector = dblarr(3)
    tangent_point_vector[*] = !values.d_nan
    tangent_longitude = !values.d_nan
    tangent_latitude = !values.d_nan
    tangent_radius = !values.d_nan
    tangent_altitude = !values.d_nan
    return
  endif

  tangent_point_vector = spacecraft_position + (closest_approach_distance * line_direction)
  if total(finite(tangent_point_vector)) ne 3 then begin
    message, 'Step 8 occultation geometry failed: tangent-point vector contains non-finite values.', /NONAME
  endif

  orthogonality = abs(total(tangent_point_vector * line_direction))
  if orthogonality gt 1D-8 then begin
    message, 'Step 8 occultation geometry failed: tangent-point vector is not orthogonal to the line-of-sight direction at closest approach.', /NONAME
  endif

  nsp_compute_geometry_from_position, tangent_point_vector, longitude=tangent_longitude, latitude=tangent_latitude, radius=tangent_radius, altitude=tangent_altitude
  occultation_valid = 1B
end
