pro nsp_test_batch_valid_config
  compile_opt strictarr

  nsp_run_batch, config_path='config/test_batch_valid.yaml', success_count=success_count, failure_count=failure_count, succeeded_case_ids=succeeded_case_ids, failed_case_ids=failed_case_ids, output_paths=output_paths

  nsp_assert_true, success_count eq 2L, 'Step 10 valid batch test expected two successful cases.'
  nsp_assert_true, failure_count eq 0L, 'Step 10 valid batch test expected zero failed cases.'
  nsp_assert_true, n_elements(succeeded_case_ids) eq 2L, 'Step 10 valid batch test expected two successful case identifiers.'
  nsp_assert_true, succeeded_case_ids[0] eq 'batch_valid_a', 'Step 10 valid batch test did not preserve the first case order.'
  nsp_assert_true, succeeded_case_ids[1] eq 'batch_valid_b', 'Step 10 valid batch test did not preserve the second case order.'
  nsp_assert_true, failed_case_ids[0] eq '', 'Step 10 valid batch test should leave the failed-case sentinel blank when no failures occur.'
  nsp_assert_true, n_elements(output_paths) eq 2L, 'Step 10 valid batch test expected two output paths.'
  nsp_assert_true, file_test(output_paths[0], /REGULAR), 'Step 10 valid batch test did not create the first output file.'
  nsp_assert_true, file_test(output_paths[1], /REGULAR), 'Step 10 valid batch test did not create the second output file.'

  nsp_read_two_line_text_file, output_paths[0], header_line=header_line_a, data_line=data_line_a
  nsp_read_two_line_text_file, output_paths[1], header_line=header_line_b, data_line=data_line_b

  fields_a = strsplit(data_line_a, ',', /extract)
  fields_b = strsplit(data_line_b, ',', /extract)

  nsp_assert_true, n_elements(fields_a) eq 22, 'Step 10 valid batch test expected the first batch output to use the base Step 9 schema.'
  nsp_assert_true, n_elements(fields_b) eq 30, 'Step 10 valid batch test expected the second batch output to include Keplerian columns.'
end


pro nsp_test_batch_failure_isolation
  compile_opt strictarr

  nsp_run_batch, config_path='config/test_batch_mixed.yaml', success_count=success_count, failure_count=failure_count, succeeded_case_ids=succeeded_case_ids, failed_case_ids=failed_case_ids, output_paths=output_paths

  nsp_assert_true, success_count eq 2L, 'Step 10 mixed batch test expected two successful cases.'
  nsp_assert_true, failure_count eq 1L, 'Step 10 mixed batch test expected one isolated failed case.'
  nsp_assert_true, n_elements(succeeded_case_ids) eq 2L, 'Step 10 mixed batch test expected two successful case identifiers.'
  nsp_assert_true, n_elements(failed_case_ids) eq 1L, 'Step 10 mixed batch test expected one failed case identifier.'
  nsp_assert_true, succeeded_case_ids[0] eq 'batch_mixed_a', 'Step 10 mixed batch test did not preserve the first successful case order.'
  nsp_assert_true, succeeded_case_ids[1] eq 'batch_mixed_c', 'Step 10 mixed batch test did not preserve the later successful case order after a failure.'
  nsp_assert_true, failed_case_ids[0] eq 'batch_mixed_bad', 'Step 10 mixed batch test did not report the failing case identifier.'
  nsp_assert_true, n_elements(output_paths) eq 2L, 'Step 10 mixed batch test expected only successful outputs to be returned.'
  nsp_assert_true, file_test(output_paths[0], /REGULAR), 'Step 10 mixed batch test did not create the first successful output file.'
  nsp_assert_true, file_test(output_paths[1], /REGULAR), 'Step 10 mixed batch test did not create the second successful output file.'
  nsp_assert_true, ~file_test(file_expand_path('outputs/batch_mixed_bad.csv'), /REGULAR), 'Step 10 mixed batch test should not leave a misleading output file for the failed case.'
end


pro nsp_test_batch
  compile_opt strictarr

  nsp_test_batch_valid_config
  nsp_test_batch_failure_isolation

  print, 'Step 10 tests passed.'
  print, 'Validated deterministic YAML batch execution, per-case outputs, and isolated case failures.'
end
