;+
; NAME:
;   NSP_EXPORT_BASE_HEADER
;
; PURPOSE:
;   Returns the 24-element string array of column names that form the
;   fixed base schema for every NSP output CSV file.
;   Called internally by NSP_EXPORT_HEADER_VALUES.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   result = NSP_EXPORT_BASE_HEADER()
;
; INPUTS:
;   None
;
; OUTPUTS:
;   STRING array[24]. Ordered column-name tokens.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_export_base_header
  compile_opt strictarr

  return, ['case_id', 'utc', 'et', 'sc_x_km', 'sc_y_km', 'sc_z_km', 'sc_vx_km_s', 'sc_vy_km_s', 'sc_vz_km_s', 'sc_longitude_rad', 'sc_latitude_rad', 'sc_radius_km', 'sc_altitude_km', 'solar_zenith_angle_rad', 'subsolar_latitude_rad', 'subsolar_longitude_rad', 'occultation_valid', 'tangent_x_km', 'tangent_y_km', 'tangent_z_km', 'tangent_longitude_rad', 'tangent_latitude_rad', 'tangent_radius_km', 'tangent_altitude_km']
end


;+
; NAME:
;   NSP_EXPORT_KEPLERIAN_HEADER
;
; PURPOSE:
;   Returns the 8-element string array of column names for the optional
;   Keplerian-element extension columns appended after the base schema.
;   Called internally by NSP_EXPORT_HEADER_VALUES.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   result = NSP_EXPORT_KEPLERIAN_HEADER()
;
; INPUTS:
;   None
;
; OUTPUTS:
;   STRING array[8]. Ordered Keplerian column-name tokens matching the
;   cspice_oscelt output order: rp, ecc, inc, lnode, argp, m0, t0, mu.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_export_keplerian_header
  compile_opt strictarr

  return, ['kep_rp_km', 'kep_eccentricity', 'kep_inclination_rad', 'kep_longitude_of_ascending_node_rad', 'kep_argument_of_periapsis_rad', 'kep_mean_anomaly_rad', 'kep_epoch_et', 'kep_mu_km3_s2']
end


;+
; NAME:
;   NSP_CSV_VALUE_STRING
;
; PURPOSE:
;   Converts a scalar value to its CSV field representation.
;   String values are trimmed and returned verbatim.  Numeric values are
;   formatted in 24-character E notation with 16 significant digits.
;   Non-finite (NaN, ±Inf) and undefined values are written as 'NaN'.
;   Called internally by NSP_BUILD_EXPORT_ROW.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   result = NSP_CSV_VALUE_STRING(value)
;
; INPUTS:
;   value - Any scalar. Strings are passed through; numerics are formatted.
;           Undefined or non-finite inputs produce 'NaN'.
;
; OUTPUTS:
;   STRING scalar. CSV-safe field text.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_csv_value_string, value
  compile_opt strictarr

  if n_elements(value) eq 0 then return, 'NaN'

  ; String type: trim whitespace and return as-is.
  if size(value, /TYPE) eq 7 then begin
    return, strtrim(string(value), 2)
  endif

  ; Numeric: use E notation with full double precision; non-finite → 'NaN'.
  numeric_value = double(value)
  if finite(numeric_value) then begin
    return, strtrim(string(numeric_value, format='(E24.16)'), 2)
  endif

  return, 'NaN'
end


;+
; NAME:
;   NSP_EXPORT_JOIN_ROW
;
; PURPOSE:
;   Joins a string array of CSV field values into a single comma-separated
;   row string suitable for writing directly to a CSV file.
;   Called internally by NSP_EXPORT_CSV, NSP_RUN_BATCH, and NSP_WRITE_CSV_FILE.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   result = NSP_EXPORT_JOIN_ROW(values)
;
; INPUTS:
;   values - STRING array. Field values to join.
;
; OUTPUTS:
;   STRING scalar. Comma-delimited row.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_export_join_row, values
  compile_opt strictarr

  return, strjoin(values, ',')
end


