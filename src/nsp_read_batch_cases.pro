;+
; NAME:
;   NSP_DEFAULT_BATCH_CONFIG_PATH
;
; PURPOSE:
;   Returns the built-in default path to the YAML batch configuration file.
;   Called internally by NSP_READ_BATCH_CASES when no CONFIG_PATH is supplied.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_DEFAULT_BATCH_CONFIG_PATH()
;
; INPUTS:
;   None
;
; OUTPUTS:
;   STRING scalar. Absolute path to 'config/tgo_cases.yaml' relative to
;   the current working directory.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_default_batch_config_path
  compile_opt strictarr

  return, file_expand_path('config/tgo_cases.yaml')
end


;+
; NAME:
;   NSP_BATCH_OUTPUT_FILENAME_FROM_CASE_ID
;
; PURPOSE:
;   Derives a safe output CSV filename from a batch case identifier by
;   appending '.csv'.  Validates that the case_id is non-empty, does not
;   contain path-traversal sequences ('..'), directory separators ('/'),
;   or a leading dot ('.').
;   Called internally by NSP_READ_BATCH_CASES.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_BATCH_OUTPUT_FILENAME_FROM_CASE_ID(case_identifier)
;
; INPUTS:
;   case_identifier - STRING scalar. Validated batch case identifier.
;
; OUTPUTS:
;   STRING scalar. Simple filename (e.g. 'my_case.csv').
;   Raises an error if the identifier fails any safety check.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_batch_output_filename_from_case_id, case_identifier
  compile_opt strictarr

  trimmed_case_identifier = strtrim(case_identifier, 2)
  if trimmed_case_identifier eq '' then begin
    message, 'Step 10 batch configuration failed: case_id is empty.', /NONAME
  endif

  if strpos(trimmed_case_identifier, '..') ge 0 then begin
    message, 'Step 10 batch configuration failed: case_id must not contain "..": ' + trimmed_case_identifier, /NONAME
  endif

  if strpos(trimmed_case_identifier, '/') ge 0 then begin
    message, 'Step 10 batch configuration failed: case_id must not contain "/": ' + trimmed_case_identifier, /NONAME
  endif

  if strmid(trimmed_case_identifier, 0, 1) eq '.' then begin
    message, 'Step 10 batch configuration failed: case_id must not start with ".": ' + trimmed_case_identifier, /NONAME
  endif

  return, trimmed_case_identifier + '.csv'
end


;+
; NAME:
;   NSP_BATCH_HAS_CONTROL_CHARACTERS
;
; PURPOSE:
;   Returns 1 if the given string contains a horizontal-tab (ASCII 9),
;   linefeed (ASCII 10), or carriage-return (ASCII 13) character; 0 otherwise.
;   Used to reject YAML field values that would corrupt CSV output.
;   Called internally by NSP_BATCH_REQUIRED_STRING and NSP_BATCH_OPTIONAL_STRING.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_BATCH_HAS_CONTROL_CHARACTERS(text_value)
;
; INPUTS:
;   text_value - STRING scalar. Text to check.
;
; OUTPUTS:
;   BYTE scalar. 1 if control characters are present; 0 otherwise.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_batch_has_control_characters, text_value
  compile_opt strictarr

  return, (strpos(text_value, string(byte(9))) ge 0) or $
    (strpos(text_value, string(byte(10))) ge 0) or $
    (strpos(text_value, string(byte(13))) ge 0)
end


;+
; NAME:
;   NSP_BATCH_REQUIRED_STRING
;
; PURPOSE:
;   Extracts a required STRING field from a YAML_MAP case definition.
;   Raises a descriptive error if the field is absent, not a scalar string,
;   empty after trimming, or contains control characters.
;   Called internally by NSP_READ_BATCH_CASES.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_BATCH_REQUIRED_STRING(case_definition, field_name, case_index)
;
; INPUTS:
;   case_definition - YAML_MAP. One case entry from the 'cases' YAML list.
;   field_name      - STRING. Key to look up in the mapping.
;   case_index      - LONG. 1-based case index used in error messages.
;
; OUTPUTS:
;   STRING scalar. Trimmed, validated field value.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_batch_required_string, case_definition, field_name, case_index
  compile_opt strictarr

  if ~case_definition.HasKey(field_name) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' is missing.', /NONAME
  endif

  value = case_definition[field_name]
  if ~isa(value, 'STRING', /SCALAR) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be a string.', /NONAME
  endif

  text_value = strtrim(value, 2)
  if text_value eq '' then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' is empty.', /NONAME
  endif

  if nsp_batch_has_control_characters(text_value) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' contains unsupported control characters.', /NONAME
  endif

  return, text_value
