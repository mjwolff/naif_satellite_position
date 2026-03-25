; Return an empty occultation-event result structure.
;
; Calling sequence:
;   events = nsp_empty_occultation_events()
;
; Returns:
;   Structure array fields used for each extracted occultation event.
function nsp_empty_occultation_events
  compile_opt strictarr

  return, create_struct($
    'type', '', $
    'ingress', 0B, $
    'i_start', 0L, $
    'i_end', 0L, $
    't_start_interp', 0D, $
    't_end_interp', 0D, $
    't_start', 0D, $
    't_end', 0D, $
    'duration_interp', 0D, $
    'tang_alt_min', 0D, $
    'lat_min', 0D, $
    'lon_min', 0D, $
    'tang_alt_max', 0D, $
    'lat_max', 0D, $
    'lon_max', 0D)
end


; Linearly interpolate the ET of one tangent-altitude threshold crossing.
function nsp_interpolate_occultation_crossing_time, t0, a0, t1, a1, threshold
  compile_opt strictarr

  time0 = double(t0)
  time1 = double(t1)
  altitude0 = double(a0)
  altitude1 = double(a1)
  threshold_value = double(threshold)

  if (~finite(time0)) or (~finite(time1)) or (~finite(altitude0)) or (~finite(altitude1)) then begin
    message, 'Step 10 occultation-event extraction failed: interpolation inputs must be finite.', /NONAME
  endif

  if time1 eq time0 then begin
    message, 'Step 10 occultation-event extraction failed: interpolation times must be distinct.', /NONAME
  endif

  altitude_delta = altitude1 - altitude0
  if altitude_delta eq 0D then begin
    message, 'Step 10 occultation-event extraction failed: threshold interpolation requires distinct tangent altitudes.', /NONAME
  endif

  fraction = (threshold_value - altitude0) / altitude_delta
  if (fraction lt 0D) or (fraction gt 1D) then begin
    message, 'Step 10 occultation-event extraction failed: threshold is not bracketed by adjacent tangent altitudes.', /NONAME
  endif

  return, time0 + (fraction * (time1 - time0))
end


; Return the nearest previous index whose time and tangent altitude are both finite.
function nsp_previous_finite_occultation_index, time_values, altitude_values, start_index
  compile_opt strictarr

  for candidate_index = start_index - 1L, 0L, -1L do begin
    if finite(double(time_values[candidate_index])) and finite(double(altitude_values[candidate_index])) then begin
      return, candidate_index
    endif
  endfor

  message, 'Step 10 occultation-event extraction failed: no previous finite sample was available for event classification.', /NONAME
end


; Return the nearest later index whose time and tangent altitude are both finite.
function nsp_next_finite_occultation_index, time_values, altitude_values, start_index
  compile_opt strictarr

  last_index = n_elements(time_values) - 1L
  for candidate_index = start_index + 1L, last_index do begin
    if finite(double(time_values[candidate_index])) and finite(double(altitude_values[candidate_index])) then begin
      return, candidate_index
    endif
  endfor

  message, 'Step 10 occultation-event extraction failed: no later finite sample was available for event classification.', /NONAME
end


; Return the nearest previous finite sample that brackets a threshold crossing.
function nsp_previous_bracketing_occultation_index, time_values, altitude_values, start_index, threshold
  compile_opt strictarr

  current_altitude = double(altitude_values[start_index])
  threshold_value = double(threshold)
  if (~finite(current_altitude)) or (~finite(threshold_value)) then begin
    message, 'Step 10 occultation-event extraction failed: current altitude and threshold must be finite when searching for a previous bracket.', /NONAME
  endif

  for candidate_index = start_index - 1L, 0L, -1L do begin
    candidate_time = double(time_values[candidate_index])
    candidate_altitude = double(altitude_values[candidate_index])
    if ~finite(candidate_time) or ~finite(candidate_altitude) then continue
    if candidate_altitude eq current_altitude then continue
    if ((candidate_altitude - threshold_value) * (current_altitude - threshold_value)) le 0D then begin
      return, candidate_index
    endif
  endfor

  message, 'Step 10 occultation-event extraction failed: no previous bracketing sample was available for threshold interpolation.', /NONAME
end


; Return the nearest later finite sample that brackets a threshold crossing.
function nsp_next_bracketing_occultation_index, time_values, altitude_values, start_index, threshold
  compile_opt strictarr

  current_altitude = double(altitude_values[start_index])
  threshold_value = double(threshold)
  if (~finite(current_altitude)) or (~finite(threshold_value)) then begin
    message, 'Step 10 occultation-event extraction failed: current altitude and threshold must be finite when searching for a later bracket.', /NONAME
  endif

  last_index = n_elements(time_values) - 1L
  for candidate_index = start_index + 1L, last_index do begin
    candidate_time = double(time_values[candidate_index])
    candidate_altitude = double(altitude_values[candidate_index])
    if ~finite(candidate_time) or ~finite(candidate_altitude) then continue
    if candidate_altitude eq current_altitude then continue
    if ((candidate_altitude - threshold_value) * (current_altitude - threshold_value)) le 0D then begin
      return, candidate_index
    endif
  endfor

  message, 'Step 10 occultation-event extraction failed: no later bracketing sample was available for threshold interpolation.', /NONAME
