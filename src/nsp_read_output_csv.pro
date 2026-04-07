;+
; NAME:
;   NSP_READ_OUTPUT_CSV
;
; PURPOSE:
;   Reads one NSP output CSV file into an anonymous IDL structure whose
;   tags match the header column names and whose values are string arrays
;   containing one entry per data row.  Validates that the file exists,
;   that every data row has the same column count as the header, and that
;   at least one data row is present.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   NSP_READ_OUTPUT_CSV, csv_path, CSV_DATA=csv_data
;
; INPUTS:
;   csv_path - STRING scalar. Path to the NSP output CSV file to read.
;
; OUTPUTS:
;   CSV_DATA - Anonymous structure. One tag per header column; each tag
;              holds a STRING array[n_rows] containing the raw field text
;              for that column.  Numeric columns can be converted with
;              DOUBLE(csv_data.column_name).
;
; EXAMPLE:
;   NSP_READ_OUTPUT_CSV, 'outputs/single_case.csv', CSV_DATA=d
;   print, double(d.et)
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_read_output_csv, csv_path, csv_data=csv_data
  compile_opt strictarr

  if n_elements(csv_path) eq 0 then begin
    message, 'Step 9 CSV reader failed: csv_path was not provided.', /NONAME
  endif

  resolved_csv_path = file_expand_path(strtrim(csv_path, 2))
  if resolved_csv_path eq '' then begin
    message, 'Step 9 CSV reader failed: csv_path is empty.', /NONAME
  endif

  if ~file_test(resolved_csv_path, /REGULAR) then begin
    message, 'Step 9 CSV reader failed: expected CSV file was not found: ' + resolved_csv_path, /NONAME
  endif

  ; Read all lines into a List, then convert to a string array.
  line_values = List()
  openr, lun, resolved_csv_path, /get_lun

  while ~eof(lun) do begin
    line_value = ''
    readf, lun, line_value, format='(A)'
    line_values.Add, line_value
  endwhile

  free_lun, lun
  csv_lines = line_values.ToArray()
  obj_destroy, line_values

  if n_elements(csv_lines) lt 2 then begin
    message, 'Step 9 CSV reader failed: CSV file must contain one header row and at least one data row: ' + resolved_csv_path, /NONAME
  endif

  ; Parse header to determine the column schema.
  header_names = strsplit(csv_lines[0], ',', /extract)
  header_count = n_elements(header_names)
  if header_count eq 0 then begin
    message, 'Step 9 CSV reader failed: header row did not contain any columns: ' + resolved_csv_path, /NONAME
  endif

  ; Load all data rows into a [n_columns, n_rows] string table.
  row_count = n_elements(csv_lines) - 1L
  field_table = strarr(header_count, row_count)

  for row_index = 0L, row_count - 1L do begin
    row_fields = strsplit(csv_lines[row_index + 1L], ',', /extract)
    if n_elements(row_fields) ne header_count then begin
      message, 'Step 9 CSV reader failed: data row ' + strtrim(row_index + 2L, 2) + ' has ' + strtrim(n_elements(row_fields), 2) + ' columns but expected ' + strtrim(header_count, 2) + '.', /NONAME
    endif

    field_table[*, row_index] = row_fields
  endfor

  ; Build the output structure one column at a time.
  csv_data = create_struct(header_names[0], reform(field_table[0, *]))
  for column_index = 1L, header_count - 1L do begin
    csv_data = create_struct(csv_data, header_names[column_index], reform(field_table[column_index, *]))
  endfor
end
