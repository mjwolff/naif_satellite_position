; Return the aggregate batch CSV filename derived from a batch config path.
;
; Calling sequence:
;   output_filename = nsp_batch_output_filename_from_config_path(config_path)
;
; Inputs:
;   config_path - batch YAML path whose basename becomes the CSV filename.
;
; Returns:
;   A simple filename such as 'test_batch_valid.csv'.
function nsp_batch_output_filename_from_config_path, config_path
  compile_opt strictarr

  resolved_config_path = file_expand_path(strtrim(config_path, 2))
  config_basename = file_basename(resolved_config_path)
  basename_length = strlen(config_basename)

  if basename_length gt 5 then begin
    if strlowcase(strmid(config_basename, basename_length - 5, 5)) eq '.yaml' then begin
      config_basename = strmid(config_basename, 0, basename_length - 5)
    endif
  endif

  basename_length = strlen(config_basename)
  if basename_length gt 4 then begin
    if strlowcase(strmid(config_basename, basename_length - 4, 4)) eq '.yml' then begin
      config_basename = strmid(config_basename, 0, basename_length - 4)
    endif
  endif

  if strtrim(config_basename, 2) eq '' then begin
    message, 'Step 10 batch execution failed: unable to derive an aggregate output filename from the configuration path: ' + resolved_config_path, /NONAME
  endif

  return, config_basename + '.csv'
end


; Normalize a caught IDL error message for safe inclusion in one CSV field.
;
; Calling sequence:
;   safe_message = nsp_batch_safe_failure_message(raw_message)
;
; Inputs:
;   raw_message - scalar or array-valued error text from !ERROR_STATE.MSG.
;
; Returns:
;   A single-line message with embedded commas/newlines sanitized.
function nsp_batch_safe_failure_message, raw_message
  compile_opt strictarr

  if n_elements(raw_message) eq 0 then return, 'unknown_failure'

  if n_elements(raw_message) gt 1 then begin
    safe_message = strjoin(strtrim(raw_message, 2), ' ')
  endif else begin
    safe_message = strtrim(raw_message, 2)
  endelse

  if safe_message eq '' then return, 'unknown_failure'

  linefeed = string(10B, format='(A1)')
  carriage_return = string(13B, format='(A1)')

  char_values = strmid(safe_message, lindgen(strlen(safe_message)), 1)
  for i = 0L, n_elements(char_values) - 1L do begin
    if (char_values[i] eq linefeed) or (char_values[i] eq carriage_return) then char_values[i] = ' '
    if char_values[i] eq ',' then char_values[i] = ';'
  endfor

  safe_message = strjoin(char_values, '')
  safe_message = strtrim(safe_message, 2)

  if safe_message eq '' then return, 'unknown_failure'

  return, safe_message
end


; Build one aggregate CSV row for a failed batch case.
;
; Calling sequence:
;   nsp_batch_failure_row_values, case_id, utc_string, include_keplerian_columns, failure_message, row_values=row_values
;
; Inputs:
;   case_id                   - case identifier for the failed batch row.
;   utc_string                - UTC string associated with the failed case.
;   include_keplerian_columns - nonzero when the aggregate schema includes Keplerian columns.
;   failure_message           - human-readable failure text for the row.
;
; Outputs:
;   row_values - string array matching the aggregate CSV schema.
pro nsp_batch_failure_row_values, case_id, utc_string, include_keplerian_columns, failure_message, row_values=row_values
  compile_opt strictarr

  case_identifier = strtrim(case_id, 2)
  utc_value = strtrim(utc_string, 2)

  ; Preserve the explicit UTC failure wording when we already know it is safe.
  safe_failure_message = strtrim(failure_message, 2)
  if strpos(safe_failure_message, 'UTC to ET') lt 0 then begin
    safe_failure_message = nsp_batch_safe_failure_message(failure_message)
  endif

  ; Failure rows keep the same schema as success rows by filling science fields with NaN.
  base_nan_values = nsp_export_nan_values(n_elements(nsp_export_base_header()) - 2L)
  row_values = [case_identifier, utc_value, base_nan_values]

  if include_keplerian_columns then begin
    row_values = [row_values, nsp_export_nan_values(n_elements(nsp_export_keplerian_header()))]
  endif

  row_values = [row_values, 'failed', safe_failure_message]
end


