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

  nsp_assert_true, n_elements(header_fields) eq 34L, 'Step 10 valid batch test expected aggregate output to include Keplerian, subsolar, and batch-status columns.'
  nsp_assert_true, n_elements(row_a_fields) eq 34L, 'Step 10 valid batch test expected the first aggregate data row to match the aggregate schema.'
  nsp_assert_true, n_elements(row_b_fields) eq 34L, 'Step 10 valid batch test expected the first expanded aggregate data row to match the aggregate schema.'
  nsp_assert_true, n_elements(row_d_fields) eq 34L, 'Step 10 valid batch test expected the final expanded aggregate data row to match the aggregate schema.'

  nsp_assert_true, row_a_fields[0] eq 'batch_valid_a', 'Step 10 valid batch test wrote an incorrect case_id for the first aggregate row.'
  nsp_assert_true, row_b_fields[0] eq 'batch_valid_series_2025_01_01_001000', 'Step 10 valid batch test wrote an incorrect case_id for the first expanded aggregate row.'
  nsp_assert_true, row_d_fields[0] eq 'batch_valid_series_2025_01_01_003000', 'Step 10 valid batch test wrote an incorrect case_id for the final aggregate row.'
  nsp_assert_true, row_a_fields[32] eq 'success', 'Step 10 valid batch test expected success status for the first aggregate row.'
  nsp_assert_true, row_b_fields[32] eq 'success', 'Step 10 valid batch test expected success status for the expanded aggregate row.'
  nsp_assert_true, row_d_fields[32] eq 'success', 'Step 10 valid batch test expected success status for the final aggregate row.'
  nsp_assert_true, row_a_fields[33] eq 'none', 'Step 10 valid batch test expected a placeholder failure message for successful aggregate rows.'
  nsp_assert_true, strpos(strlowcase(row_a_fields[24]), 'nan') ge 0, 'Step 10 valid batch test expected non-Keplerian rows to mark aggregate Keplerian columns as NaN.'
  nsp_assert_true, finite(double(row_b_fields[24])), 'Step 10 valid batch test expected Keplerian aggregate rows to populate the first Keplerian column.'
  nsp_assert_true, finite(double(row_d_fields[24])), 'Step 10 valid batch test expected final Keplerian aggregate rows to populate the first Keplerian column.'
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
  nsp_assert_true, row_a_fields[24] eq 'success', 'Step 10 mixed batch test expected success status for the first aggregate row.'
  nsp_assert_true, row_bad_fields[24] eq 'failed', 'Step 10 mixed batch test expected failed status for the bad aggregate row.'
  nsp_assert_true, row_c_fields[24] eq 'success', 'Step 10 mixed batch test expected success status for the final aggregate row.'
  nsp_assert_true, strpos(strlowcase(row_bad_fields[25]), 'unable to convert utc to et') ge 0, 'Step 10 mixed batch test expected the failed aggregate row to preserve the case failure reason.'
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

  deg_to_rad = !dpi / 180D
  lat10 = strtrim(string(10D * deg_to_rad, format='(E24.16)'), 2)
  lat11 = strtrim(string(11D * deg_to_rad, format='(E24.16)'), 2)
  lat12 = strtrim(string(12D * deg_to_rad, format='(E24.16)'), 2)
  lat13 = strtrim(string(13D * deg_to_rad, format='(E24.16)'), 2)
  lat14 = strtrim(string(14D * deg_to_rad, format='(E24.16)'), 2)
  lat21 = strtrim(string(21D * deg_to_rad, format='(E24.16)'), 2)
  lat22 = strtrim(string(22D * deg_to_rad, format='(E24.16)'), 2)
  lat23 = strtrim(string(23D * deg_to_rad, format='(E24.16)'), 2)
  lat24 = strtrim(string(24D * deg_to_rad, format='(E24.16)'), 2)
  lon100 = strtrim(string(100D * deg_to_rad, format='(E24.16)'), 2)
  lon101 = strtrim(string(101D * deg_to_rad, format='(E24.16)'), 2)
  lon102 = strtrim(string(102D * deg_to_rad, format='(E24.16)'), 2)
  lon103 = strtrim(string(103D * deg_to_rad, format='(E24.16)'), 2)
  lon104 = strtrim(string(104D * deg_to_rad, format='(E24.16)'), 2)
  lon111 = strtrim(string(111D * deg_to_rad, format='(E24.16)'), 2)
  lon112 = strtrim(string(112D * deg_to_rad, format='(E24.16)'), 2)
  lon113 = strtrim(string(113D * deg_to_rad, format='(E24.16)'), 2)
  lon114 = strtrim(string(114D * deg_to_rad, format='(E24.16)'), 2)
  sat_lat = strtrim(string((-5D) * deg_to_rad, format='(E24.16)'), 2)
  sat_lon = strtrim(string((45D) * deg_to_rad, format='(E24.16)'), 2)
  sat_alt = '4.0000000000000000E+02'
  ss_lat = strtrim(string(30D * deg_to_rad, format='(E24.16)'), 2)
  ss_lon_0 = strtrim(string(200D * deg_to_rad, format='(E24.16)'), 2)
  ss_lon_1 = strtrim(string(201D * deg_to_rad, format='(E24.16)'), 2)
  ss_lon_2 = strtrim(string(202D * deg_to_rad, format='(E24.16)'), 2)
  ss_lon_3 = strtrim(string(203D * deg_to_rad, format='(E24.16)'), 2)
  ss_lon_4 = strtrim(string(204D * deg_to_rad, format='(E24.16)'), 2)
  ss_lon_5 = strtrim(string(205D * deg_to_rad, format='(E24.16)'), 2)
  ss_lon_6 = strtrim(string(206D * deg_to_rad, format='(E24.16)'), 2)
  ss_lon_7 = strtrim(string(207D * deg_to_rad, format='(E24.16)'), 2)
  ss_lon_8 = strtrim(string(208D * deg_to_rad, format='(E24.16)'), 2)
  lines = [ $
    'case_id,utc,et,sc_latitude_rad,sc_longitude_rad,sc_altitude_km,subsolar_latitude_rad,subsolar_longitude_rad,occultation_valid,tangent_latitude_rad,tangent_longitude_rad,tangent_altitude_km,batch_status,failure_message', $
    'profile_000000,2025-01-01T00:00:00,0,' + sat_lat + ',' + sat_lon + ',' + sat_alt + ',' + ss_lat + ',' + ss_lon_0 + ',0,' + lat10 + ',' + lon100 + ',160,success,none', $
    'profile_000500,2025-01-01T00:05:00,10,' + sat_lat + ',' + sat_lon + ',' + sat_alt + ',' + ss_lat + ',' + ss_lon_1 + ',1,' + lat11 + ',' + lon101 + ',140,success,none', $
    'profile_001000,2025-01-01T00:10:00,20,' + sat_lat + ',' + sat_lon + ',' + sat_alt + ',' + ss_lat + ',' + ss_lon_2 + ',1,' + lat12 + ',' + lon102 + ',90,success,none', $
    'profile_001500,2025-01-01T00:15:00,30,' + sat_lat + ',' + sat_lon + ',' + sat_alt + ',' + ss_lat + ',' + ss_lon_3 + ',1,' + lat13 + ',' + lon103 + ',20,success,none', $
    'profile_002000,2025-01-01T00:20:00,40,' + sat_lat + ',' + sat_lon + ',' + sat_alt + ',' + ss_lat + ',' + ss_lon_4 + ',1,' + lat14 + ',' + lon104 + ',-5,success,none', $
    'profile_002500,2025-01-01T00:25:00,50,' + sat_lat + ',' + sat_lon + ',' + sat_alt + ',' + ss_lat + ',' + ss_lon_5 + ',1,' + lat21 + ',' + lon111 + ',5,success,none', $
    'profile_003000,2025-01-01T00:30:00,60,' + sat_lat + ',' + sat_lon + ',' + sat_alt + ',' + ss_lat + ',' + ss_lon_6 + ',1,' + lat22 + ',' + lon112 + ',60,success,none', $
    'profile_003500,2025-01-01T00:35:00,70,' + sat_lat + ',' + sat_lon + ',' + sat_alt + ',' + ss_lat + ',' + ss_lon_7 + ',1,' + lat23 + ',' + lon113 + ',140,success,none', $
    'profile_004000,2025-01-01T00:40:00,80,' + sat_lat + ',' + sat_lon + ',' + sat_alt + ',' + ss_lat + ',' + ss_lon_8 + ',0,' + lat24 + ',' + lon114 + ',170,success,none']
  nsp_write_text_file_lines, synthetic_output_path, lines

  nsp_extract_occultation_events, synthetic_output_path, survey=survey, event_count=event_count

  nsp_assert_true, n_elements(survey.time) eq 9L, 'Step 10 occultation-event test expected survey.time to include all input rows.'
  nsp_assert_true, n_elements(survey.tang_alt) eq 9L, 'Step 10 occultation-event test expected survey.tang_alt to include all input rows.'
  nsp_assert_true, n_elements(survey.tang_lat) eq 9L, 'Step 10 occultation-event test expected survey.tang_lat to include all input rows.'
  nsp_assert_true, n_elements(survey.tang_lon) eq 9L, 'Step 10 occultation-event test expected survey.tang_lon to include all input rows.'
  nsp_assert_true, n_elements(survey.n_int) eq 9L, 'Step 10 occultation-event test expected survey.n_int to include all input rows.'
  nsp_assert_true, n_elements(survey.sat_lat) eq 9L, 'Step 10 occultation-event test expected survey.sat_lat to include all input rows.'
  nsp_assert_true, n_elements(survey.sat_lon) eq 9L, 'Step 10 occultation-event test expected survey.sat_lon to include all input rows.'
  nsp_assert_true, n_elements(survey.sat_alt) eq 9L, 'Step 10 occultation-event test expected survey.sat_alt to include all input rows.'
  nsp_assert_true, n_elements(survey.ss_lon) eq 9L, 'Step 10 occultation-event test expected survey.ss_lon to include all input rows.'
  nsp_assert_true, abs(survey.tang_alt[0] - 160D) lt 1D-10, 'Step 10 occultation-event test should preserve rows with occultation_valid=0 in survey.tang_alt.'
  nsp_assert_true, abs(survey.tang_alt[8] - 170D) lt 1D-10, 'Step 10 occultation-event test should preserve the final occultation_valid=0 row in survey.tang_alt.'
  nsp_assert_true, event_count eq 2L, 'Step 10 occultation-event test expected two extracted events.'
  nsp_assert_true, survey.n_ingress eq 1L, 'Step 10 occultation-event test expected one ingress event.'
  nsp_assert_true, survey.n_egress eq 1L, 'Step 10 occultation-event test expected one egress event.'
  nsp_assert_true, finite(survey.ss_lat), 'Step 10 occultation-event test expected a finite scalar survey.ss_lat.'
  nsp_assert_true, abs(survey.ss_lat - 30D) lt 1D-8, 'Step 10 occultation-event test found the wrong scalar survey.ss_lat.'
  nsp_assert_true, survey.n_int[0] eq 0L, 'Step 10 occultation-event test expected no atmospheric intersection above altitude_max.'
  nsp_assert_true, survey.n_int[1] eq 1L, 'Step 10 occultation-event test expected an atmospheric intersection inside the event window.'
  nsp_assert_true, survey.n_int[4] eq 0L, 'Step 10 occultation-event test expected no atmospheric intersection below 0 km.'
  nsp_assert_true, survey.n_int[5] eq 1L, 'Step 10 occultation-event test expected an atmospheric intersection for the egress window.'
  nsp_assert_true, n_elements(survey.events) eq 2L, 'Step 10 occultation-event test expected survey.events to contain two event structs.'
  nsp_assert_true, survey.events[0].type eq 'ING', 'Step 10 occultation-event test expected the first event to be classified as ING.'
  nsp_assert_true, survey.events[1].type eq 'EGR', 'Step 10 occultation-event test expected the second event to be classified as EGR.'
  nsp_assert_true, survey.events[0].ingress eq 1B, 'Step 10 occultation-event test expected ingress flag 1 for the ING event.'
  nsp_assert_true, survey.events[1].ingress eq 0B, 'Step 10 occultation-event test expected ingress flag 0 for the EGR event.'
  nsp_assert_true, survey.events[0].i_start eq 1L, 'Step 10 occultation-event test found the wrong ING start index.'
  nsp_assert_true, survey.events[0].i_end eq 3L, 'Step 10 occultation-event test found the wrong ING end index.'
  nsp_assert_true, survey.events[1].i_start eq 5L, 'Step 10 occultation-event test found the wrong EGR start index.'
  nsp_assert_true, survey.events[1].i_end eq 7L, 'Step 10 occultation-event test found the wrong EGR end index.'
  nsp_assert_true, abs(survey.events[0].t_start_interp - 5D) lt 1D-10, 'Step 10 occultation-event test found the wrong ING interpolated start time.'
  nsp_assert_true, abs(survey.events[0].t_end_interp - 38D) lt 1D-10, 'Step 10 occultation-event test found the wrong ING interpolated end time.'
  nsp_assert_true, abs(survey.events[1].t_start_interp - 45D) lt 1D-10, 'Step 10 occultation-event test found the wrong EGR interpolated start time.'
  nsp_assert_true, abs(survey.events[1].t_end_interp - (220D / 3D)) lt 1D-10, 'Step 10 occultation-event test found the wrong EGR interpolated end time.'
  nsp_assert_true, abs(survey.events[0].t_start - 10D) lt 1D-10, 'Step 10 occultation-event test found the wrong ING sampled start time.'
  nsp_assert_true, abs(survey.events[0].t_end - 30D) lt 1D-10, 'Step 10 occultation-event test found the wrong ING sampled end time.'
  nsp_assert_true, abs(survey.events[1].t_start - 50D) lt 1D-10, 'Step 10 occultation-event test found the wrong EGR sampled start time.'
  nsp_assert_true, abs(survey.events[1].t_end - 70D) lt 1D-10, 'Step 10 occultation-event test found the wrong EGR sampled end time.'
  nsp_assert_true, abs(survey.events[0].duration_interp - 33D) lt 1D-10, 'Step 10 occultation-event test found the wrong ING interpolated duration.'
  nsp_assert_true, abs(survey.events[1].duration_interp - (85D / 3D)) lt 1D-10, 'Step 10 occultation-event test found the wrong EGR interpolated duration.'
  nsp_assert_true, abs(survey.events[0].tang_alt_min - 20D) lt 1D-10, 'Step 10 occultation-event test found the wrong ING minimum tangent altitude.'
  nsp_assert_true, abs(survey.events[1].tang_alt_min - 5D) lt 1D-10, 'Step 10 occultation-event test found the wrong EGR minimum tangent altitude.'
  nsp_assert_true, abs(survey.events[0].tang_alt_max - 140D) lt 1D-10, 'Step 10 occultation-event test found the wrong ING maximum tangent altitude.'
  nsp_assert_true, abs(survey.events[1].tang_alt_max - 140D) lt 1D-10, 'Step 10 occultation-event test found the wrong EGR maximum tangent altitude.'
  nsp_assert_true, abs(survey.events[0].lat_min - 13D) lt 1D-8, 'Step 10 occultation-event test found the wrong ING latitude at minimum tangent altitude.'
  nsp_assert_true, abs(survey.events[0].lon_min - 103D) lt 1D-8, 'Step 10 occultation-event test found the wrong ING longitude at minimum tangent altitude.'
  nsp_assert_true, abs(survey.events[0].lat_max - 11D) lt 1D-8, 'Step 10 occultation-event test found the wrong ING latitude at maximum tangent altitude.'
  nsp_assert_true, abs(survey.events[0].lon_max - 101D) lt 1D-8, 'Step 10 occultation-event test found the wrong ING longitude at maximum tangent altitude.'
  nsp_assert_true, abs(survey.events[1].lat_min - 21D) lt 1D-8, 'Step 10 occultation-event test found the wrong EGR latitude at minimum tangent altitude.'
  nsp_assert_true, abs(survey.events[1].lon_min - 111D) lt 1D-8, 'Step 10 occultation-event test found the wrong EGR longitude at minimum tangent altitude.'
  nsp_assert_true, abs(survey.events[1].lat_max - 23D) lt 1D-8, 'Step 10 occultation-event test found the wrong EGR latitude at maximum tangent altitude.'
  nsp_assert_true, abs(survey.events[1].lon_max - 113D) lt 1D-8, 'Step 10 occultation-event test found the wrong EGR longitude at maximum tangent altitude.'
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
