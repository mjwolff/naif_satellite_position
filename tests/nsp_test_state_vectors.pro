pro nsp_test_state_vector_success
  compile_opt strictarr

  et_value = nsp_utc_to_et('2025-01-01T00:00:00')
  nsp_get_tgo_state, et_value, state_vector=state_vector, light_time=light_time

  meta_kernel_path = nsp_loaded_meta_kernel_path()
  meta_kernel_directory = file_dirname(meta_kernel_path)
  abcorr = nsp_state_vector_abcorr()
  cd, current=original_directory

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    cd, original_directory
    message, 'Step 5 tests failed: ' + !error_state.msg, /NONAME
  endif

  cd, meta_kernel_directory
  status = execute("cspice_spkezr, 'TGO', et_value, 'IAU_MARS', abcorr, 'MARS', direct_state, direct_light_time")
  cd, original_directory

  catch, /cancel

  nsp_assert_true, status eq 1, 'direct cspice_spkezr comparison call did not execute successfully.'
  nsp_assert_true, n_elements(state_vector) eq 6, 'NSP_GET_TGO_STATE did not return a 6-element state vector.'
  nsp_assert_true, total(finite(state_vector)) eq 6, 'NSP_GET_TGO_STATE returned non-finite state-vector elements.'
  nsp_assert_true, finite(light_time), 'NSP_GET_TGO_STATE returned a non-finite light time.'

  for i = 0L, 5L do begin
    nsp_assert_close, state_vector[i], direct_state[i], 1D-9, 'NSP_GET_TGO_STATE does not match cspice_spkezr element ' + strtrim(i, 2)
  endfor
  nsp_assert_close, light_time, direct_light_time, 1D-12, 'NSP_GET_TGO_STATE light time does not match cspice_spkezr.'
end


pro nsp_test_state_vector_invalid_et_failure
  compile_opt strictarr

  catch, error_status
  if error_status ne 0 then begin
    error_message = !error_state.msg
    catch, /cancel
    nsp_assert_true, strpos(strlowcase(error_message), 'et must be finite') ge 0, 'Invalid ET failure message did not mention finite ET.'
    return
  endif

  invalid_et = !values.d_nan
  nsp_get_tgo_state, invalid_et, state_vector=state_vector, light_time=light_time
  catch, /cancel
  message, 'Step 5 tests failed: NSP_GET_TGO_STATE accepted a non-finite ET without failing.', /NONAME
end


pro nsp_test_state_vectors
  compile_opt strictarr

  nsp_test_state_vector_success
  nsp_test_state_vector_invalid_et_failure

  print, 'Step 5 tests passed.'
  print, 'Validated single-epoch TGO state retrieval and expected ET failure handling.'
end
