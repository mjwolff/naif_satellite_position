pro nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
  compile_opt strictarr

  print, 'Test Results'
  print, string('Test Name', 'Total', 'Pass', 'Fail', format='(A24,2X,A5,2X,A4,2X,A4)')
  print, '------------------------  -----  ----  ----'

  for i = 0L, n_elements(test_names) - 1L do begin
    print, string(test_names[i], test_counts[i], pass_counts[i], fail_counts[i], format='(A24,2X,I5,2X,I4,2X,I4)')
  endfor
end


pro nsp_run_tests, icy_dlm_path=icy_dlm_path
  compile_opt strictarr

  nsp_setup_path, /include_tests

  test_names = ['Step 4 Time Handling', 'Step 5 State Vectors', 'Step 6 Geometry', 'Step 7 Solar Geometry', 'Step 8 Occultation', 'Step 9 Export', 'Step 10 Batch', 'Step 11 Validation']
  test_counts = [4L, 2L, 2L, 2L, 4L, 3L, 3L, 4L]
  pass_counts = lonarr(n_elements(test_names))
  fail_counts = lonarr(n_elements(test_names))

  nsp_run_pipeline, icy_dlm_path=icy_dlm_path

  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    fail_counts[0] = test_counts[0]
    nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
    message, error_message, /NONAME
  endif
  nsp_test_time_handling
  catch, /cancel
  pass_counts[0] = test_counts[0]

  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    fail_counts[1] = test_counts[1]
    nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
    message, error_message, /NONAME
  endif
  nsp_test_state_vectors
  catch, /cancel
  pass_counts[1] = test_counts[1]

  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    fail_counts[2] = test_counts[2]
    nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
    message, error_message, /NONAME
  endif
  nsp_test_geometry
  catch, /cancel
  pass_counts[2] = test_counts[2]

  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    fail_counts[3] = test_counts[3]
    nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
    message, error_message, /NONAME
  endif
  nsp_test_solar_geometry
  catch, /cancel
  pass_counts[3] = test_counts[3]

  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    fail_counts[4] = test_counts[4]
    nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
    message, error_message, /NONAME
  endif
  nsp_test_occultation
  catch, /cancel
  pass_counts[4] = test_counts[4]

  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    fail_counts[5] = test_counts[5]
    nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
    message, error_message, /NONAME
  endif
  nsp_test_export_csv
  catch, /cancel
  pass_counts[5] = test_counts[5]

  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    fail_counts[6] = test_counts[6]
    nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
    message, error_message, /NONAME
  endif
  nsp_test_batch
  catch, /cancel
  pass_counts[6] = test_counts[6]

  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    fail_counts[7] = test_counts[7]
    nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
    message, error_message, /NONAME
  endif
  nsp_test_validate_outputs
  catch, /cancel
  pass_counts[7] = test_counts[7]

  nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
end