;+
; NAME:
;   NSP_EXPORT_NAN_VALUES
;
; PURPOSE:
;   Returns a string array of 'NaN' tokens of a specified length.  Used to
;   pad failure rows or absent optional column groups to the full schema width.
;   Called internally by NSP_BATCH_FAILURE_ROW_VALUES and NSP_BUILD_EXPORT_ROW.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   result = NSP_EXPORT_NAN_VALUES(value_count)
;
; INPUTS:
;   value_count - LONG scalar. Number of 'NaN' strings to produce.
;                 Returns a 1-element empty string array when value_count ≤ 0.
;
; OUTPUTS:
;   STRING array[value_count]. All elements set to 'NaN'.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_export_nan_values, value_count
  compile_opt strictarr

  if value_count le 0L then return, ['']

  values = strarr(value_count)
  values[*] = 'NaN'
  return, values
end


;+
; NAME:
;   NSP_EXPORT_OUTPUTS_DIRECTORY
;
; PURPOSE:
;   Returns the path to the outputs/ directory relative to the current
;   working directory.  If outputs/ does not exist or is not writable,
;   emits a WARNING to the console and falls back to the current
;   working directory so that the export can continue.
;   Called internally by NSP_EXPORT_RESOLVE_OUTPUT_PATH.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   result = NSP_EXPORT_OUTPUTS_DIRECTORY()
;
; INPUTS:
;   None
;
; OUTPUTS:
;   STRING scalar. Absolute path to the directory where CSV files will be written.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_export_outputs_directory
  compile_opt strictarr

  outputs_directory = file_expand_path('outputs')
  cwd = file_expand_path('.')

  if ~file_test(outputs_directory, /DIRECTORY) then begin
    print, 'WARNING: Step 9 export: outputs directory not found: ' + outputs_directory
    print, 'WARNING: Writing output to current directory instead: ' + cwd
    return, cwd
  endif

  if ~file_test(outputs_directory, /WRITE) then begin
    print, 'WARNING: Step 9 export: outputs directory is not writable: ' + outputs_directory
    print, 'WARNING: Writing output to current directory instead: ' + cwd
    return, cwd
  endif

  return, outputs_directory
end


;+
; NAME:
;   NSP_EXPORT_RESOLVE_OUTPUT_PATH
;
; PURPOSE:
;   Resolves the absolute output path for a CSV file by combining the
;   outputs directory with a validated filename.  Rejects filenames that
;   are empty, contain path traversal sequences ('..'), contain a
;   directory separator ('/'), or begin with '/'.
;   Called internally by NSP_WRITE_CSV_FILE.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   result = NSP_EXPORT_RESOLVE_OUTPUT_PATH(default_filename $
;              [, OUTPUT_FILENAME=output_filename])
;
; INPUTS:
;   default_filename - STRING. Fallback filename when OUTPUT_FILENAME is
;                      absent or empty.
;
; OPTIONAL KEYWORDS:
;   OUTPUT_FILENAME - STRING. Caller-supplied override filename.
;
; OUTPUTS:
;   STRING scalar. Absolute path to the target CSV file.
;   Raises an error if the resolved filename is invalid.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_export_resolve_output_path, default_filename, output_filename=output_filename
  compile_opt strictarr

  ; Prefer the caller-supplied name; fall back to the default.
  export_filename = strtrim(default_filename, 2)
  if n_elements(output_filename) gt 0 then begin
    if strtrim(output_filename, 2) ne '' then export_filename = strtrim(output_filename, 2)
  endif

  if export_filename eq '' then begin
    message, 'Step 9 export failed: output_filename resolved to an empty value.', /NONAME
  endif

  ; Reject path traversal sequences.
  if strpos(export_filename, '..') ge 0 then begin
    message, 'Step 9 export failed: output_filename must not contain "..": ' + export_filename, /NONAME
  endif

  ; Reject relative subdirectory paths; only bare filenames are accepted.
  if strpos(export_filename, '/') ge 0 then begin
    message, 'Step 9 export failed: output_filename must be a simple file name beneath outputs/: ' + export_filename, /NONAME
  endif

  ; Reject absolute paths.
  if strmid(export_filename, 0, 1) eq '/' then begin
    message, 'Step 9 export failed: output_filename must not be an absolute path: ' + export_filename, /NONAME
  endif

  return, nsp_export_outputs_directory() + '/' + export_filename