end


;+
; NAME:
;   NSP_BATCH_OPTIONAL_STRING
;
; PURPOSE:
;   Extracts an optional STRING field from a YAML_MAP case definition.
;   Returns an empty string when the field is absent.  Raises a descriptive
;   error if the field is present but is not a scalar string or contains
;   control characters.
;   Called internally by NSP_READ_BATCH_CASES.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_BATCH_OPTIONAL_STRING(case_definition, field_name, case_index)
;
; INPUTS:
;   case_definition - YAML_MAP. One case entry from the 'cases' YAML list.
;   field_name      - STRING. Key to look up in the mapping.
;   case_index      - LONG. 1-based case index used in error messages.
;
; OUTPUTS:
;   STRING scalar. Trimmed field value, or empty string if absent.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_batch_optional_string, case_definition, field_name, case_index
  compile_opt strictarr

  if ~case_definition.HasKey(field_name) then return, ''

  value = case_definition[field_name]
  if ~isa(value, 'STRING', /SCALAR) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be a string when provided.', /NONAME
  endif

  text_value = strtrim(value, 2)
  if nsp_batch_has_control_characters(text_value) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' contains unsupported control characters.', /NONAME
  endif

  return, text_value
end


;+
; NAME:
;   NSP_BATCH_OPTIONAL_BOOLEAN
;
; PURPOSE:
;   Extracts an optional BOOLEAN field from a YAML_MAP case definition.
;   Returns 0B when the field is absent.  Raises a descriptive error if
;   the field is present but is not a scalar YAML boolean.
;   Called internally by NSP_READ_BATCH_CASES.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_BATCH_OPTIONAL_BOOLEAN(case_definition, field_name, case_index)
;
; INPUTS:
;   case_definition - YAML_MAP. One case entry from the 'cases' YAML list.
;   field_name      - STRING. Key to look up in the mapping.
;   case_index      - LONG. 1-based case index used in error messages.
;
; OUTPUTS:
;   BYTE scalar. The boolean field value, or 0B if absent.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_batch_optional_boolean, case_definition, field_name, case_index
  compile_opt strictarr

  if ~case_definition.HasKey(field_name) then return, 0B

  value = case_definition[field_name]
  if ~isa(value, 'BOOLEAN', /SCALAR) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be true or false.', /NONAME
  endif

  return, value
end


;+
; NAME:
;   NSP_BATCH_REQUIRED_POSITIVE_INTEGER
;
; PURPOSE:
;   Extracts a required positive-integer field from a YAML_MAP case
;   definition.  Validates that the field exists, is a scalar non-boolean
;   integer type, and is greater than zero.
;   Called internally by NSP_READ_BATCH_CASES for the 'dt_seconds' field.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_BATCH_REQUIRED_POSITIVE_INTEGER(case_definition, field_name, case_index)
;
; INPUTS:
;   case_definition - YAML_MAP. One case entry from the 'cases' YAML list.
;   field_name      - STRING. Key to look up in the mapping.
;   case_index      - LONG. 1-based case index used in error messages.
;
; OUTPUTS:
;   LONG64 scalar. Validated positive integer value.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_batch_required_positive_integer, case_definition, field_name, case_index
  compile_opt strictarr

  if ~case_definition.HasKey(field_name) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' is missing.', /NONAME
  endif

  value = case_definition[field_name]
  if (n_elements(value) ne 1) or (size(value, /N_DIMENSIONS) ne 0) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be a positive integer.', /NONAME
  endif

  ; Reject YAML booleans, which IDL parses as BYTE scalars.
  if isa(value, 'BOOLEAN', /SCALAR) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be a positive integer.', /NONAME
  endif

  ; Accept any integer type returned by the YAML parser.
  value_type = strupcase(size(value, /TNAME))
  valid_integer_type = 0B
  case value_type of
    'BYTE':   valid_integer_type = 1B
    'INT':    valid_integer_type = 1B
    'LONG':   valid_integer_type = 1B
    'UINT':   valid_integer_type = 1B
    'ULONG':  valid_integer_type = 1B
    'LONG64': valid_integer_type = 1B
    'ULONG64': valid_integer_type = 1B
    else:
  endcase

  if ~keyword_set(valid_integer_type) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be a positive integer.', /NONAME
  endif

  integer_value = long64(value)
  if integer_value le 0LL then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be greater than zero.', /NONAME
  endif

  return, integer_value