end


; Extract survey arrays and occultation events from one aggregate batch CSV.
;
; Calling sequence:
;   nsp_extract_occultation_events, csv_path, survey=survey, [altitude_max_km=altitude_max_km], [event_count=event_count]
;
; Notes:
;   survey.n_int is mapped as a per-step 0/1 atmospheric-intersection flag from the
;   current CSV output: 1 when the row is successful, occultation_valid=1, and the
;   tangent altitude lies inside [0, altitude_max_km]. survey.ss_lat is returned as
;   the first finite sub-solar latitude sample from the CSV, which is the operational
;   scalar used for the current fixed-LsubS workflow.
pro nsp_extract_occultation_events, csv_path, survey=survey, altitude_max_km=altitude_max_km, event_count=event_count
  compile_opt strictarr

  if n_elements(csv_path) eq 0 then begin
    message, 'Step 10 occultation-event extraction failed: csv_path was not provided.', /NONAME
  endif

  altitude_limit = 150D
  if n_elements(altitude_max_km) gt 0 then altitude_limit = double(altitude_max_km)
  if (~finite(altitude_limit)) or (altitude_limit le 0D) then begin
    message, 'Step 10 occultation-event extraction failed: altitude_max_km must be finite and positive.', /NONAME
  endif

  resolve_routine, 'nsp_read_output_csv', /COMPILE_FULL_FILE
  nsp_read_output_csv, csv_path, csv_data=csv_data

  csv_tag_names = strlowcase(tag_names(csv_data))
  required_tags = ['et', 'occultation_valid', 'tangent_altitude_km', 'tangent_latitude_rad', 'tangent_longitude_rad', 'sc_latitude_rad', 'sc_longitude_rad', 'sc_altitude_km', 'subsolar_latitude_rad', 'subsolar_longitude_rad', 'batch_status']
  for tag_index = 0L, n_elements(required_tags) - 1L do begin
    if total(csv_tag_names eq required_tags[tag_index]) ne 1L then begin
      message, 'Step 10 occultation-event extraction failed: required batch CSV column was not found: ' + required_tags[tag_index], /NONAME
    endif
  endfor

  row_count = n_elements(csv_data.et)
  if n_elements(csv_data.occultation_valid) ne row_count then message, 'Step 10 occultation-event extraction failed: occultation_valid column length does not match et.', /NONAME
  if n_elements(csv_data.tangent_altitude_km) ne row_count then message, 'Step 10 occultation-event extraction failed: tangent_altitude_km column length does not match et.', /NONAME
  if n_elements(csv_data.tangent_latitude_rad) ne row_count then message, 'Step 10 occultation-event extraction failed: tangent_latitude_rad column length does not match et.', /NONAME
  if n_elements(csv_data.tangent_longitude_rad) ne row_count then message, 'Step 10 occultation-event extraction failed: tangent_longitude_rad column length does not match et.', /NONAME
  if n_elements(csv_data.sc_latitude_rad) ne row_count then message, 'Step 10 occultation-event extraction failed: sc_latitude_rad column length does not match et.', /NONAME
  if n_elements(csv_data.sc_longitude_rad) ne row_count then message, 'Step 10 occultation-event extraction failed: sc_longitude_rad column length does not match et.', /NONAME
  if n_elements(csv_data.sc_altitude_km) ne row_count then message, 'Step 10 occultation-event extraction failed: sc_altitude_km column length does not match et.', /NONAME
  if n_elements(csv_data.subsolar_latitude_rad) ne row_count then message, 'Step 10 occultation-event extraction failed: subsolar_latitude_rad column length does not match et.', /NONAME
  if n_elements(csv_data.subsolar_longitude_rad) ne row_count then message, 'Step 10 occultation-event extraction failed: subsolar_longitude_rad column length does not match et.', /NONAME
  if n_elements(csv_data.batch_status) ne row_count then message, 'Step 10 occultation-event extraction failed: batch_status column length does not match et.', /NONAME

  time_values = dblarr(row_count)
  tang_alt_values = dblarr(row_count)
  tang_lat_values = dblarr(row_count)
  tang_lon_values = dblarr(row_count)
  n_int_values = lonarr(row_count)
  sat_lat_values = dblarr(row_count)
  sat_lon_values = dblarr(row_count)
  sat_alt_values = dblarr(row_count)
  ss_lat_values = dblarr(row_count)
  ss_lon_values = dblarr(row_count)
  ss_lat_scalar = !values.d_nan

  if row_count eq 0L then begin
    survey = create_struct('time', time_values, 'tang_alt', tang_alt_values, 'tang_lat', tang_lat_values, 'tang_lon', tang_lon_values, 'n_int', n_int_values, 'sat_lat', sat_lat_values, 'sat_lon', sat_lon_values, 'sat_alt', sat_alt_values, 'ss_lat', ss_lat_scalar, 'ss_lon', ss_lon_values, 'n_ingress', 0L, 'n_egress', 0L, 'events', -1L)
    event_count = 0L
    return
  endif

  event_mask = bytarr(row_count)
  for row_index = 0L, row_count - 1L do begin
    time_values[row_index] = double(csv_data.et[row_index])
    tang_alt_values[row_index] = double(csv_data.tangent_altitude_km[row_index])
    tang_lat_values[row_index] = double(csv_data.tangent_latitude_rad[row_index]) * (180D / !dpi)
    tang_lon_values[row_index] = double(csv_data.tangent_longitude_rad[row_index]) * (180D / !dpi)
    sat_lat_values[row_index] = double(csv_data.sc_latitude_rad[row_index]) * (180D / !dpi)
    sat_lon_values[row_index] = double(csv_data.sc_longitude_rad[row_index]) * (180D / !dpi)
    sat_alt_values[row_index] = double(csv_data.sc_altitude_km[row_index])
    ss_lat_values[row_index] = double(csv_data.subsolar_latitude_rad[row_index]) * (180D / !dpi)
    ss_lon_values[row_index] = double(csv_data.subsolar_longitude_rad[row_index]) * (180D / !dpi)

    if ~finite(ss_lat_scalar) and finite(ss_lat_values[row_index]) then ss_lat_scalar = ss_lat_values[row_index]

    batch_status_value = strlowcase(strtrim(csv_data.batch_status[row_index], 2))
    if batch_status_value ne 'success' then continue

    occultation_flag = long(strtrim(csv_data.occultation_valid[row_index], 2))
    if occultation_flag ne 1L then continue

    if finite(tang_alt_values[row_index]) and (tang_alt_values[row_index] ge 0D) and (tang_alt_values[row_index] le altitude_limit) then begin
      event_mask[row_index] = 1B
      n_int_values[row_index] = 1L
    endif
  endfor

  if total(long(event_mask)) eq 0L then begin
    survey = create_struct('time', time_values, 'tang_alt', tang_alt_values, 'tang_lat', tang_lat_values, 'tang_lon', tang_lon_values, 'n_int', n_int_values, 'sat_lat', sat_lat_values, 'sat_lon', sat_lon_values, 'sat_alt', sat_alt_values, 'ss_lat', ss_lat_scalar, 'ss_lon', ss_lon_values, 'n_ingress', 0L, 'n_egress', 0L, 'events', -1L)
    event_count = 0L
    return
  endif

  event_template = nsp_empty_occultation_events()
  event_values = replicate(event_template, row_count)
  event_count = 0L

  segment_start = 0L
  while segment_start lt row_count do begin
    if event_mask[segment_start] eq 0B then begin
      segment_start = segment_start + 1L
      continue
    endif

    segment_end = segment_start
    while (segment_end + 1L lt row_count) and (event_mask[segment_end + 1L] eq 1B) do begin
      segment_end = segment_end + 1L
    endwhile

    trend_delta = tang_alt_values[segment_end] - tang_alt_values[segment_start]
    if (~finite(trend_delta)) or (trend_delta eq 0D) then begin
      previous_trend_index = nsp_previous_finite_occultation_index(time_values, tang_alt_values, segment_start)
      next_trend_index = nsp_next_finite_occultation_index(time_values, tang_alt_values, segment_end)
      trend_delta = tang_alt_values[next_trend_index] - tang_alt_values[previous_trend_index]
    endif
    if (~finite(trend_delta)) or (trend_delta eq 0D) then begin
      message, 'Step 10 occultation-event extraction failed: unable to classify event trend for rows ' + strtrim(segment_start, 2) + ' through ' + strtrim(segment_end, 2) + '.', /NONAME
    endif

    if trend_delta lt 0D then begin
      event_values[event_count].type = 'ING'
      event_values[event_count].ingress = 1B
      inside_start = where(tang_alt_values[segment_start:segment_end] lt altitude_limit, inside_start_count)
      if inside_start_count eq 0L then message, 'Step 10 occultation-event extraction failed: ingress event never crossed below altitude_max_km.', /NONAME
      i_start_value = segment_start + inside_start[0]

      inside_end = where(tang_alt_values[segment_start:segment_end] ge 0D, inside_end_count)
      if inside_end_count eq 0L then message, 'Step 10 occultation-event extraction failed: ingress event never remained at or above 0 km within the event window.', /NONAME
      i_end_value = segment_start + inside_end[inside_end_count - 1L]

      previous_index = nsp_previous_bracketing_occultation_index(time_values, tang_alt_values, i_start_value, altitude_limit)
      next_index = nsp_next_bracketing_occultation_index(time_values, tang_alt_values, i_end_value, 0D)

      t_start_interp_value = nsp_interpolate_occultation_crossing_time(time_values[previous_index], tang_alt_values[previous_index], time_values[i_start_value], tang_alt_values[i_start_value], altitude_limit)
      t_end_interp_value = nsp_interpolate_occultation_crossing_time(time_values[i_end_value], tang_alt_values[i_end_value], time_values[next_index], tang_alt_values[next_index], 0D)
    endif else begin
      event_values[event_count].type = 'EGR'
      event_values[event_count].ingress = 0B
      inside_start = where(tang_alt_values[segment_start:segment_end] ge 0D, inside_start_count)
      if inside_start_count eq 0L then message, 'Step 10 occultation-event extraction failed: egress event never crossed above 0 km.', /NONAME
      i_start_value = segment_start + inside_start[0]

      inside_end = where(tang_alt_values[segment_start:segment_end] lt altitude_limit, inside_end_count)
      if inside_end_count eq 0L then message, 'Step 10 occultation-event extraction failed: egress event never remained below altitude_max_km within the event window.', /NONAME
      i_end_value = segment_start + inside_end[inside_end_count - 1L]

      previous_index = nsp_previous_bracketing_occultation_index(time_values, tang_alt_values, i_start_value, 0D)
      next_index = nsp_next_bracketing_occultation_index(time_values, tang_alt_values, i_end_value, altitude_limit)

      t_start_interp_value = nsp_interpolate_occultation_crossing_time(time_values[previous_index], tang_alt_values[previous_index], time_values[i_start_value], tang_alt_values[i_start_value], 0D)
      t_end_interp_value = nsp_interpolate_occultation_crossing_time(time_values[i_end_value], tang_alt_values[i_end_value], time_values[next_index], tang_alt_values[next_index], altitude_limit)
    endelse

    if i_end_value lt i_start_value then begin
      message, 'Step 10 occultation-event extraction failed: event end index precedes the event start index.', /NONAME
    endif

    minimum_altitude_value = tang_alt_values[i_start_value]
    maximum_altitude_value = tang_alt_values[i_start_value]
    min_index = i_start_value
    max_index = i_start_value
    for window_index = i_start_value + 1L, i_end_value do begin
      if tang_alt_values[window_index] lt minimum_altitude_value then begin
        minimum_altitude_value = tang_alt_values[window_index]
        min_index = window_index
      endif
      if tang_alt_values[window_index] gt maximum_altitude_value then begin
        maximum_altitude_value = tang_alt_values[window_index]
        max_index = window_index
      endif
    endfor

    event_values[event_count].i_start = i_start_value
    event_values[event_count].i_end = i_end_value
    event_values[event_count].t_start_interp = t_start_interp_value
    event_values[event_count].t_end_interp = t_end_interp_value
    event_values[event_count].t_start = time_values[i_start_value]
    event_values[event_count].t_end = time_values[i_end_value]
    event_values[event_count].duration_interp = t_end_interp_value - t_start_interp_value
    event_values[event_count].tang_alt_min = minimum_altitude_value
    event_values[event_count].lat_min = tang_lat_values[min_index]
    event_values[event_count].lon_min = tang_lon_values[min_index]
    event_values[event_count].tang_alt_max = maximum_altitude_value
    event_values[event_count].lat_max = tang_lat_values[max_index]
    event_values[event_count].lon_max = tang_lon_values[max_index]
    event_count = event_count + 1L
    segment_start = segment_end + 1L
  endwhile

  n_ingress = long(total(long(event_values[0:event_count - 1L].ingress)))
  n_egress = long(event_count - n_ingress)
  survey_events = event_values[0:event_count - 1L]
  survey = create_struct('time', time_values, 'tang_alt', tang_alt_values, 'tang_lat', tang_lat_values, 'tang_lon', tang_lon_values, 'n_int', n_int_values, 'sat_lat', sat_lat_values, 'sat_lon', sat_lon_values, 'sat_alt', sat_alt_values, 'ss_lat', ss_lat_scalar, 'ss_lon', ss_lon_values, 'n_ingress', n_ingress, 'n_egress', n_egress, 'events', survey_events)
end
