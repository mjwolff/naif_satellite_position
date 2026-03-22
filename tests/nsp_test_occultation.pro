pro nsp_test_occultation_actual_case
  compile_opt strictarr

  et_value = nsp_utc_to_et('2025-01-01T00:00:00')
  nsp_get_tgo_state, et_value, state_vector=state_vector, light_time=spacecraft_light_time
  nsp_get_sun_state, et_value, sun_state_vector=sun_state_vector, light_time=sun_light_time
  nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  nsp_compute_occultation_geometry, state_vector, spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance

  nsp_occultation, et=et_value, state_vector=wrapped_state_vector, sun_state_vector=wrapped_sun_state_vector, spacecraft_to_sun_vector=wrapped_spacecraft_to_sun_vector, tangent_point_vector=wrapped_tangent_point_vector, tangent_longitude=wrapped_tangent_longitude, tangent_latitude=wrapped_tangent_latitude, tangent_radius=wrapped_tangent_radius, tangent_altitude=wrapped_tangent_altitude, occultation_valid=wrapped_occultation_valid, closest_approach_distance=wrapped_closest_approach_distance

  nsp_assert_true, n_elements(wrapped_state_vector) eq 6, 'NSP_OCCULTATION did not return the spacecraft state vector.'
  nsp_assert_true, n_elements(wrapped_sun_state_vector) eq 6, 'NSP_OCCULTATION did not return the Sun state vector.'
  nsp_assert_true, n_elements(wrapped_spacecraft_to_sun_vector) eq 3, 'NSP_OCCULTATION did not return the spacecraft-to-Sun vector.'
  nsp_assert_close, wrapped_closest_approach_distance, closest_approach_distance, 1D-10, 'NSP_OCCULTATION closest approach distance does not match the direct helper result.'
  nsp_assert_true, wrapped_occultation_valid eq occultation_valid, 'NSP_OCCULTATION occultation flag does not match the direct helper result.'

  if occultation_valid then begin
    nsp_assert_true, n_elements(tangent_point_vector) eq 3, 'NSP_COMPUTE_OCCULTATION_GEOMETRY did not return a 3-element tangent-point vector.'
    nsp_assert_true, total(finite(tangent_point_vector)) eq 3, 'NSP_COMPUTE_OCCULTATION_GEOMETRY returned non-finite tangent-point vector elements.'
    nsp_assert_true, finite(tangent_radius), 'NSP_COMPUTE_OCCULTATION_GEOMETRY returned a non-finite tangent radius.'
    nsp_assert_true, finite(tangent_altitude), 'NSP_COMPUTE_OCCULTATION_GEOMETRY returned a non-finite tangent altitude.'
    nsp_assert_true, abs(total(tangent_point_vector * (spacecraft_to_sun_vector / sqrt(total(spacecraft_to_sun_vector * spacecraft_to_sun_vector))))) le 1D-8, 'Tangent-point vector is not orthogonal to the line-of-sight direction.'
    nsp_assert_close, wrapped_tangent_radius, tangent_radius, 1D-10, 'NSP_OCCULTATION tangent radius does not match the direct helper result.'
    nsp_assert_close, wrapped_tangent_altitude, tangent_altitude, 1D-10, 'NSP_OCCULTATION tangent altitude does not match the direct helper result.'
  endif else begin
    nsp_assert_true, ~finite(tangent_radius), 'Non-occultation case should not report a finite tangent radius.'
    nsp_assert_true, ~finite(tangent_altitude), 'Non-occultation case should not report a finite tangent altitude.'
    nsp_assert_true, ~finite(wrapped_tangent_radius), 'Wrapped non-occultation case should not report a finite tangent radius.'
    nsp_assert_true, ~finite(wrapped_tangent_altitude), 'Wrapped non-occultation case should not report a finite tangent altitude.'
  endelse
end


pro nsp_test_occultation_synthetic_success
  compile_opt strictarr

  synthetic_state = dblarr(6)
  synthetic_state[0] = 4000D
  synthetic_state[1] = 1000D
  synthetic_spacecraft_to_sun = dblarr(3)
  synthetic_spacecraft_to_sun[0] = -1D

  nsp_compute_occultation_geometry, synthetic_state, synthetic_spacecraft_to_sun, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance

  nsp_assert_true, occultation_valid eq 1B, 'Synthetic occultation case should be flagged as valid.'
  nsp_assert_close, closest_approach_distance, 4000D, 1D-10, 'Synthetic closest approach distance is incorrect.'
  nsp_assert_close, tangent_point_vector[0], 0D, 1D-10, 'Synthetic tangent-point X coordinate is incorrect.'
  nsp_assert_close, tangent_point_vector[1], 1000D, 1D-10, 'Synthetic tangent-point Y coordinate is incorrect.'
  nsp_assert_close, tangent_point_vector[2], 0D, 1D-10, 'Synthetic tangent-point Z coordinate is incorrect.'
  nsp_assert_close, tangent_longitude, !dpi / 2D, 1D-10, 'Synthetic tangent longitude is incorrect.'
  nsp_assert_close, tangent_latitude, 0D, 1D-10, 'Synthetic tangent latitude is incorrect.'
  nsp_assert_close, tangent_radius, 1000D, 1D-10, 'Synthetic tangent radius is incorrect.'
  nsp_assert_close, tangent_altitude, 1000D - nsp_mars_mean_radius_km(), 1D-10, 'Synthetic tangent altitude is incorrect.'
end


pro nsp_test_occultation_synthetic_non_occultation
  compile_opt strictarr

  synthetic_state = dblarr(6)
  synthetic_state[0] = 4000D
  synthetic_state[1] = 1000D
  synthetic_spacecraft_to_sun = dblarr(3)
  synthetic_spacecraft_to_sun[0] = 1D

  nsp_compute_occultation_geometry, synthetic_state, synthetic_spacecraft_to_sun, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance

  nsp_assert_true, occultation_valid eq 0B, 'Synthetic non-occultation case should be flagged as invalid.'
  nsp_assert_true, closest_approach_distance lt 0D, 'Synthetic non-occultation case should have a non-positive closest-approach distance.'
  nsp_assert_true, ~finite(tangent_longitude), 'Synthetic non-occultation case should not report a finite tangent longitude.'
  nsp_assert_true, ~finite(tangent_latitude), 'Synthetic non-occultation case should not report a finite tangent latitude.'
  nsp_assert_true, ~finite(tangent_radius), 'Synthetic non-occultation case should not report a finite tangent radius.'
  nsp_assert_true, ~finite(tangent_altitude), 'Synthetic non-occultation case should not report a finite tangent altitude.'
end


pro nsp_test_occultation_invalid_state_failure
  compile_opt strictarr

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    return
  endif

  invalid_state = dblarr(5)
  valid_spacecraft_to_sun = dblarr(3)
  valid_spacecraft_to_sun[0] = -1D
  nsp_compute_occultation_geometry, invalid_state, valid_spacecraft_to_sun, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance
  catch, /cancel
  message, 'Step 8 tests failed: NSP_COMPUTE_OCCULTATION_GEOMETRY accepted an invalid spacecraft state vector without failing.', /NONAME
end


pro nsp_test_occultation
  compile_opt strictarr

  nsp_test_occultation_actual_case
  nsp_test_occultation_synthetic_success
  nsp_test_occultation_synthetic_non_occultation
  nsp_test_occultation_invalid_state_failure

  print, 'Step 8 tests passed.'
  print, 'Validated tangent-point geometry, non-occultation flagging, and closest-approach construction on the spacecraft-to-Sun line.'
end
