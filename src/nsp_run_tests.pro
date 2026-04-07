;+
; NAME:
;   NSP_PRINT_TEST_RESULTS_TABLE
;
; PURPOSE:
;   Prints a formatted summary table of test suite results to the IDL
;   console.  Each row shows the suite name, total expected tests, pass
;   count, and fail count.
;   Called internally by NSP_RUN_TESTS.
;
; CATEGORY:
;   NAIF Satellite Position / Testing
;
; CALLING SEQUENCE:
;   NSP_PRINT_TEST_RESULTS_TABLE, test_names, test_counts, pass_counts, fail_counts
;
; INPUTS:
;   test_names  - STRING array. Suite names (one per row).
;   test_counts - LONG array. Expected number of tests per suite.
;   pass_counts - LONG array. Number of tests that passed per suite.
;   fail_counts - LONG array. Number of tests that failed per suite.
;
; OUTPUTS:
;   None. Prints a tabular summary to stdout.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_print_test_results_table, test_names, test_counts, pass_counts, fail_counts
  compile_opt strictarr

  print, 'Test Results'
  print, string('Test Name', 'Total', 'Pass', 'Fail', format='(A24,2X,A5,2X,A4,2X,A4)')
  print, '------------------------  -----  ----  ----'

  for i = 0L, n_elements(test_names) - 1L do begin
    print, string(test_names[i], test_counts[i], pass_counts[i], fail_counts[i], format='(A24,2X,I5,2X,I4,2X,I4)')
  endfor
end


;+
; NAME:
;   NSP_RUN_TESTS
;
; PURPOSE:
;   Runs the full NSP test suite across all eight pipeline steps (Steps 4–11).
;   Calls NSP_RUN_PIPELINE first to initialise the SPICE kernel pool, then
;   executes each step's test routine in order.  A failing suite prints the
;   partial results table and re-raises the error; a passing suite increments
;   its pass counter.  The final results table is always printed.
;
;   All NSP source and test routines must be on !PATH before calling this
;   procedure.  The recommended invocation from the shell is:
;
;     idl -e "!path = EXPAND_PATH('+src') + ':' + EXPAND_PATH('+tests') + ':' + !path" \
;         -e "NSP_RUN_TESTS"
;
; CATEGORY:
;   NAIF Satellite Position / Testing
;
; CALLING SEQUENCE:
;   NSP_RUN_TESTS [, ICY_DLM_PATH=icy_dlm_path]
;
; OPTIONAL KEYWORDS:
;   ICY_DLM_PATH - STRING. Override path to the ICY DLM directory.
;                  Passed through to NSP_RUN_PIPELINE.
;
; OUTPUTS:
;   None. Prints per-suite progress and a final results table.
;   Re-raises the first suite-level error encountered, halting execution.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_run_tests, icy_dlm_path=icy_dlm_path
  compile_opt strictarr

  test_names = ['Step 4 Time Handling', 'Step 5 State Vectors', 'Step 6 Geometry', 'Step 7 Solar Geometry', 'Step 8 Occultation', 'Step 9 Export', 'Step 10 Batch', 'Step 11 Validation']
  test_counts = [7L, 2L, 2L, 2L, 4L, 3L, 4L, 4L]
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
