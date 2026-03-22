pro nsp_test_solar_geometry_success
  compile_opt strictarr

  et_value = nsp_utc_to_et('2025-01-01T00:00:00')
  nsp_get_tgo_state, et_value, state_vector=state_vector, light_time=spacecraft_light_time
  nsp_get_sun_state, et_value, sun_state_vector=sun_state_vector, light_time=sun_light_time
  nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle

  direct_abcorr = nsp_solar_geometry_abcorr()
  meta_kernel_path = nsp_loaded_meta_kernel_path()
  meta_kernel_directory = file_dirname(meta_kernel_path)
  cd, current=original_directory

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    cd, original_directory
    message, 'Step 7 tests failed: ' + !error_state.msg, /NONAME
  endif

  cd, meta_kernel_directory
  status = execute("cspice_spkezr, 'SUN', et_value, 'IAU_MARS', direct_abcorr, 'MARS', direct_sun_state_vector, direct_sun_light_time")
  cd, original_directory

  catch, /cancel

  nsp_assert_true, status eq 1, 'direct cspice_spkezr Sun comparison call did not execute successfully.'
  nsp_assert_true, n_elements(sun_state_vector) eq 6, 'NSP_GET_SUN_STATE did not return a 6-element Sun state vector.'
  nsp_assert_true, total(finite(sun_state_vector)) eq 6, 'NSP_GET_SUN_STATE returned non-finite Sun state-vector elements.'
  nsp_assert_true, finite(sun_light_time), 'NSP_GET_SUN_STATE returned a non-finite light time.'

  for i = 0L, 5L do begin
    nsp_assert_close, sun_state_vector[i], direct_sun_state_vector[i], 1D-6, 'NSP_GET_SUN_STATE does not match cspice_spkezr element ' + strtrim(i, 2)
  endfor
  nsp_assert_close, sun_light_time, direct_sun_light_time, 1D-9, 'NSP_GET_SUN_STATE light time does not match cspice_spkezr.'

  direct_spacecraft_to_sun = direct_sun_state_vector[0:2] - state_vector[0:2]
  direct_solar_zenith_angle = acos((total(state_vector[0:2] * direct_spacecraft_to_sun)) / (sqrt(total(state_vector[0:2] * state_vector[0:2])) * sqrt(total(direct_spacecraft_to_sun * direct_spacecraft_to_sun))))

  nsp_assert_true, n_elements(spacecraft_to_sun_vector) eq 3, 'NSP_COMPUTE_SOLAR_GEOMETRY did not return a 3-element spacecraft-to-Sun vector.'
  nsp_assert_true, total(finite(spacecraft_to_sun_vector)) eq 3, 'NSP_COMPUTE_SOLAR_GEOMETRY returned non-finite spacecraft-to-Sun vector elements.'
  nsp_assert_true, finite(solar_zenith_angle), 'NSP_COMPUTE_SOLAR_GEOMETRY returned a non-finite solar zenith angle.'
  nsp_assert_true, (solar_zenith_angle ge 0D) and (solar_zenith_angle le !dpi), 'Solar zenith angle is outside the valid range [0, pi].'

  for i = 0L, 2L do begin
    nsp_assert_close, spacecraft_to_sun_vector[i], direct_spacecraft_to_sun[i], 1D-3, 'NSP_COMPUTE_SOLAR_GEOMETRY does not match the direct spacecraft-to-Sun vector element ' + strtrim(i, 2)
  endfor
  nsp_assert_close, solar_zenith_angle, direct_solar_zenith_angle, 1D-10, 'NSP_COMPUTE_SOLAR_GEOMETRY solar zenith angle does not match the direct dot-product definition.'

  nsp_solar_geometry, et=et_value, state_vector=wrapped_state_vector, sun_state_vector=wrapped_sun_state_vector, spacecraft_to_sun_vector=wrapped_spacecraft_to_sun_vector, solar_zenith_angle=wrapped_solar_zenith_angle
  nsp_assert_true, n_elements(wrapped_state_vector) eq 6, 'NSP_SOLAR_GEOMETRY did not return the Step 5 spacecraft state vector.'
  nsp_assert_true, n_elements(wrapped_sun_state_vector) eq 6, 'NSP_SOLAR_GEOMETRY did not return the Sun state vector.'
  nsp_assert_close, wrapped_solar_zenith_angle, solar_zenith_angle, 1D-10, 'NSP_SOLAR_GEOMETRY solar zenith angle does not match the direct helper result.'
end


pro nsp_test_solar_geometry_invalid_state_failure
  compile_opt strictarr

  catch, error_status
  if error_status ne 0 then begin
    error_message = !error_state.msg
    catch, /cancel
    nsp_assert_true, strpos(strlowcase(error_message), '6-element spacecraft state vector') ge 0, 'Invalid spacecraft-state failure message did not mention the required element count.'
    return
  endif

  invalid_state = dblarr(5)
  valid_sun_state = dblarr(6)
  nsp_compute_solar_geometry, invalid_state, valid_sun_state, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  catch, /cancel
  message, 'Step 7 tests failed: NSP_COMPUTE_SOLAR_GEOMETRY accepted an invalid spacecraft state vector without failing.', /NONAME
end


pro nsp_test_solar_geometry
  compile_opt strictarr

  nsp_test_solar_geometry_success
  nsp_test_solar_geometry_invalid_state_failure

  print, 'Step 7 tests passed.'
  print, 'Validated Sun state retrieval, spacecraft-to-Sun vectors, and spacecraft-local solar zenith angle.'
end
