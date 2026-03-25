pro nsp_read_text_file_lines, file_path, lines=lines
  compile_opt strictarr

  if ~file_test(file_path, /REGULAR) then begin
    message, 'Batch tests failed: expected text file was not found: ' + file_path, /NONAME
  endif

  line_list = List()
  openr, lun, file_path, /get_lun

  while ~eof(lun) do begin
    line_value = ''
    readf, lun, line_value, format='(A)'
    line_list.Add, line_value
  endwhile

  free_lun, lun
  lines = line_list.ToArray()
  obj_destroy, line_list
end


pro nsp_write_text_file_lines, file_path, lines
  compile_opt strictarr

  openw, lun, file_path, /get_lun
  for i = 0L, n_elements(lines) - 1L do begin
    printf, lun, lines[i]
  endfor
  free_lun, lun
end


pro nsp_test_batch_valid_config
  compile_opt strictarr

  expected_output_path = file_expand_path('outputs/test_batch_valid.csv')
  if file_test(expected_output_path, /REGULAR) then file_delete, expected_output_path
  if file_test(file_expand_path('outputs/batch_valid_a.csv'), /REGULAR) then file_delete, file_expand_path('outputs/batch_valid_a.csv')
  if file_test(file_expand_path('outputs/batch_valid_series_2025_01_01_001000.csv'), /REGULAR) then file_delete, file_expand_path('outputs/batch_valid_series_2025_01_01_001000.csv')
  if file_test(file_expand_path('outputs/batch_valid_series_2025_01_01_002000.csv'), /REGULAR) then file_delete, file_expand_path('outputs/batch_valid_series_2025_01_01_002000.csv')
  if file_test(file_expand_path('outputs/batch_valid_series_2025_01_01_003000.csv'), /REGULAR) then file_delete, file_expand_path('outputs/batch_valid_series_2025_01_01_003000.csv')

  nsp_run_batch, config_path='config/test_batch_valid.yaml', success_count=success_count, failure_count=failure_count, succeeded_case_ids=succeeded_case_ids, failed_case_ids=failed_case_ids, output_paths=output_paths

  nsp_assert_true, success_count eq 4L, 'Step 10 valid batch test expected four successful cases.'
  nsp_assert_true, failure_count eq 0L, 'Step 10 valid batch test expected zero failed cases.'
  nsp_assert_true, n_elements(succeeded_case_ids) eq 4L, 'Step 10 valid batch test expected four successful case identifiers.'
  nsp_assert_true, succeeded_case_ids[0] eq 'batch_valid_a', 'Step 10 valid batch test did not preserve the first case order.'
  nsp_assert_true, succeeded_case_ids[1] eq 'batch_valid_series_2025_01_01_001000', 'Step 10 valid batch test did not expand the first UTC range case correctly.'
  nsp_assert_true, succeeded_case_ids[2] eq 'batch_valid_series_2025_01_01_002000', 'Step 10 valid batch test did not preserve the expanded UTC range order.'
  nsp_assert_true, succeeded_case_ids[3] eq 'batch_valid_series_2025_01_01_003000', 'Step 10 valid batch test did not expand the final UTC range case correctly.'
  nsp_assert_true, failed_case_ids[0] eq '', 'Step 10 valid batch test should leave the failed-case sentinel blank when no failures occur.'
  nsp_assert_true, n_elements(output_paths) eq 1L, 'Step 10 valid batch test expected one aggregate output path.'
  nsp_assert_true, output_paths[0] eq expected_output_path, 'Step 10 valid batch test did not return the expected aggregate output path.'
  nsp_assert_true, file_test(output_paths[0], /REGULAR), 'Step 10 valid batch test did not create the aggregate output file.'

  nsp_read_text_file_lines, output_paths[0], lines=lines
  nsp_assert_true, n_elements(lines) eq 5L, 'Step 10 valid batch test expected one header row plus four data rows.'

  header_fields = strsplit(lines[0], ',', /extract)
  row_a_fields = strsplit(lines[1], ',', /extract)
  row_b_fields = strsplit(lines[2], ',', /extract)
  row_d_fields = strsplit(lines[4], ',', /extract)

  nsp_assert_true, n_elements(header_fields) eq 32L, 'Step 10 valid batch test expected aggregate output to include Keplerian and batch-status columns.'
  nsp_assert_true, n_elements(row_a_fields) eq 32L, 'Step 10 valid batch test expected the first aggregate data row to match the aggregate schema.'
  nsp_assert_true, n_elements(row_b_fields) eq 32L, 'Step 10 valid batch test expected the first expanded aggregate data row to match the aggregate schema.'
  nsp_assert_true, n_elements(row_d_fields) eq 32L, 'Step 10 valid batch test expected the final expanded aggregate data row to match the aggregate schema.'

  nsp_assert_true, row_a_fields[0] eq 'batch_valid_a', 'Step 10 valid batch test wrote an incorrect case_id for the first aggregate row.'
  nsp_assert_true, row_b_fields[0] eq 'batch_valid_series_2025_01_01_001000', 'Step 10 valid batch test wrote an incorrect case_id for the first expanded aggregate row.'
  nsp_assert_true, row_d_fields[0] eq 'batch_valid_series_2025_01_01_003000', 'Step 10 valid batch test wrote an incorrect case_id for the final aggregate row.'
  nsp_assert_true, row_a_fields[30] eq 'success', 'Step 10 valid batch test expected success status for the first aggregate row.'
  nsp_assert_true, row_b_fields[30] eq 'success', 'Step 10 valid batch test expected success status for the expanded aggregate row.'
  nsp_assert_true, row_d_fields[30] eq 'success', 'Step 10 valid batch test expected success status for the final aggregate row.'
  nsp_assert_true, row_a_fields[31] eq 'none', 'Step 10 valid batch test expected a placeholder failure message for successful aggregate rows.'
  nsp_assert_true, strpos(strlowcase(row_a_fields[22]), 'nan') ge 0, 'Step 10 valid batch test expected non-Keplerian rows to mark aggregate Keplerian columns as NaN.'
  nsp_assert_true, finite(double(row_b_fields[22])), 'Step 10 valid batch test expected Keplerian aggregate rows to populate the first Keplerian column.'
  nsp_assert_true, finite(double(row_d_fields[22])), 'Step 10 valid batch test expected final Keplerian aggregate rows to populate the first Keplerian column.'
