; Build one PNG path for a named Keplerian-relative-change panel.
;
; Calling sequence:
;   png_path = nsp_keplerian_plot_output_path(base_png_path, suffix)
function nsp_keplerian_plot_output_path, base_png_path, suffix
  compile_opt strictarr

  resolved_base_path = strtrim(base_png_path, 2)
  if resolved_base_path eq '' then begin
    message, 'Step 10 Keplerian plot failed: base_png_path is empty.', /NONAME
  endif

  if strmid(resolved_base_path, strlen(resolved_base_path) - 1L, 1) ne '/' then begin
    basename_length = strlen(resolved_base_path)
    if (basename_length lt 4L) or (strlowcase(strmid(resolved_base_path, basename_length - 4L, 4L)) ne '.png') then begin
      resolved_base_path = resolved_base_path + '/'
    endif
  endif

  resolved_base_path = file_expand_path(resolved_base_path)
  resolved_suffix = strtrim(suffix, 2)
  if resolved_suffix eq '' then begin
    message, 'Step 10 Keplerian plot failed: plot suffix is empty.', /NONAME
  endif

  basename = file_basename(resolved_base_path)
  directory_name = file_dirname(resolved_base_path)
  basename_length = strlen(basename)
  if basename_length gt 4 then begin
    if strlowcase(strmid(basename, basename_length - 4, 4)) eq '.png' then begin
      basename = strmid(basename, 0, basename_length - 4)
    endif
  endif

  return, directory_name + '/' + basename + '_' + resolved_suffix + '.png'
end


; Render one Keplerian relative-change panel to either the current device or a PNG file.
;
; Calling sequence:
;   nsp_render_keplerian_relative_plot, x_values, y_values, panel_title, line_color_index, [output_png_path=output_png_path], [use_x=use_x]
pro nsp_render_keplerian_relative_plot, x_values, y_values, panel_title, line_color_index, output_png_path=output_png_path, use_x=use_x
  compile_opt strictarr

  old_device = !d.name
  if n_elements(output_png_path) gt 0 then begin
    if strtrim(output_png_path, 2) eq '' then begin
      message, 'Step 10 Keplerian plot failed: output_png_path is empty.', /NONAME
    endif
    if keyword_set(use_x) then begin
      set_plot, 'x'
      window, /free, xsize=1600, ysize=1000
    endif else begin
      set_plot, 'z'
      device, set_resolution=[1600, 1000]
    endelse
  endif

  ; Reset to the standard grayscale table so the background/foreground indices are deterministic.
  loadct, 0, /silent

  plot, x_values, y_values, color=line_color_index, thick=3, background=255, title=panel_title, xtitle='Days since first sample', ytitle='Relative change', xstyle=1, ystyle=1, charsize=2.

  if n_elements(output_png_path) gt 0 then begin
    image = tvrd(/true)
    write_png, file_expand_path(strtrim(output_png_path, 2)), image
    if keyword_set(use_x) then begin
      wdelete
    endif else begin
      device, /close
    endelse
    set_plot, old_device
  endif
end


