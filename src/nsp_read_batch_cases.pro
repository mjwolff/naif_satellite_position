function nsp_default_batch_config_path
  compile_opt strictarr

  return, file_expand_path('config/tgo_cases.yaml')
end


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


function nsp_batch_has_control_characters, text_value
  compile_opt strictarr

  return, (strpos(text_value, string(byte(9))) ge 0) or $
    (strpos(text_value, string(byte(10))) ge 0) or $
    (strpos(text_value, string(byte(13))) ge 0)
end


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


function nsp_batch_optional_boolean, case_definition, field_name, case_index
  compile_opt strictarr

  if ~case_definition.HasKey(field_name) then return, 0B

  value = case_definition[field_name]
  if ~isa(value, 'BOOLEAN', /SCALAR) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be true or false.', /NONAME
  endif

  return, value
end


function nsp_batch_required_positive_integer, case_definition, field_name, case_index
  compile_opt strictarr

  if ~case_definition.HasKey(field_name) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' is missing.', /NONAME
  endif

  value = case_definition[field_name]
  if (n_elements(value) ne 1) or (size(value, /N_DIMENSIONS) ne 0) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be a positive integer.', /NONAME
  endif

  if isa(value, 'BOOLEAN', /SCALAR) then begin
    message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' field ''' + field_name + ''' must be a positive integer.', /NONAME
  endif

  value_type = strupcase(size(value, /TNAME))
  valid_integer_type = 0B
  case value_type of
    'BYTE': valid_integer_type = 1B
    'INT': valid_integer_type = 1B
    'LONG': valid_integer_type = 1B
    'UINT': valid_integer_type = 1B
    'ULONG': valid_integer_type = 1B
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


pro nsp_read_batch_cases, config_path=config_path, case_ids=case_ids, utc_strings=utc_strings, include_keplerian_values=include_keplerian_values, output_filenames=output_filenames
  compile_opt strictarr

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

    if has_single_utc and has_any_range_field then begin
      message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' must define either ''utc'' or the range fields ''utc_start'', ''utc_end'', and ''dt_seconds'', but not both.', /NONAME
    endif

    if has_single_utc then begin
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

    dt_seconds_double = double(dt_seconds)
    step_count_double = (end_et - start_et) / dt_seconds_double
    rounded_step_count = round(step_count_double)
    reconstructed_end_et = start_et + (double(rounded_step_count) * dt_seconds_double)

    ; Allow a small ET tolerance so exact UTC wall-clock spans survive SPICE floating-point conversion.
    if abs(end_et - reconstructed_end_et) gt 1D-5 then begin
      message, 'Step 10 batch configuration failed: case ' + strtrim(case_index, 2) + ' UTC range span must be an exact multiple of ''dt_seconds''.', /NONAME
    endif

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

  case_ids = case_id_list.ToArray()
  utc_strings = utc_string_list.ToArray()
  include_keplerian_values = long(include_keplerian_list.ToArray())
  output_filenames = output_filename_list.ToArray()

  obj_destroy, case_id_list
  obj_destroy, utc_string_list
  obj_destroy, include_keplerian_list
  obj_destroy, output_filename_list

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

    if output_filenames[i] eq '' then begin
      output_filenames[i] = nsp_batch_output_filename_from_case_id(case_ids[i])
    endif
  endfor

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