end


;+
; NAME:
;   NSP_BATCH_UTC_SUFFIX
;
; PURPOSE:
;   Derives a compact, filesystem-safe timestamp suffix from an ISO 8601 UTC
;   string for use in auto-generated case IDs during range expansion.
;   For example, '2025-01-15T06:30:00' → '2025_01_15_063000'.
;   Called internally by NSP_READ_BATCH_CASES.
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   result = NSP_BATCH_UTC_SUFFIX(utc_string)
;
; INPUTS:
;   utc_string - STRING scalar. ISO 8601 UTC string with at least 19 characters.
;
; OUTPUTS:
;   STRING scalar. Compact timestamp suffix with date components separated by
;   underscores and time components concatenated.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_batch_utc_suffix, utc_string
  compile_opt strictarr

  if strlen(utc_string) lt 19 then begin
    message, 'Step 10 batch configuration failed: unable to derive a case-id suffix from UTC string: ' + utc_string, /NONAME
  endif

  date_fields = strsplit(strmid(utc_string, 0, 10), '-', /extract)
  time_fields = strsplit(strmid(utc_string, 11, 8), ':', /extract)

  if (n_elements(date_fields) ne 3) or (n_elements(time_fields) ne 3) then begin
    message, 'Step 10 batch configuration failed: unable to derive a case-id suffix from UTC string: ' + utc_string, /NONAME
  endif

  return, date_fields[0] + '_' + date_fields[1] + '_' + date_fields[2] + '_' + time_fields[0] + time_fields[1] + time_fields[2]
end