; Plot relative changes in the non-dynamic Keplerian elements from one batch CSV.
;
; Calling sequence:
;   nsp_plot_keplerian_relative_change, csv_path
;
; Inputs:
;   csv_path - aggregate batch CSV path that includes Keplerian export columns.
;
; Keywords:
;   TITLE            - optional plot-title prefix.
;   OUTPUT_PNG_PATH  - optional PNG base path for saved plotting. When set, the routine
;                      writes one PNG per element by appending a descriptive suffix.
;   USE_X            - when set together with OUTPUT_PNG_PATH, render each figure in an
;                      X window and capture it with TVRD(/TRUE) before writing the PNG.
;                      Otherwise the routine uses the Z device for headless rendering.
;
; Notes:
;   The non-dynamic elements are treated here as:
;     kep_rp_km
;     kep_eccentricity
;     kep_inclination_rad
;     kep_longitude_of_ascending_node_rad
;     kep_argument_of_periapsis_rad
;   Relative change is computed against the first successful sample. Angular elements
;   are unwrapped before differencing so 2*pi crossings do not introduce false jumps.
pro nsp_plot_keplerian_relative_change, csv_path, title=title, output_png_path=output_png_path, use_x=use_x
  compile_opt strictarr

  if n_elements(csv_path) eq 0 then begin
    message, 'Step 10 Keplerian plot failed: csv_path was not provided.', /NONAME
  endif

  resolve_routine, 'nsp_read_output_csv', /COMPILE_FULL_FILE
  nsp_read_output_csv, csv_path, csv_data=csv_data

  required_tags = ['et', 'batch_status', 'kep_rp_km', 'kep_eccentricity', 'kep_inclination_rad', 'kep_longitude_of_ascending_node_rad', 'kep_argument_of_periapsis_rad']
  csv_tag_names = strlowcase(tag_names(csv_data))
  for tag_index = 0L, n_elements(required_tags) - 1L do begin
    if total(csv_tag_names eq required_tags[tag_index]) ne 1L then begin
      message, 'Step 10 Keplerian plot failed: required CSV column was not found: ' + required_tags[tag_index], /NONAME
    endif
  endfor

  row_count = n_elements(csv_data.et)
  if row_count eq 0L then begin
    message, 'Step 10 Keplerian plot failed: CSV file does not contain any data rows.', /NONAME
  endif

  success_mask = bytarr(row_count)
  for i = 0L, row_count - 1L do begin
    if strlowcase(strtrim(csv_data.batch_status[i], 2)) eq 'success' then success_mask[i] = 1B
  endfor

  success_index = where(success_mask eq 1B, success_count)
  if success_count lt 2L then begin
    message, 'Step 10 Keplerian plot failed: need at least two successful rows with Keplerian elements.', /NONAME
  endif

  time_days = (double(csv_data.et[success_index]) - double(csv_data.et[success_index[0]])) / 86400D
  rp_values = double(csv_data.kep_rp_km[success_index])
  eccentricity_values = double(csv_data.kep_eccentricity[success_index])
  inclination_values = double(csv_data.kep_inclination_rad[success_index])
  node_values = double(csv_data.kep_longitude_of_ascending_node_rad[success_index])
  periapsis_values = double(csv_data.kep_argument_of_periapsis_rad[success_index])

  if (total(finite(rp_values)) ne success_count) or (total(finite(eccentricity_values)) ne success_count) or (total(finite(inclination_values)) ne success_count) or (total(finite(node_values)) ne success_count) or (total(finite(periapsis_values)) ne success_count) then begin
    message, 'Step 10 Keplerian plot failed: successful rows contain non-finite Keplerian values.', /NONAME
  endif

  node_unwrapped = node_values
  periapsis_unwrapped = periapsis_values
  for i = 1L, success_count - 1L do begin
    node_step = node_unwrapped[i] - node_unwrapped[i - 1L]
    if node_step gt !dpi then node_unwrapped[i:*] = node_unwrapped[i:*] - (2D * !dpi)
    if node_step lt (-1D * !dpi) then node_unwrapped[i:*] = node_unwrapped[i:*] + (2D * !dpi)

    periapsis_step = periapsis_unwrapped[i] - periapsis_unwrapped[i - 1L]
    if periapsis_step gt !dpi then periapsis_unwrapped[i:*] = periapsis_unwrapped[i:*] - (2D * !dpi)
    if periapsis_step lt (-1D * !dpi) then periapsis_unwrapped[i:*] = periapsis_unwrapped[i:*] + (2D * !dpi)
  endfor

  rp_reference = abs(rp_values[0])
  if rp_reference eq 0D then message, 'Step 10 Keplerian plot failed: kep_rp_km reference value is zero.', /NONAME

  eccentricity_reference = abs(eccentricity_values[0])
  if eccentricity_reference eq 0D then message, 'Step 10 Keplerian plot failed: kep_eccentricity reference value is zero.', /NONAME

  inclination_reference = abs(inclination_values[0])
  if inclination_reference eq 0D then message, 'Step 10 Keplerian plot failed: kep_inclination_rad reference value is zero.', /NONAME

  node_reference = abs(node_unwrapped[0])
  if node_reference eq 0D then message, 'Step 10 Keplerian plot failed: kep_longitude_of_ascending_node_rad reference value is zero.', /NONAME

  periapsis_reference = abs(periapsis_unwrapped[0])
  if periapsis_reference eq 0D then message, 'Step 10 Keplerian plot failed: kep_argument_of_periapsis_rad reference value is zero.', /NONAME

  rp_relative = (rp_values - rp_values[0]) / rp_reference
  eccentricity_relative = (eccentricity_values - eccentricity_values[0]) / eccentricity_reference
  inclination_relative = (inclination_values - inclination_values[0]) / inclination_reference
  node_relative = (node_unwrapped - node_unwrapped[0]) / node_reference
  periapsis_relative = (periapsis_unwrapped - periapsis_unwrapped[0]) / periapsis_reference

  plot_title_prefix = 'TGO Non-Dynamic Keplerian Relative Change'
  if n_elements(title) gt 0 then begin
    if strtrim(title, 2) ne '' then plot_title_prefix = strtrim(title, 2)
  endif

  if n_elements(output_png_path) gt 0 then begin
    nsp_render_keplerian_relative_plot, time_days, rp_relative, plot_title_prefix + ': kep_rp_km', 60, output_png_path=nsp_keplerian_plot_output_path(output_png_path, 'kep_rp_km'), use_x=use_x
    nsp_render_keplerian_relative_plot, time_days, eccentricity_relative, plot_title_prefix + ': kep_eccentricity', 61, output_png_path=nsp_keplerian_plot_output_path(output_png_path, 'kep_eccentricity'), use_x=use_x
    nsp_render_keplerian_relative_plot, time_days, inclination_relative, plot_title_prefix + ': kep_inclination_rad', 62, output_png_path=nsp_keplerian_plot_output_path(output_png_path, 'kep_inclination_rad'), use_x=use_x
    nsp_render_keplerian_relative_plot, time_days, node_relative, plot_title_prefix + ': kep_longitude_of_ascending_node_rad', 63, output_png_path=nsp_keplerian_plot_output_path(output_png_path, 'kep_longitude_of_ascending_node_rad'), use_x=use_x
    nsp_render_keplerian_relative_plot, time_days, periapsis_relative, plot_title_prefix + ': kep_argument_of_periapsis_rad', 64, output_png_path=nsp_keplerian_plot_output_path(output_png_path, 'kep_argument_of_periapsis_rad'), use_x=use_x
  endif else begin
    nsp_render_keplerian_relative_plot, time_days, rp_relative, plot_title_prefix + ': kep_rp_km', 60
    nsp_render_keplerian_relative_plot, time_days, eccentricity_relative, plot_title_prefix + ': kep_eccentricity', 61
    nsp_render_keplerian_relative_plot, time_days, inclination_relative, plot_title_prefix + ': kep_inclination_rad', 62
    nsp_render_keplerian_relative_plot, time_days, node_relative, plot_title_prefix + ': kep_longitude_of_ascending_node_rad', 63
    nsp_render_keplerian_relative_plot, time_days, periapsis_relative, plot_title_prefix + ': kep_argument_of_periapsis_rad', 64
  endelse

  print, 'Step 10 Keplerian plot passed.'
  print, 'Successful plotted rows=' + strtrim(success_count, 2)
  print, 'CSV input=' + file_expand_path(strtrim(csv_path, 2))
  if n_elements(output_png_path) gt 0 then begin
    if strtrim(output_png_path, 2) ne '' then print, 'Plot base output=' + file_expand_path(strtrim(output_png_path, 2))
  endif
end
