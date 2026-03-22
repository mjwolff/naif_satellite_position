pro nsp_test_geometry_success
  compile_opt strictarr

  et_value = nsp_utc_to_et('2025-01-01T00:00:00')
  nsp_get_tgo_state, et_value, state_vector=state_vector, light_time=light_time
  nsp_compute_geometry_from_state, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, position_vector=position_vector

  status = execute("cspice_reclat, position_vector, spice_radius, spice_longitude, spice_latitude")
  nsp_assert_true, status eq 1, 'direct cspice_reclat comparison call did not execute successfully.'
  nsp_assert_close, radius, spice_radius, 1D-10, 'NSP_COMPUTE_GEOMETRY_FROM_STATE radius does not match cspice_reclat.'
  nsp_assert_close, longitude, spice_longitude, 1D-10, 'NSP_COMPUTE_GEOMETRY_FROM_STATE longitude does not match cspice_reclat.'
  nsp_assert_close, latitude, spice_latitude, 1D-10, 'NSP_COMPUTE_GEOMETRY_FROM_STATE latitude does not match cspice_reclat.'
  nsp_assert_close, altitude, radius - nsp_mars_mean_radius_km(), 1D-10, 'Altitude does not equal radius minus the Mars mean radius.'

  nsp_assert_true, (latitude ge (-0.5D * !dpi)) and (latitude le (0.5D * !dpi)), 'Latitude is outside the valid planetocentric range.'
  nsp_assert_true, (longitude ge (-1D * !dpi)) and (longitude le !dpi), 'Longitude is outside the valid planetocentric range.'
  nsp_assert_true, radius gt 0D, 'Radius is not positive.'
  nsp_assert_true, finite(altitude), 'Altitude is not finite.'

  nsp_geometry, et=et_value, state_vector=wrapped_state_vector, longitude=wrapped_longitude, latitude=wrapped_latitude, radius=wrapped_radius, altitude=wrapped_altitude
  nsp_assert_true, n_elements(wrapped_state_vector) eq 6, 'NSP_GEOMETRY did not return the Step 5 state vector.'
  nsp_assert_close, wrapped_radius, radius, 1D-10, 'NSP_GEOMETRY radius does not match the direct helper result.'
  nsp_assert_close, wrapped_longitude, longitude, 1D-10, 'NSP_GEOMETRY longitude does not match the direct helper result.'
  nsp_assert_close, wrapped_latitude, latitude, 1D-10, 'NSP_GEOMETRY latitude does not match the direct helper result.'
  nsp_assert_close, wrapped_altitude, altitude, 1D-10, 'NSP_GEOMETRY altitude does not match the direct helper result.'
end


pro nsp_test_geometry_invalid_state_failure
  compile_opt strictarr

  catch, error_status
  if error_status ne 0 then begin
    error_message = !error_state.msg
    catch, /cancel
    nsp_assert_true, strpos(strlowcase(error_message), '6-element state vector') ge 0, 'Invalid state-vector failure message did not mention the required element count.'
    return
  endif

  invalid_state = dblarr(5)
  nsp_compute_geometry_from_state, invalid_state, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude
  catch, /cancel
  message, 'Step 6 tests failed: NSP_COMPUTE_GEOMETRY_FROM_STATE accepted an invalid-length state vector without failing.', /NONAME
end


pro nsp_test_geometry
  compile_opt strictarr

  nsp_test_geometry_success
  nsp_test_geometry_invalid_state_failure

  print, 'Step 6 tests passed.'
  print, 'Validated spacecraft latitude, longitude, radius, altitude, and cspice_reclat agreement.'
end