end


pro nsp_test_batch_failure_isolation
  compile_opt strictarr

  expected_output_path = file_expand_path('outputs/test_batch_mixed.csv')
  if file_test(expected_output_path, /REGULAR) then file_delete, expected_output_path
  if file_test(file_expand_path('outputs/batch_mixed_a.csv'), /REGULAR) then file_delete, file_expand_path('outputs/batch_mixed_a.csv')
  if file_test(file_expand_path('outputs/batch_mixed_bad.csv'), /REGULAR) then file_delete, file_expand_path('outputs/batch_mixed_bad.csv')
  if file_test(file_expand_path('outputs/batch_mixed_c.csv'), /REGULAR) then file_delete, file_expand_path('outputs/batch_mixed_c.csv')

  nsp_run_batch, config_path='config/test_batch_mixed.yaml', success_count=success_count, failure_count=failure_count, succeeded_case_ids=succeeded_case_ids, failed_case_ids=failed_case_ids, output_paths=output_paths

  nsp_assert_true, success_count eq 2L, 'Step 10 mixed batch test expected two successful cases.'
  nsp_assert_true, failure_count eq 1L, 'Step 10 mixed batch test expected one isolated failed case.'
  nsp_assert_true, n_elements(succeeded_case_ids) eq 2L, 'Step 10 mixed batch test expected two successful case identifiers.'
  nsp_assert_true, n_elements(failed_case_ids) eq 1L, 'Step 10 mixed batch test expected one failed case identifier.'
  nsp_assert_true, succeeded_case_ids[0] eq 'batch_mixed_a', 'Step 10 mixed batch test did not preserve the first successful case order.'
  nsp_assert_true, succeeded_case_ids[1] eq 'batch_mixed_c', 'Step 10 mixed batch test did not preserve the later successful case order after a failure.'
  nsp_assert_true, failed_case_ids[0] eq 'batch_mixed_bad', 'Step 10 mixed batch test did not report the failing case identifier.'
  nsp_assert_true, n_elements(output_paths) eq 1L, 'Step 10 mixed batch test expected one aggregate output path.'
  nsp_assert_true, output_paths[0] eq expected_output_path, 'Step 10 mixed batch test did not return the expected aggregate output path.'
  nsp_assert_true, file_test(output_paths[0], /REGULAR), 'Step 10 mixed batch test did not create the aggregate output file.'
  nsp_assert_true, ~file_test(file_expand_path('outputs/batch_mixed_bad.csv'), /REGULAR), 'Step 10 mixed batch test should not leave a misleading per-case output file for the failed case.'

  nsp_read_text_file_lines, output_paths[0], lines=lines
  nsp_assert_true, n_elements(lines) eq 4L, 'Step 10 mixed batch test expected one header row plus three data rows.'

  row_a_fields = strsplit(lines[1], ',', /extract)
  row_bad_fields = strsplit(lines[2], ',', /extract)
  row_c_fields = strsplit(lines[3], ',', /extract)

  nsp_assert_true, row_a_fields[0] eq 'batch_mixed_a', 'Step 10 mixed batch test wrote the wrong first aggregate case_id.'
  nsp_assert_true, row_bad_fields[0] eq 'batch_mixed_bad', 'Step 10 mixed batch test wrote the wrong failed aggregate case_id.'
  nsp_assert_true, row_c_fields[0] eq 'batch_mixed_c', 'Step 10 mixed batch test wrote the wrong final aggregate case_id.'
  nsp_assert_true, row_a_fields[22] eq 'success', 'Step 10 mixed batch test expected success status for the first aggregate row.'
  nsp_assert_true, row_bad_fields[22] eq 'failed', 'Step 10 mixed batch test expected failed status for the bad aggregate row.'
  nsp_assert_true, row_c_fields[22] eq 'success', 'Step 10 mixed batch test expected success status for the final aggregate row.'
  nsp_assert_true, strpos(strlowcase(row_bad_fields[23]), 'unable to convert utc to et') ge 0, 'Step 10 mixed batch test expected the failed aggregate row to preserve the case failure reason.'
  nsp_assert_true, strpos(strlowcase(row_bad_fields[2]), 'nan') ge 0, 'Step 10 mixed batch test expected failed aggregate rows to mark ET as NaN.'
