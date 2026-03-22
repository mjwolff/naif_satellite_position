pro nsp_read_two_line_text_file, file_path, header_line=header_line, data_line=data_line
  compile_opt strictarr

  header_line = ''
  data_line = ''

  if ~file_test(file_path, /REGULAR) then begin
    message, 'Step 9 tests failed: expected export file was not found: ' + file_path, /NONAME
  endif

  openr, lun, file_path, /get_lun
  readf, lun, header_line, format='(A)'
  readf, lun, data_line, format='(A)'
  free_lun, lun
end


pro nsp_test_export_csv_base_success
  compile_opt strictarr

  utc_string = '2025-01-01T00:00:00'
  nsp_export_csv, utc_string=utc_string, case_id='step9_base', output_filename='step9_base.csv', output_path=output_path

  expected_header = 'case_id,utc,et,sc_x_km,sc_y_km,sc_z_km,sc_vx_km_s,sc_vy_km_s,sc_vz_km_s,sc_longitude_rad,sc_latitude_rad,sc_radius_km,sc_altitude_km,solar_zenith_angle_rad,occultation_valid,tangent_x_km,tangent_y_km,tangent_z_km,tangent_longitude_rad,tangent_latitude_rad,tangent_radius_km,tangent_altitude_km'
  nsp_read_two_line_text_file, output_path, header_line=header_line, data_line=data_line

  nsp_assert_true, header_line eq expected_header, 'Base export header did not match the documented fixed schema.'

  fields = strsplit(data_line, ',', /extract)
  nsp_assert_true, n_elements(fields) eq 22, 'Base export row did not contain the expected 22 columns.'
  nsp_assert_true, fields[0] eq 'step9_base', 'Base export case_id column is incorrect.'
  nsp_assert_true, fields[1] eq utc_string, 'Base export UTC column is incorrect.'
  nsp_assert_true, finite(double(fields[2])), 'Base export ET column is not finite.'
  nsp_assert_true, finite(double(fields[13])), 'Base export solar zenith angle column is not finite.'
  nsp_assert_true, (fields[14] eq '0') or (fields[14] eq '1'), 'Base export occultation_valid column is not an explicit 0/1 flag.'

  if fields[14] eq '1' then begin
    nsp_assert_true, finite(double(fields[20])), 'Occultation-valid base export should contain a finite tangent radius.'
    nsp_assert_true, finite(double(fields[21])), 'Occultation-valid base export should contain a finite tangent altitude.'
  endif else begin
    nsp_assert_true, strpos(strlowcase(fields[20]), 'nan') ge 0, 'Non-occultation base export should mark tangent radius explicitly as NaN.'
    nsp_assert_true, strpos(strlowcase(fields[21]), 'nan') ge 0, 'Non-occultation base export should mark tangent altitude explicitly as NaN.'
  endelse
end


pro nsp_test_export_csv_keplerian_success
  compile_opt strictarr

  utc_string = '2025-01-01T00:00:00'
  et_value = nsp_utc_to_et(utc_string)
  nsp_get_tgo_state_j2000, et_value, state_vector=inertial_state_vector, light_time=inertial_light_time
  nsp_compute_keplerian_elements, et_value, inertial_state_vector, keplerian_elements=keplerian_elements, mars_gm=mars_gm

  nsp_export_csv, utc_string=utc_string, case_id='step9_kep', output_filename='step9_kep.csv', output_path=output_path, /include_keplerian_elements

  expected_header = 'case_id,utc,et,sc_x_km,sc_y_km,sc_z_km,sc_vx_km_s,sc_vy_km_s,sc_vz_km_s,sc_longitude_rad,sc_latitude_rad,sc_radius_km,sc_altitude_km,solar_zenith_angle_rad,occultation_valid,tangent_x_km,tangent_y_km,tangent_z_km,tangent_longitude_rad,tangent_latitude_rad,tangent_radius_km,tangent_altitude_km,kep_rp_km,kep_eccentricity,kep_inclination_rad,kep_longitude_of_ascending_node_rad,kep_argument_of_periapsis_rad,kep_mean_anomaly_rad,kep_epoch_et,kep_mu_km3_s2'
  nsp_read_two_line_text_file, output_path, header_line=header_line, data_line=data_line

  nsp_assert_true, header_line eq expected_header, 'Keplerian export header did not match the documented fixed schema.'

  fields = strsplit(data_line, ',', /extract)
  nsp_assert_true, n_elements(fields) eq 30, 'Keplerian export row did not contain the expected 30 columns.'
  nsp_assert_true, fields[0] eq 'step9_kep', 'Keplerian export case_id column is incorrect.'

  for i = 0L, 7L do begin
    nsp_assert_close, double(fields[22 + i]), keplerian_elements[i], 1D-6, 'Keplerian export column does not match the direct helper element ' + strtrim(i, 2)
  endfor
  nsp_assert_close, double(fields[29]), mars_gm, 1D-6, 'Keplerian export Mars GM column does not match the helper value.'
end


pro nsp_test_export_csv
  compile_opt strictarr

  nsp_test_export_csv_base_success
  nsp_test_export_csv_keplerian_success

  print, 'Step 9 tests passed.'
  print, 'Validated fixed-schema CSV export, outputs directory writing, and optional Keplerian-element export.'
end
