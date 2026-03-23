pro nsp_run_batch, config_path=config_path, meta_kernel_name=meta_kernel_name, icy_dlm_path=icy_dlm_path, global_include_keplerian_elements=global_include_keplerian_elements, success_count=success_count, failure_count=failure_count, succeeded_case_ids=succeeded_case_ids, failed_case_ids=failed_case_ids, output_paths=output_paths
  compile_opt strictarr

  src_directory = file_expand_path('src')
  path_with_separators = ':' + !PATH + ':'
  src_with_separators = ':' + src_directory + ':'

  if ~file_test(src_directory, /DIRECTORY) then begin
    message, 'nsp_run_batch failed: required source directory was not found relative to the current working directory: ' + src_directory, /NONAME
  endif

  if strpos(path_with_separators, src_with_separators) lt 0 then begin
    !PATH = src_directory + ':' + !PATH
  endif

  nsp_run_pipeline, meta_kernel_name=meta_kernel_name, icy_dlm_path=icy_dlm_path
  nsp_read_batch_cases, config_path=config_path, case_ids=case_ids, utc_strings=utc_strings, include_keplerian_values=include_keplerian_values, output_filenames=output_filenames

  case_count = n_elements(case_ids)
  success_count = 0L
  failure_count = 0L
  succeeded_case_ids = strarr(case_count)
  failed_case_ids = strarr(case_count)
  output_paths = strarr(case_count)

  for i = 0L, case_count - 1L do begin
    case_identifier = case_ids[i]
    utc_value = utc_strings[i]
    include_keplerian_for_case = keyword_set(global_include_keplerian_elements) or (include_keplerian_values[i] eq 1L)

    print, 'Step 10 batch case start: case_id=' + case_identifier
    print, 'Step 10 batch case UTC=' + utc_value

    catch, error_status
    if error_status ne 0 then begin
      error_message = !ERROR_STATE.MSG
      catch, /cancel
      failed_case_ids[failure_count] = case_identifier
      failure_count = failure_count + 1L
      print, 'Step 10 batch case failed: case_id=' + case_identifier
      print, 'Failure reason=' + error_message
      continue
    endif

    nsp_export_csv, utc_string=utc_value, case_id=case_identifier, output_filename=output_filenames[i], output_path=exported_output_path, include_keplerian_elements=include_keplerian_for_case
    catch, /cancel

    succeeded_case_ids[success_count] = case_identifier
    output_paths[success_count] = exported_output_path
    success_count = success_count + 1L
    print, 'Step 10 batch case passed: case_id=' + case_identifier
  endfor

  if success_count gt 0L then begin
    succeeded_case_ids = succeeded_case_ids[0:success_count - 1L]
    output_paths = output_paths[0:success_count - 1L]
  endif else begin
    succeeded_case_ids = ['']
    output_paths = ['']
  endelse

  if failure_count gt 0L then begin
    failed_case_ids = failed_case_ids[0:failure_count - 1L]
  endif else begin
    failed_case_ids = ['']
  endelse

  print, 'Step 10 batch execution completed.'
  print, 'Batch successes=' + strtrim(success_count, 2)
  print, 'Batch failures=' + strtrim(failure_count, 2)

  if success_count eq 0L then begin
    message, 'Step 10 batch execution failed: all configured batch cases failed.', /NONAME
  endif
end
