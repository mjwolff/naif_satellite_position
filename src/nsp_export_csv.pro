function nsp_export_base_header
  compile_opt strictarr

  return, ['case_id', 'utc', 'et', 'sc_x_km', 'sc_y_km', 'sc_z_km', 'sc_vx_km_s', 'sc_vy_km_s', 'sc_vz_km_s', 'sc_longitude_rad', 'sc_latitude_rad', 'sc_radius_km', 'sc_altitude_km', 'solar_zenith_angle_rad', 'occultation_valid', 'tangent_x_km', 'tangent_y_km', 'tangent_z_km', 'tangent_longitude_rad', 'tangent_latitude_rad', 'tangent_radius_km', 'tangent_altitude_km']
end


function nsp_export_keplerian_header
  compile_opt strictarr

  return, ['kep_rp_km', 'kep_eccentricity', 'kep_inclination_rad', 'kep_longitude_of_ascending_node_rad', 'kep_argument_of_periapsis_rad', 'kep_mean_anomaly_rad', 'kep_epoch_et', 'kep_mu_km3_s2']
end


function nsp_csv_value_string, value
  compile_opt strictarr

  if n_elements(value) eq 0 then return, 'NaN'

  if size(value, /TYPE) eq 7 then begin
    return, strtrim(string(value), 2)
  endif

  numeric_value = double(value)
  if finite(numeric_value) then begin
    return, strtrim(string(numeric_value, format='(E24.16)'), 2)
  endif

  return, 'NaN'
end


function nsp_export_join_row, values
  compile_opt strictarr

  return, strjoin(values, ',')
end


pro nsp_export_csv, utc_string=utc_string, case_id=case_id, output_filename=output_filename, output_path=output_path, include_keplerian_elements=include_keplerian_elements
  compile_opt strictarr

  if n_elements(utc_string) eq 0 then begin
    message, 'Step 9 export failed: utc_string was not provided.', /NONAME
  endif

  utc_value = strtrim(utc_string, 2)
  if utc_value eq '' then begin
    message, 'Step 9 export failed: utc_string is empty.', /NONAME
  endif

  case_identifier = 'single_case'
  if n_elements(case_id) gt 0 then begin
    if strtrim(case_id, 2) ne '' then case_identifier = strtrim(case_id, 2)
  endif

  export_filename = case_identifier + '.csv'
  if n_elements(output_filename) gt 0 then begin
    if strtrim(output_filename, 2) ne '' then export_filename = strtrim(output_filename, 2)
  endif

  if strpos(export_filename, '..') ge 0 then begin
    message, 'Step 9 export failed: output_filename must not contain "..": ' + export_filename, /NONAME
  endif

  if strpos(export_filename, '/') ge 0 then begin
    message, 'Step 9 export failed: output_filename must be a simple file name beneath outputs/: ' + export_filename, /NONAME
  endif

  if strmid(export_filename, 0, 1) eq '/' then begin
    message, 'Step 9 export failed: output_filename must not be an absolute path: ' + export_filename, /NONAME
  endif

  outputs_directory = file_expand_path('outputs')
  if ~file_test(outputs_directory, /DIRECTORY) then begin
    message, 'Step 9 export failed: required outputs directory was not found relative to the current working directory: ' + outputs_directory, /NONAME
  endif

  if ~file_test(outputs_directory, /WRITE) then begin
    message, 'Step 9 export failed: outputs directory is not writable: ' + outputs_directory, /NONAME
  endif

  output_path = outputs_directory + '/' + export_filename

  et_value = nsp_utc_to_et(utc_value)
  nsp_get_tgo_state, et_value, state_vector=state_vector, light_time=spacecraft_light_time
  nsp_compute_geometry_from_state, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, position_vector=position_vector
  nsp_get_sun_state, et_value, sun_state_vector=sun_state_vector, light_time=sun_light_time
  nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  nsp_compute_occultation_geometry, state_vector, spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance

  header_values = nsp_export_base_header()
  row_values = [case_identifier, utc_value, nsp_csv_value_string(et_value), nsp_csv_value_string(state_vector[0]), nsp_csv_value_string(state_vector[1]), nsp_csv_value_string(state_vector[2]), nsp_csv_value_string(state_vector[3]), nsp_csv_value_string(state_vector[4]), nsp_csv_value_string(state_vector[5]), nsp_csv_value_string(longitude), nsp_csv_value_string(latitude), nsp_csv_value_string(radius), nsp_csv_value_string(altitude), nsp_csv_value_string(solar_zenith_angle), strtrim(fix(occultation_valid), 2), nsp_csv_value_string(tangent_point_vector[0]), nsp_csv_value_string(tangent_point_vector[1]), nsp_csv_value_string(tangent_point_vector[2]), nsp_csv_value_string(tangent_longitude), nsp_csv_value_string(tangent_latitude), nsp_csv_value_string(tangent_radius), nsp_csv_value_string(tangent_altitude)]

  if keyword_set(include_keplerian_elements) then begin
    ; Keplerian elements are derived from a separate inertial J2000 state, not from the rotating IAU_MARS state.
    nsp_get_tgo_state_j2000, et_value, state_vector=inertial_state_vector, light_time=inertial_light_time
    nsp_compute_keplerian_elements, et_value, inertial_state_vector, keplerian_elements=keplerian_elements, mars_gm=mars_gm
    header_values = [header_values, nsp_export_keplerian_header()]
    row_values = [row_values, nsp_csv_value_string(keplerian_elements[0]), nsp_csv_value_string(keplerian_elements[1]), nsp_csv_value_string(keplerian_elements[2]), nsp_csv_value_string(keplerian_elements[3]), nsp_csv_value_string(keplerian_elements[4]), nsp_csv_value_string(keplerian_elements[5]), nsp_csv_value_string(keplerian_elements[6]), nsp_csv_value_string(mars_gm)]
  endif

  openw, lun, output_path, /get_lun
  printf, lun, nsp_export_join_row(header_values)
  printf, lun, nsp_export_join_row(row_values)
  free_lun, lun

  print, 'Step 9 export passed.'
  print, 'CSV output=' + output_path
  print, 'CSV columns=' + strtrim(n_elements(header_values), 2)
  print, 'Keplerian elements included=' + strtrim(fix(keyword_set(include_keplerian_elements)), 2)
end