; Execute deterministic YAML batch cases and write one aggregate CSV for the run.
;
; Calling sequence:
;   nsp_run_batch, [config_path=config_path], [meta_kernel_name=meta_kernel_name], $
;     [icy_dlm_path=icy_dlm_path], [debug=debug], $
;     [global_include_keplerian_elements=global_include_keplerian_elements], $
;     [success_count=success_count], [failure_count=failure_count], $
;     [succeeded_case_ids=succeeded_case_ids], [failed_case_ids=failed_case_ids], [output_paths=output_paths]
;
; Keywords:
;   CONFIG_PATH                        - optional YAML batch config path.
;   META_KERNEL_NAME                   - optional meta-kernel override passed through to NSP_RUN_PIPELINE.
;   ICY_DLM_PATH                       - optional ICY DLM override passed through to NSP_RUN_PIPELINE.
;   DEBUG                              - when set, passes /DEBUG to NSP_RUN_PIPELINE so Step 1
;                                        may use the local default KERNEL_PATH fallback.
;   GLOBAL_INCLUDE_KEPLERIAN_ELEMENTS  - when set, force Keplerian columns for all rows.
;   SUCCESS_COUNT / FAILURE_COUNT      - returned case counts.
;   SUCCEEDED_CASE_IDS / FAILED_CASE_IDS - returned case identifiers grouped by outcome.
;   OUTPUT_PATHS                       - one-element array containing the aggregate CSV path.
;
; Behavior:
;   Each configured or expanded case contributes exactly one row to the aggregate file.
;   Failed cases remain visible in the output with batch_status='failed' and NaN science values.
pro nsp_run_batch, $
  config_path=config_path, $
  meta_kernel_name=meta_kernel_name, $
  icy_dlm_path=icy_dlm_path, $
  debug=debug, $
  global_include_keplerian_elements=global_include_keplerian_elements, $
  success_count=success_count, $
  failure_count=failure_count, $
  succeeded_case_ids=succeeded_case_ids, $
  failed_case_ids=failed_case_ids, $
  output_paths=output_paths
  compile_opt strictarr

  ; Initialize the repository path and base pipeline before reading any batch cases.
  nsp_setup_path

  nsp_run_pipeline, meta_kernel_name=meta_kernel_name, icy_dlm_path=icy_dlm_path, debug=debug
  resolve_routine, 'nsp_read_batch_cases', /COMPILE_FULL_FILE
  resolve_routine, 'nsp_export_csv', /COMPILE_FULL_FILE
  nsp_read_batch_cases, $
    config_path=config_path, $
    case_ids=case_ids, $
    utc_strings=utc_strings, $
    include_keplerian_values=include_keplerian_values, $
    output_filenames=output_filenames

  ; Mirror the reader default so the derived output filename matches the config in use.
  resolved_config_path = 'config/tgo_cases.yaml'
  if n_elements(config_path) gt 0 then begin
    if strtrim(config_path, 2) ne '' then resolved_config_path = strtrim(config_path, 2)
  endif
  resolved_config_path = file_expand_path(resolved_config_path)

  batch_output_filename = nsp_batch_output_filename_from_config_path(resolved_config_path)
  case_count = n_elements(case_ids)

  success_count = 0L
  failure_count = 0L
  succeeded_case_ids = strarr(case_count)
  failed_case_ids = strarr(case_count)
  output_paths = ['']
  row_strings = strarr(case_count)

  ; Decide the one batch-wide schema before generating any rows.
  include_any_keplerian = keyword_set(global_include_keplerian_elements)
  if ~include_any_keplerian then begin
    include_any_keplerian = total(long(include_keplerian_values gt 0L)) gt 0L
  endif

  ; The aggregate file has one fixed schema for the whole batch run.
  header_values = nsp_export_header_values($
    include_keplerian_columns=include_any_keplerian, $
    include_batch_status=1B)

  for i = 0L, case_count - 1L do begin
    case_identifier = case_ids[i]
    utc_value = utc_strings[i]
    include_keplerian_for_case = keyword_set(global_include_keplerian_elements) or (include_keplerian_values[i] eq 1L)

    print, 'Step 10 batch case start: case_id=' + case_identifier
    print, 'Step 10 batch case UTC=' + utc_value

    ; Validate UTC early so invalid timestamps produce a deterministic failure row.
    catch, error_status
    if error_status ne 0 then begin
      catch, /cancel
      error_message = 'Step 4 time handling failed: unable to convert UTC to ET for ' + utc_value
      failed_case_ids[failure_count] = case_identifier
      nsp_batch_failure_row_values, $
        case_identifier, utc_value, include_any_keplerian, error_message, $
        row_values=row_values
      row_strings[i] = nsp_export_join_row(row_values)
      failure_count = failure_count + 1L
      print, 'Step 10 batch case failed: case_id=' + case_identifier
      print, 'Failure reason=' + error_message
      continue
    endif
    et_probe = nsp_utc_to_et(utc_value)
    catch, /cancel

    ; Any later failure still produces one failed aggregate row rather than aborting the batch.
    catch, error_status
    if error_status ne 0 then begin
      error_message = !ERROR_STATE.MSG
      catch, /cancel
      failed_case_ids[failure_count] = case_identifier
      nsp_batch_failure_row_values, $
        case_identifier, utc_value, include_any_keplerian, error_message, $
        row_values=row_values
      row_strings[i] = nsp_export_join_row(row_values)
      failure_count = failure_count + 1L
      print, 'Step 10 batch case failed: case_id=' + case_identifier
      print, 'Failure reason=' + nsp_batch_safe_failure_message(error_message)
      continue
    endif

    nsp_build_export_row, $
      utc_string=utc_value, $
      case_id=case_identifier, $
      include_keplerian_elements=include_keplerian_for_case, $
      force_keplerian_columns=include_any_keplerian, $
      row_values=row_values
    catch, /cancel

    row_values = [row_values, 'success', 'none']
    row_strings[i] = nsp_export_join_row(row_values)
    succeeded_case_ids[success_count] = case_identifier
    success_count = success_count + 1L

    print, 'Step 10 batch case passed: case_id=' + case_identifier
  endfor

  ; Write the single aggregate artifact only after every row has been collected.
  nsp_write_csv_file, $
    header_values, row_strings, $
    default_filename=batch_output_filename, $
    output_path=batch_output_path
  output_paths[0] = batch_output_path

  if success_count gt 0L then begin
    succeeded_case_ids = succeeded_case_ids[0:success_count - 1L]
  endif else begin
    succeeded_case_ids = ['']
  endelse

  if failure_count gt 0L then begin
    failed_case_ids = failed_case_ids[0:failure_count - 1L]
  endif else begin
    failed_case_ids = ['']
  endelse

  print, 'Step 10 batch execution completed.'
  print, 'Batch successes=' + strtrim(success_count, 2)
  print, 'Batch failures=' + strtrim(failure_count, 2)
  print, 'Batch output=' + batch_output_path

  if success_count eq 0L then begin
    message, 'Step 10 batch execution failed: all configured batch cases failed.', /NONAME
  endif
end
