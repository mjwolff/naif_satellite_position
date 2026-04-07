pro nsp_test_utc_to_et_success
  compile_opt strictarr

  utc_string = '2025-01-01T00:00:00'
  converted_et = nsp_utc_to_et(utc_string)
  status = execute("cspice_str2et, utc_string, direct_et")

  nsp_assert_true, status eq 1, 'direct cspice_str2et comparison call did not execute successfully.'
  nsp_assert_true, finite(converted_et), 'NSP_UTC_TO_ET returned a non-finite ET value.'
  nsp_assert_close, converted_et, direct_et, 1D-6, 'NSP_UTC_TO_ET does not match cspice_str2et for ' + utc_string
end


pro nsp_test_time_grid_success
  compile_opt strictarr

  utc_string = '2025-01-01T00:00:00'
  expected_start_et = nsp_utc_to_et(utc_string)
  grid = nsp_build_time_grid(utc_string, 60D, 3L)

  nsp_assert_true, n_elements(grid) eq 3, 'NSP_BUILD_TIME_GRID did not return three ET values.'
  nsp_assert_close, grid[0], expected_start_et, 1D-6, 'NSP_BUILD_TIME_GRID first element does not match NSP_UTC_TO_ET.'
  nsp_assert_close, grid[1] - grid[0], 60D, 1D-9, 'NSP_BUILD_TIME_GRID first spacing is not 60 seconds.'
  nsp_assert_close, grid[2] - grid[1], 60D, 1D-9, 'NSP_BUILD_TIME_GRID second spacing is not 60 seconds.'
end


pro nsp_test_utc_to_et_empty_failure
  compile_opt strictarr

  catch, error_status
  if error_status ne 0 then begin
    error_message = !error_state.msg
    catch, /cancel
    nsp_assert_true, strpos(strlowcase(error_message), 'utc_string is empty') ge 0, 'Empty UTC failure message did not mention an empty UTC string.'
    return
  endif

  ignored_value = nsp_utc_to_et('')
  catch, /cancel
  message, 'Step 4 tests failed: NSP_UTC_TO_ET accepted an empty UTC string without failing.', /NONAME
end


pro nsp_test_time_grid_invalid_point_count_failure
  compile_opt strictarr

  catch, error_status
  if error_status ne 0 then begin
    error_message = !error_state.msg
    catch, /cancel
    nsp_assert_true, strpos(strlowcase(error_message), 'point_count must be greater than zero') ge 0, 'Invalid point-count failure message did not mention point_count.'
    return
  endif

  ignored_grid = nsp_build_time_grid('2025-01-01T00:00:00', 60D, 0L)
  catch, /cancel
  message, 'Step 4 tests failed: NSP_BUILD_TIME_GRID accepted POINT_COUNT=0 without failing.', /NONAME
end


pro nsp_test_utc_to_et_vector_success
  compile_opt strictarr

  utc_inputs = ['2025-01-01T00:00:00', '2025-06-15T12:30:00', '2025-12-31T23:59:59']
  n = n_elements(utc_inputs)
  et_values = nsp_utc_to_et(utc_inputs)

  nsp_assert_true, n_elements(et_values) eq n, 'NSP_UTC_TO_ET vector did not return the correct number of elements.'
  for i = 0L, n - 1L do begin
    status = execute("cspice_str2et, utc_inputs[i], direct_et")
    nsp_assert_true, status eq 1, 'direct cspice_str2et comparison call did not execute successfully for element ' + strtrim(i, 2)
    nsp_assert_close, et_values[i], direct_et, 1D-6, 'NSP_UTC_TO_ET vector element ' + strtrim(i, 2) + ' does not match cspice_str2et.'
  endfor
end


pro nsp_test_et_to_utc_scalar_roundtrip
  compile_opt strictarr

  utc_input = '2025-01-01T00:00:00'
  et_value = nsp_utc_to_et(utc_input)
  utc_output = nsp_et_to_utc(et_value)
  et_roundtrip = nsp_utc_to_et(utc_output)

  nsp_assert_true, size(utc_output, /TNAME) eq 'STRING', 'NSP_ET_TO_UTC did not return a string.'
  nsp_assert_close, et_roundtrip, et_value, 5D-4, 'NSP_ET_TO_UTC scalar round-trip ET does not match original within 0.5 ms.'
end


pro nsp_test_et_to_utc_vector_roundtrip
  compile_opt strictarr

  utc_inputs = ['2025-01-01T00:00:00', '2025-06-15T12:30:00', '2025-12-31T23:59:59']
  n = n_elements(utc_inputs)
  et_values = dblarr(n)
  for i = 0L, n - 1L do et_values[i] = nsp_utc_to_et(utc_inputs[i])

  utc_outputs = nsp_et_to_utc(et_values)

  nsp_assert_true, n_elements(utc_outputs) eq n, 'NSP_ET_TO_UTC vector did not return the correct number of elements.'
  for i = 0L, n - 1L do begin
    et_roundtrip = nsp_utc_to_et(utc_outputs[i])
    nsp_assert_close, et_roundtrip, et_values[i], 5D-4, 'NSP_ET_TO_UTC vector round-trip failed for element ' + strtrim(i, 2)
  endfor
end


pro nsp_test_time_handling
  compile_opt strictarr

  nsp_test_utc_to_et_success
  nsp_test_utc_to_et_vector_success
  nsp_test_time_grid_success
  nsp_test_utc_to_et_empty_failure
  nsp_test_time_grid_invalid_point_count_failure
  nsp_test_et_to_utc_scalar_roundtrip
  nsp_test_et_to_utc_vector_roundtrip

  print, 'Step 4 tests passed.'
  print, 'Validated UTC/ET scalar and vector conversions, ET grid generation, and expected failure cases.'
end