end


;+
; NAME:
;   NSP_EXPORT_HEADER_VALUES
;
; PURPOSE:
;   Assembles the full ordered column-name array for one CSV file schema.
;   Starts with the 24-element base header, optionally appends 8 Keplerian
;   columns, and optionally appends batch-status columns.
;   Called internally by NSP_EXPORT_CSV and NSP_RUN_BATCH.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   result = NSP_EXPORT_HEADER_VALUES( $
;              [/INCLUDE_KEPLERIAN_COLUMNS] $
;              [, /INCLUDE_BATCH_STATUS])
;
; OPTIONAL KEYWORDS:
;   INCLUDE_KEPLERIAN_COLUMNS - When set, appends the 8 Keplerian element columns.
;   INCLUDE_BATCH_STATUS      - When set, appends 'batch_status' and
;                               'failure_message' columns.
;
; OUTPUTS:
;   STRING array. Header tokens in column order.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_export_header_values, include_keplerian_columns=include_keplerian_columns, include_batch_status=include_batch_status
  compile_opt strictarr

  header_values = nsp_export_base_header()
  if keyword_set(include_keplerian_columns) then begin
    header_values = [header_values, nsp_export_keplerian_header()]
  endif

  if keyword_set(include_batch_status) then begin
    header_values = [header_values, ['batch_status', 'failure_message']]
  endif

  return, header_values
end