end


pro nsp_test_batch_invalid_range_config
  compile_opt strictarr

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    return
  endif

  nsp_read_batch_cases, config_path='config/test_batch_invalid_range.yaml', case_ids=case_ids, utc_strings=utc_strings, include_keplerian_values=include_keplerian_values, output_filenames=output_filenames
  catch, /cancel

  message, 'Step 10 invalid range batch test expected nsp_read_batch_cases to fail for a non-integral UTC range.', /NONAME
end


pro nsp_test_batch_occultation_event_extraction
  compile_opt strictarr

  synthetic_output_path = file_expand_path('outputs/test_batch_occultation_events.csv')
  if file_test(synthetic_output_path, /REGULAR) then file_delete, synthetic_output_path

  lines = [ $
    'case_id,utc,occultation_valid,tangent_altitude_km,batch_status,failure_message', $
    'profile_000000,2025-01-01T00:00:00,1,160,success,none', $
    'profile_000500,2025-01-01T00:05:00,1,140,success,none', $
    'profile_001000,2025-01-01T00:10:00,1,90,success,none', $
    'profile_001500,2025-01-01T00:15:00,1,20,success,none', $
    'profile_002000,2025-01-01T00:20:00,1,-5,success,none', $
    'profile_002500,2025-01-01T00:25:00,1,5,success,none', $
    'profile_003000,2025-01-01T00:30:00,1,60,success,none', $
    'profile_003500,2025-01-01T00:35:00,1,140,success,none', $
    'profile_004000,2025-01-01T00:40:00,1,170,success,none']
  nsp_write_text_file_lines, synthetic_output_path, lines

  nsp_extract_occultation_events, synthetic_output_path, events=events, event_count=event_count

  nsp_assert_true, event_count eq 2L, 'Step 10 occultation-event test expected two extracted events.'
  nsp_assert_true, n_elements(events.event_id) eq 2L, 'Step 10 occultation-event test expected two event identifiers.'
  nsp_assert_true, events.event_type[0] eq 'ingress', 'Step 10 occultation-event test expected the first event to be classified as ingress.'
  nsp_assert_true, events.event_type[1] eq 'egress', 'Step 10 occultation-event test expected the second event to be classified as egress.'
  nsp_assert_true, events.start_case_id[0] eq 'profile_000500', 'Step 10 occultation-event test found the wrong ingress start case.'
  nsp_assert_true, events.end_case_id[0] eq 'profile_001500', 'Step 10 occultation-event test found the wrong ingress end case.'
  nsp_assert_true, events.start_case_id[1] eq 'profile_002500', 'Step 10 occultation-event test found the wrong egress start case.'
  nsp_assert_true, events.end_case_id[1] eq 'profile_003500', 'Step 10 occultation-event test found the wrong egress end case.'
  nsp_assert_true, events.sample_count[0] eq 3L, 'Step 10 occultation-event test expected three samples in the ingress event.'
  nsp_assert_true, events.sample_count[1] eq 3L, 'Step 10 occultation-event test expected three samples in the egress event.'
  nsp_assert_true, abs(events.minimum_tangent_altitude_km[0] - 20D) lt 1D-10, 'Step 10 occultation-event test found the wrong ingress minimum tangent altitude.'
  nsp_assert_true, abs(events.maximum_tangent_altitude_km[1] - 140D) lt 1D-10, 'Step 10 occultation-event test found the wrong egress maximum tangent altitude.'
end


pro nsp_test_batch
  compile_opt strictarr

  nsp_test_batch_valid_config
  nsp_test_batch_failure_isolation
  nsp_test_batch_invalid_range_config
  nsp_test_batch_occultation_event_extraction

  print, 'Step 10 tests passed.'
  print, 'Validated deterministic YAML batch execution, UTC range expansion, aggregate single-file output, isolated case failures, and occultation-event extraction.'
end
