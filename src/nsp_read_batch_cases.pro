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


function nsp_batch_python_script_path
  compile_opt strictarr

  return, file_expand_path('src/nsp_emit_batch_cases.py')
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

  python_script_path = nsp_batch_python_script_path()
  if ~file_test(python_script_path, /REGULAR) then begin
    message, 'Step 10 batch configuration failed: YAML parser helper was not found: ' + python_script_path, /NONAME
  endif

  command = 'python3 ' + python_script_path + ' ' + resolved_config_path
  spawn, command, result_lines, EXIT_STATUS=exit_status

  if exit_status ne 0 then begin
    failure_message = 'Step 10 batch configuration failed: unable to parse YAML batch cases.'
    if n_elements(result_lines) gt 0 then begin
      failure_message = failure_message + ' ' + strjoin(result_lines, ' ')
    endif
    message, failure_message, /NONAME
  endif

  if n_elements(result_lines) eq 0 then begin
    message, 'Step 10 batch configuration failed: configuration did not produce any batch cases: ' + resolved_config_path, /NONAME
  endif

  tab_character = string(byte(9))
  case_count = n_elements(result_lines)
  case_ids = strarr(case_count)
  utc_strings = strarr(case_count)
  include_keplerian_values = lonarr(case_count)
  output_filenames = strarr(case_count)

  for i = 0L, case_count - 1L do begin
    fields = strsplit(result_lines[i], tab_character, /extract)
    if n_elements(fields) eq 3 then begin
      line_length = strlen(result_lines[i])
      if (line_length gt 0L) and (strmid(result_lines[i], line_length - 1L, 1) eq tab_character) then begin
        fields = [fields, '']
      endif
    endif

    if n_elements(fields) ne 4 then begin
      message, 'Step 10 batch configuration failed: parser returned an invalid case definition row: ' + result_lines[i], /NONAME
    endif

    case_ids[i] = strtrim(fields[0], 2)
    utc_strings[i] = strtrim(fields[1], 2)
    include_keplerian_values[i] = long(strtrim(fields[2], 2))
    output_filenames[i] = strtrim(fields[3], 2)

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