;+
; NAME:
;   NSP_BUILD_EXPORT_ROW
;
; PURPOSE:
;   Runs the full NSP computation chain for a single UTC epoch and assembles
;   the result into a string array matching the CSV row schema.  Calls Steps
;   4–11 in sequence: UTC→ET, TGO state, geometry, Sun state, solar geometry,
;   subsolar geometry, occultation geometry, output validation, and optionally
;   the J2000 state retrieval and Keplerian-element derivation.
;   Called internally by NSP_EXPORT_CSV and NSP_RUN_BATCH.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   NSP_BUILD_EXPORT_ROW, $
;     UTC_STRING=utc_string, $
;     [CASE_ID=case_id,] $
;     [/INCLUDE_KEPLERIAN_ELEMENTS,] $
;     [/FORCE_KEPLERIAN_COLUMNS,] $
;     ROW_VALUES=row_values
;
; OPTIONAL KEYWORDS:
;   UTC_STRING               - STRING scalar. UTC epoch for the row. Required.
;   CASE_ID                  - STRING scalar. Row identifier. Default: 'single_case'.
;   INCLUDE_KEPLERIAN_ELEMENTS - When set, computes and appends Keplerian elements.
;   FORCE_KEPLERIAN_COLUMNS  - When set without INCLUDE_KEPLERIAN_ELEMENTS, pads
;                              the Keplerian columns with 'NaN' to preserve schema
;                              alignment in a mixed batch.
;   ROW_VALUES               - Output. STRING array. One entry per CSV column.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_build_export_row, utc_string=utc_string, case_id=case_id, include_keplerian_elements=include_keplerian_elements, force_keplerian_columns=force_keplerian_columns, row_values=row_values
  compile_opt strictarr

  if n_elements(utc_string) eq 0 then begin
    message, 'Step 9 export failed: utc_string was not provided.', /NONAME
  endif

  utc_value = strtrim(utc_string, 2)
  if utc_value eq '' then begin
    message, 'Step 9 export failed: utc_string is empty.', /NONAME
  endif

  ; Default case identifier when no batch context is supplied.
  case_identifier = 'single_case'
  if n_elements(case_id) gt 0 then begin
    if strtrim(case_id, 2) ne '' then case_identifier = strtrim(case_id, 2)
  endif

  ; Steps 4–11: full computation chain for one epoch.
  et_value = nsp_utc_to_et(utc_value)
  nsp_get_tgo_state, et_value, state_vector=state_vector, light_time=spacecraft_light_time
  nsp_compute_geometry_from_state, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, position_vector=position_vector
  nsp_get_sun_state, et_value, sun_state_vector=sun_state_vector, light_time=sun_light_time
  nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  nsp_compute_geometry_from_position, sun_state_vector[0:2], longitude=subsolar_longitude, latitude=subsolar_latitude, radius=subsolar_radius, altitude=subsolar_altitude
  nsp_compute_occultation_geometry, state_vector, spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance
  nsp_validate_outputs, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude

  ; Assemble base-schema fields in column order.
  row_values = [case_identifier, utc_value, nsp_csv_value_string(et_value), nsp_csv_value_string(state_vector[0]), nsp_csv_value_string(state_vector[1]), nsp_csv_value_string(state_vector[2]), nsp_csv_value_string(state_vector[3]), nsp_csv_value_string(state_vector[4]), nsp_csv_value_string(state_vector[5]), nsp_csv_value_string(longitude), nsp_csv_value_string(latitude), nsp_csv_value_string(radius), nsp_csv_value_string(altitude), nsp_csv_value_string(solar_zenith_angle), nsp_csv_value_string(subsolar_latitude), nsp_csv_value_string(subsolar_longitude), strtrim(fix(occultation_valid), 2), nsp_csv_value_string(tangent_point_vector[0]), nsp_csv_value_string(tangent_point_vector[1]), nsp_csv_value_string(tangent_point_vector[2]), nsp_csv_value_string(tangent_longitude), nsp_csv_value_string(tangent_latitude), nsp_csv_value_string(tangent_radius), nsp_csv_value_string(tangent_altitude)]

  if keyword_set(include_keplerian_elements) then begin
    ; Keplerian elements require a J2000 inertial state, not the rotating IAU_MARS state.
    nsp_get_tgo_state_j2000, et_value, state_vector=inertial_state_vector, light_time=inertial_light_time
    nsp_compute_keplerian_elements, et_value, inertial_state_vector, keplerian_elements=keplerian_elements, mars_gm=mars_gm
    row_values = [row_values, nsp_csv_value_string(keplerian_elements[0]), nsp_csv_value_string(keplerian_elements[1]), nsp_csv_value_string(keplerian_elements[2]), nsp_csv_value_string(keplerian_elements[3]), nsp_csv_value_string(keplerian_elements[4]), nsp_csv_value_string(keplerian_elements[5]), nsp_csv_value_string(keplerian_elements[6]), nsp_csv_value_string(mars_gm)]
  endif else if keyword_set(force_keplerian_columns) then begin
    ; Pad with NaN to keep schema width consistent across a mixed batch.
    row_values = [row_values, nsp_export_nan_values(n_elements(nsp_export_keplerian_header()))]
  endif
end


;+
; NAME:
;   NSP_WRITE_CSV_FILE
;
; PURPOSE:
;   Writes a header row followed by one or more data rows to a CSV file
;   at the resolved output path.  Opens the file with OPENW, writes each
;   row with PRINTF, and frees the logical unit with FREE_LUN.
;   Called internally by NSP_EXPORT_CSV and NSP_RUN_BATCH.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   NSP_WRITE_CSV_FILE, header_values, row_strings, $
;     DEFAULT_FILENAME=default_filename $
;     [, OUTPUT_FILENAME=output_filename] $
;     [, OUTPUT_PATH=output_path]
;
; INPUTS:
;   header_values - STRING array. Column names for the header row.
;   row_strings   - STRING array. Pre-formatted comma-delimited data rows.
;
; OPTIONAL KEYWORDS:
;   DEFAULT_FILENAME - STRING. Fallback filename when OUTPUT_FILENAME is absent.
;   OUTPUT_FILENAME  - STRING. Caller-supplied override filename.
;   OUTPUT_PATH      - Output. STRING scalar. Absolute path of the written file.
;
; OUTPUTS:
;   OUTPUT_PATH keyword set on success.
;   Raises an error if header or row data are absent.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_write_csv_file, header_values, row_strings, default_filename=default_filename, output_filename=output_filename, output_path=output_path
  compile_opt strictarr

  if n_elements(header_values) eq 0 then begin
    message, 'Step 9 export failed: header_values were not provided for CSV writing.', /NONAME
  endif

  if n_elements(row_strings) eq 0 then begin
    message, 'Step 9 export failed: row_strings were not provided for CSV writing.', /NONAME
  endif

  output_path = nsp_export_resolve_output_path(default_filename, output_filename=output_filename)

  openw, lun, output_path, /get_lun
  printf, lun, nsp_export_join_row(header_values)

  for i = 0L, n_elements(row_strings) - 1L do begin
    printf, lun, row_strings[i]
  endfor

  free_lun, lun