;+
; NAME:
;   NSP_READ_BATCH_CASES
;
; PURPOSE:
;   Parses a YAML batch configuration file and expands it into parallel
;   arrays of case identifiers, UTC strings, Keplerian-element flags, and
;   output filenames.  Supports two case forms:
;     - Single-point: 'case_id' + 'utc'
;     - Range: 'case_id' + 'utc_start' + 'utc_end' + 'dt_seconds'
;       (the range span must be an exact multiple of dt_seconds)
;   Validates all field types, rejects mixing of single-point and range fields
;   within one case, enforces uniqueness of case_id and output_filename across
;   all expanded cases, and destroys YAML objects on completion.
;   Called internally by NSP_RUN_BATCH (Step 10).
;
; CATEGORY:
;   NAIF Satellite Position / Batch
;
; CALLING SEQUENCE:
;   NSP_READ_BATCH_CASES $
;     [, CONFIG_PATH=config_path] $
;     [, CASE_IDS=case_ids] $
;     [, UTC_STRINGS=utc_strings] $
;     [, INCLUDE_KEPLERIAN_VALUES=include_keplerian_values] $
;     [, OUTPUT_FILENAMES=output_filenames]
;
; OPTIONAL KEYWORDS:
;   CONFIG_PATH               - STRING. Path to the YAML config file.
;                               Default: 'config/tgo_cases.yaml'.
;   CASE_IDS                  - Output. STRING array. Expanded case identifiers.
;   UTC_STRINGS               - Output. STRING array. One UTC string per case.
;   INCLUDE_KEPLERIAN_VALUES  - Output. LONG array. 1 if Keplerian elements are
;                               requested for the case, 0 otherwise.
;   OUTPUT_FILENAMES          - Output. STRING array. CSV filename per case.
;
; OUTPUTS:
;   All keyword arrays set on success, parallel and of equal length.
;   Raises an error on any configuration or validation failure.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_read_batch_cases, config_path=config_path, case_ids=case_ids, utc_strings=utc_strings, include_keplerian_values=include_keplerian_values, output_filenames=output_filenames
  compile_opt strictarr

  ; Resolve the config path: keyword overrides the built-in default.
  resolved_config_path = nsp_default_batch_config_path()
  if n_elements(config_path) gt 0 then begin
    if strtrim(config_path, 2) ne '' then resolved_config_path = file_expand_path(strtrim(config_path, 2))
  endif

  if ~file_test(resolved_config_path, /REGULAR) then begin
    message, 'Step 10 batch configuration failed: configuration file was not found: ' + resolved_config_path, /NONAME
  endif

  if ~file_test(resolved_config_path, /READ) then begin
    message, 'Step 10 batch configuration failed: configuration file is not readable: ' + resolved_config_path, /NONAME
  endif

  ; Parse YAML, propagating any parse error with a Step 10 prefix.
  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    message, 'Step 10 batch configuration failed: unable to parse YAML batch cases. ' + error_message, /NONAME
  endif
  config_data = yaml_parse(resolved_config_path)
  catch, /cancel

  if ~obj_isa(config_data, 'YAML_MAP') then begin
    message, 'Step 10 batch configuration failed: top-level YAML document must be a mapping.', /NONAME
  endif

  if ~config_data.HasKey('cases') then begin
    message, 'Step 10 batch configuration failed: top-level ''cases'' must be a non-empty list.', /NONAME
  endif

  cases = config_data['cases']
  if ~obj_isa(cases, 'YAML_SEQUENCE') then begin
    message, 'Step 10 batch configuration failed: top-level ''cases'' must be a non-empty list.', /NONAME
  endif

  if cases.Count() eq 0 then begin
    message, 'Step 10 batch configuration failed: top-level ''cases'' must be a non-empty list.', /NONAME
  endif

  ; Accumulate expanded cases into IDL Lists before converting to arrays.
  case_id_list = List()
  utc_string_list = List()
  include_keplerian_list = List()
  output_filename_list = List()

  for i = 0L, cases.Count() - 1L do begin
    case_index = i + 1L
    case_definition = cases[i]

    if ~obj_isa(case_definition, 'YAML_MAP') then begin
      message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' must be a mapping.', /NONAME
    endif

    case_id = nsp_batch_required_string(case_definition, 'case_id', case_index)
    include_keplerian = nsp_batch_optional_boolean(case_definition, 'include_keplerian_elements', case_index)
    output_filename = nsp_batch_optional_string(case_definition, 'output_filename', case_index)

    has_single_utc = case_definition.HasKey('utc')
    has_any_range_field = case_definition.HasKey('utc_start') or case_definition.HasKey('utc_end') or case_definition.HasKey('dt_seconds')

    ; Reject mixed single-point and range fields in the same case.
    if has_single_utc and has_any_range_field then begin
      message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' must define either ''utc'' or the range fields ''utc_start'', ''utc_end'', and ''dt_seconds'', but not both.', /NONAME
    endif

    if has_single_utc then begin
      ; Single-point case: add exactly one row.
      utc_value = nsp_batch_required_string(case_definition, 'utc', case_index)
      effective_output_filename = output_filename
      if effective_output_filename eq '' then begin
        effective_output_filename = nsp_batch_output_filename_from_case_id(case_id)
      endif

      case_id_list.Add, case_id
      utc_string_list.Add, utc_value
      include_keplerian_list.Add, long(keyword_set(include_keplerian))
      output_filename_list.Add, effective_output_filename
      continue
    endif

    if ~has_any_range_field then begin
      message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' must define either ''utc'' or the range fields ''utc_start'', ''utc_end'', and ''dt_seconds''.', /NONAME
    endif

    ; Range case: expand into one row per time step.
    utc_start_text = nsp_batch_required_string(case_definition, 'utc_start', case_index)
    utc_end_text = nsp_batch_required_string(case_definition, 'utc_end', case_index)
    dt_seconds = nsp_batch_required_positive_integer(case_definition, 'dt_seconds', case_index)

    if output_filename ne '' then begin
      message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' range definitions must not set ''output_filename''; filenames are generated from the expanded timestamps.', /NONAME
    endif

    start_et = nsp_utc_to_et(utc_start_text)
    end_et = nsp_utc_to_et(utc_end_text)

    if end_et lt start_et then begin
      message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''utc_end'' must not be earlier than ''utc_start''.', /NONAME
    endif

    ; Verify the span is an exact multiple of dt_seconds (within a small ET tolerance
    ; to absorb SPICE floating-point rounding on exact wall-clock boundaries).
    dt_seconds_double = double(dt_seconds)
    step_count_double = (end_et - start_et) / dt_seconds_double
    rounded_step_count = round(step_count_double)
    reconstructed_end_et = start_et + (double(rounded_step_count) * dt_seconds_double)

    if abs(end_et - reconstructed_end_et) gt 1D-5 then begin
      message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' UTC range span must be an exact multiple of ''dt_seconds''.', /NONAME
    endif

    ; Expand into individual time steps.
    for step_index = 0L, long(rounded_step_count) do begin
      current_et = start_et + (double(step_index) * dt_seconds_double)
      cspice_et2utc, current_et, 'ISOC', 0L, expanded_utc
      expanded_case_id = case_id + '_' + nsp_batch_utc_suffix(expanded_utc)
      effective_output_filename = nsp_batch_output_filename_from_case_id(expanded_case_id)

      case_id_list.Add, expanded_case_id
      utc_string_list.Add, expanded_utc
      include_keplerian_list.Add, long(keyword_set(include_keplerian))
      output_filename_list.Add, effective_output_filename
    endfor
  endfor

  if case_id_list.Count() eq 0 then begin
    message, 'Step 10 batch configuration failed: configuration did not produce any batch cases: ' + resolved_config_path, /NONAME
  endif

  ; Convert Lists to arrays and release YAML-allocated objects.
  case_ids = case_id_list.ToArray()
  utc_strings = utc_string_list.ToArray()
  include_keplerian_values = long(include_keplerian_list.ToArray())
  output_filenames = output_filename_list.ToArray()

  obj_destroy, case_id_list
  obj_destroy, utc_string_list
  obj_destroy, include_keplerian_list
  obj_destroy, output_filename_list

  ; Post-expansion consistency checks.
  case_count = n_elements(case_ids)
  for i = 0L, case_count - 1L do begin
    if case_ids[i] eq '' then begin
      message, 'Step 10 batch configuration failed: case_id is empty in batch configuration row ' + strtrim(i + 1L, 2), /NONAME
    endif

    if utc_strings[i] eq '' then begin
      message, 'Step 10 batch configuration failed: utc is empty for case_id=' + case_ids[i], /NONAME
    endif

    if (include_keplerian_values[i] ne 0L) and (include_keplerian_values[i] ne 1L) then begin
      message, 'Step 10 batch configuration failed: include_keplerian_elements must be 0 or 1 for case_id=' + case_ids[i], /NONAME
    endif

    ; Derive a filename for any row that still has an empty output_filename.
    if output_filenames[i] eq '' then begin
      output_filenames[i] = nsp_batch_output_filename_from_case_id(case_ids[i])
    endif
  endfor

  ; Enforce uniqueness of case_id and output_filename across all expanded rows.
  for i = 0L, case_count - 1L do begin
    for j = i + 1L, case_count - 1L do begin
      if case_ids[i] eq case_ids[j] then begin
        message, 'Step 10 batch configuration failed: duplicate case_id found in batch configuration: ' + case_ids[i], /NONAME
      endif

      if output_filenames[i] eq output_filenames[j] then begin
        message, 'Step 10 batch configuration failed: duplicate output_filename found in batch configuration: ' + output_filenames[i], /NONAME
      endif
    endfor
  endfor
end
