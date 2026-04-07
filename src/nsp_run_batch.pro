;+
; NAME:
;   NSP_BATCH_OUTPUT_FILENAME_FROM_CONFIG_PATH
;
; PURPOSE:
;   Derives the aggregate batch CSV filename from the batch YAML config path.
;   Strips a trailing '.yaml' or '.yml' extension from the basename and
;   appends '.csv'.  For example, 'config/tgo_cases.yaml' → 'tgo_cases.csv'.
;   Called internally by NSP_RUN_BATCH.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_BATCH_OUTPUT_FILENAME_FROM_CONFIG_PATH(config_path)
;
; INPUTS:
;   config_path - STRING. Path to the batch YAML configuration file.
;
; OUTPUTS:
;   STRING scalar. Simple filename (no directory component) for the aggregate
;   batch CSV artifact.  Raises an error if the basename is empty after stripping.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_batch_output_filename_from_config_path, config_path
  compile_opt strictarr

  resolved_config_path = file_expand_path(strtrim(config_path, 2))
  config_basename = file_basename(resolved_config_path)
  basename_length = strlen(config_basename)

  ; Strip '.yaml' extension (case-insensitive).
  if basename_length gt 5 then begin
    if strlowcase(strmid(config_basename, basename_length - 5, 5)) eq '.yaml' then begin
      config_basename = strmid(config_basename, 0, basename_length - 5)
    endif
  endif

  ; Strip '.yml' extension (case-insensitive).
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


;+
; NAME:
;   NSP_BATCH_SAFE_FAILURE_MESSAGE
;
; PURPOSE:
;   Sanitises a raw IDL error message for safe inclusion as a single CSV
;   field value.  Joins multi-element arrays with a space, replaces
;   newline/carriage-return characters with spaces, and replaces commas
;   with semicolons.  Returns 'unknown_failure' for empty or undefined input.
;   Called internally by NSP_RUN_BATCH.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_BATCH_SAFE_FAILURE_MESSAGE(raw_message)
;
; INPUTS:
;   raw_message - STRING scalar or array. Error text from !ERROR_STATE.MSG.
;
; OUTPUTS:
;   STRING scalar. Sanitised single-line message safe for CSV embedding.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_batch_safe_failure_message, raw_message
  compile_opt strictarr

  if n_elements(raw_message) eq 0 then return, 'unknown_failure'

  ; Collapse array-valued messages into a single space-separated string.
  if n_elements(raw_message) gt 1 then begin
    safe_message = strjoin(strtrim(raw_message, 2), ' ')
  endif else begin
    safe_message = strtrim(raw_message, 2)
  endelse

  if safe_message eq '' then return, 'unknown_failure'

  linefeed = string(10B, format='(A1)')
  carriage_return = string(13B, format='(A1)')

  ; Replace control characters and commas character-by-character.
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


;+
; NAME:
;   NSP_BATCH_FAILURE_ROW_VALUES
;
; PURPOSE:
;   Assembles a failure row for the aggregate batch CSV.  Science columns
;   are filled with 'NaN' to preserve schema alignment; the batch_status
;   column is set to 'failed' and the failure_message column contains the
;   sanitised error text.
;   Called internally by NSP_RUN_BATCH.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   NSP_BATCH_FAILURE_ROW_VALUES, case_id, utc_string, $
;     include_keplerian_columns, failure_message, $
;     ROW_VALUES=row_values
;
; INPUTS:
;   case_id                   - STRING scalar. Case identifier for the failed row.
;   utc_string                - STRING scalar. UTC string associated with the case.
;   include_keplerian_columns - INT/BYTE. Nonzero when the aggregate schema
;                               includes Keplerian columns.
;   failure_message           - STRING scalar. Human-readable failure text.
;
; OUTPUTS:
;   ROW_VALUES - STRING array. One entry per aggregate CSV column.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_batch_failure_row_values, case_id, utc_string, include_keplerian_columns, failure_message, row_values=row_values
  compile_opt strictarr

  case_identifier = strtrim(case_id, 2)
  utc_value = strtrim(utc_string, 2)

  ; UTC-conversion failures already carry a deterministic message; pass through
  ; without further sanitisation to preserve the exact wording in the CSV.
  safe_failure_message = strtrim(failure_message, 2)
  if strpos(safe_failure_message, 'UTC to ET') lt 0 then begin
    safe_failure_message = nsp_batch_safe_failure_message(failure_message)
  endif

  ; Fill science fields with NaN; keep case_id and utc for traceability.
  base_nan_values = nsp_export_nan_values(n_elements(nsp_export_base_header()) - 2L)
  row_values = [case_identifier, utc_value, base_nan_values]

  if include_keplerian_columns then begin
    row_values = [row_values, nsp_export_nan_values(n_elements(nsp_export_keplerian_header()))]
  endif

  row_values = [row_values, 'failed', safe_failure_message]
