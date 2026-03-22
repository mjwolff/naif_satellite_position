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
  nsp_compute_geometry_from_position, position_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude
end
