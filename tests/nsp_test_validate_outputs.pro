pro nsp_step11_valid_case_values, state_vector=state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude
  compile_opt strictarr

  et_value = nsp_utc_to_et('2025-01-01T00:00:00')
  nsp_get_tgo_state, et_value, state_vector=state_vector, light_time=spacecraft_light_time
  nsp_compute_geometry_from_state, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, position_vector=position_vector
  nsp_get_sun_state, et_value, sun_state_vector=sun_state_vector, light_time=sun_light_time
  nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  nsp_compute_occultation_geometry, state_vector, spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance
end


pro nsp_test_validate_outputs_success
  compile_opt strictarr

  nsp_step11_valid_case_values, state_vector=state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude

  nsp_validate_outputs, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude
end


pro nsp_test_validate_outputs_nonfinite_failure
  compile_opt strictarr

  nsp_step11_valid_case_values, state_vector=state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude
  state_vector[0] = !values.d_infinity

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    return
  endif

  nsp_validate_outputs, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude
  catch, /cancel
  message, 'Step 11 tests failed: NSP_VALIDATE_OUTPUTS accepted a non-finite spacecraft state vector without failing.', /NONAME
end


pro nsp_test_validate_outputs_solar_angle_failure
  compile_opt strictarr

  nsp_step11_valid_case_values, state_vector=state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude
  solar_zenith_angle = !dpi + 0.01D

  catch, error_status
  if error_status ne 0 then begin
    error_message = !error_state.msg
    catch, /cancel
    nsp_assert_true, strpos(strlowcase(error_message), 'solar zenith angle is outside the valid range') ge 0, 'Step 11 solar-angle failure message did not mention the valid range.'
    return
  endif

  nsp_validate_outputs, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude
  catch, /cancel
  message, 'Step 11 tests failed: NSP_VALIDATE_OUTPUTS accepted a solar zenith angle outside [0, pi] without failing.', /NONAME
end


pro nsp_test_validate_outputs_nonoccultation_tangent_failure
  compile_opt strictarr

  nsp_step11_valid_case_values, state_vector=state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude
  occultation_valid = 0L

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    return
  endif

  nsp_validate_outputs, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude
  catch, /cancel
  message, 'Step 11 tests failed: NSP_VALIDATE_OUTPUTS accepted finite tangent geometry for a non-occultation case without failing.', /NONAME
end


pro nsp_test_validate_outputs
  compile_opt strictarr

  nsp_test_validate_outputs_success
  nsp_test_validate_outputs_nonfinite_failure
  nsp_test_validate_outputs_solar_angle_failure
  nsp_test_validate_outputs_nonoccultation_tangent_failure

  print, 'Step 11 tests passed.'
  print, 'Validated integrated output finiteness checks, angle ranges, and tangent-geometry failure handling.'
end