end


;+
; NAME:
;   NSP_EXPORT_CSV
;
; PURPOSE:
;   Performs Step 9 of the NSP pipeline: runs the full computation chain for
;   a single UTC epoch, assembles the result into a one-row CSV file, and
;   prints an export summary.  Wraps NSP_BUILD_EXPORT_ROW and NSP_WRITE_CSV_FILE
;   for single-epoch interactive or programmatic use.
;
; CATEGORY:
;   NAIF Satellite Position / Export
;
; CALLING SEQUENCE:
;   NSP_EXPORT_CSV, UTC_STRING=utc_string $
;     [, CASE_ID=case_id] $
;     [, OUTPUT_FILENAME=output_filename] $
;     [, OUTPUT_PATH=output_path] $
;     [, /INCLUDE_KEPLERIAN_ELEMENTS]
;
; OPTIONAL KEYWORDS:
;   UTC_STRING               - STRING scalar. UTC epoch to evaluate. Required.
;   CASE_ID                  - STRING scalar. Row identifier written to
;                              the case_id column. Default: 'single_case'.
;   OUTPUT_FILENAME          - STRING. Bare filename for the output CSV.
;                              Default: '<case_id>.csv'.
;   OUTPUT_PATH              - Output. STRING scalar. Absolute path of the
;                              written CSV file.
;   INCLUDE_KEPLERIAN_ELEMENTS - When set, appends 8 Keplerian element columns.
;
; OUTPUTS:
;   OUTPUT_PATH keyword set on success.
;   Prints a summary line. Raises an error on any computation or I/O failure.
;
; EXAMPLE:
;   NSP_EXPORT_CSV, UTC_STRING='2025-01-01T00:00:00', OUTPUT_PATH=p
;   NSP_EXPORT_CSV, UTC_STRING='2025-01-01T00:00:00', /INCLUDE_KEPLERIAN_ELEMENTS
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_export_csv, utc_string=utc_string, case_id=case_id, output_filename=output_filename, output_path=output_path, include_keplerian_elements=include_keplerian_elements
  compile_opt strictarr

  case_identifier = 'single_case'
  if n_elements(case_id) gt 0 then begin
    if strtrim(case_id, 2) ne '' then case_identifier = strtrim(case_id, 2)
  endif

  default_filename = case_identifier + '.csv'
  header_values = nsp_export_header_values(include_keplerian_columns=keyword_set(include_keplerian_elements))
  nsp_build_export_row, utc_string=utc_string, case_id=case_identifier, include_keplerian_elements=include_keplerian_elements, force_keplerian_columns=keyword_set(include_keplerian_elements), row_values=row_values
  row_strings = [nsp_export_join_row(row_values)]
  nsp_write_csv_file, header_values, row_strings, default_filename=default_filename, output_filename=output_filename, output_path=output_path

  print, 'Step 9 export passed.'
  print, 'CSV output=' + output_path
  print, 'CSV columns=' + strtrim(n_elements(header_values), 2)
  print, 'Keplerian elements included=' + strtrim(fix(keyword_set(include_keplerian_elements)), 2)
end