end


;+
; NAME:
;   NSP_RUN_BATCH
;
; PURPOSE:
;   Performs Step 10 of the NSP pipeline: reads batch cases from a YAML
;   configuration file, runs the full computation chain for each case,
;   and writes a single aggregate CSV file containing one row per case.
;   Cases that fail are recorded with batch_status='failed' and NaN science
;   values rather than aborting the run.  The batch fails only when every
;   case fails.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   NSP_RUN_BATCH $
;     [, CONFIG_PATH=config_path] $
;     [, META_KERNEL_NAME=meta_kernel_name] $
;     [, ICY_DLM_PATH=icy_dlm_path] $
;     [, /DEBUG] $
;     [, /GLOBAL_INCLUDE_KEPLERIAN_ELEMENTS] $
;     [, SUCCESS_COUNT=success_count] $
;     [, FAILURE_COUNT=failure_count] $
;     [, SUCCEEDED_CASE_IDS=succeeded_case_ids] $
;     [, FAILED_CASE_IDS=failed_case_ids] $
;     [, OUTPUT_PATHS=output_paths]
;
; OPTIONAL KEYWORDS:
;   CONFIG_PATH                       - STRING. Path to the YAML batch config.
;                                       Default: 'config/tgo_cases.yaml'.
;   META_KERNEL_NAME                  - STRING. Override passed to NSP_RUN_PIPELINE.
;   ICY_DLM_PATH                      - STRING. Override passed to NSP_RUN_PIPELINE.
;   DEBUG                             - When set, passes /DEBUG to NSP_RUN_PIPELINE
;                                       to allow local KERNEL_PATH fallback.
;   GLOBAL_INCLUDE_KEPLERIAN_ELEMENTS - When set, forces Keplerian columns for
;                                       every row regardless of per-case settings.
;   SUCCESS_COUNT                     - Output. LONG scalar. Number of passed cases.
;   FAILURE_COUNT                     - Output. LONG scalar. Number of failed cases.
;   SUCCEEDED_CASE_IDS                - Output. STRING array. IDs of passed cases.
;   FAILED_CASE_IDS                   - Output. STRING array. IDs of failed cases.
;   OUTPUT_PATHS                      - Output. STRING array[1]. Absolute path to the
;                                       aggregate CSV file.
;
; OUTPUTS:
;   All keyword outputs set on completion. Prints per-case and summary progress
;   to the IDL console. Raises an error only when every case fails.
;
; EXAMPLE:
;   NSP_RUN_BATCH, CONFIG_PATH='config/tgo_cases.yaml', SUCCESS_COUNT=n
;   NSP_RUN_BATCH, /GLOBAL_INCLUDE_KEPLERIAN_ELEMENTS, OUTPUT_PATHS=p
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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

  ; Initialize the base pipeline before reading any batch cases.
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

  ; Decide the batch-wide schema once: Keplerian columns are included if any case
  ; requests them or the global override is set.
  include_any_keplerian = keyword_set(global_include_keplerian_elements)
  if ~include_any_keplerian then begin
    include_any_keplerian = total(long(include_keplerian_values gt 0L)) gt 0L
  endif

  ; The aggregate file uses one fixed schema for all rows (success and failure alike).
  header_values = nsp_export_header_values($
    include_keplerian_columns=include_any_keplerian, $
    include_batch_status=1B)

  for i = 0L, case_count - 1L do begin
    case_identifier = case_ids[i]
    utc_value = utc_strings[i]
    include_keplerian_for_case = keyword_set(global_include_keplerian_elements) or (include_keplerian_values[i] eq 1L)

    print, 'Step 10 batch case start: case_id=' + case_identifier
    print, 'Step 10 batch case UTC=' + utc_value

    ; Validate UTC early to produce a deterministic failure row for invalid timestamps.
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

    ; Any later failure still produces a failed aggregate row rather than aborting.
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

  ; Trim the case-ID arrays to the actual count; return empty string for zero counts.
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
