;+
; NAME:
;   NSP_EMPTY_OCCULTATION_EVENTS
;
; PURPOSE:
;   Returns a scalar structure with the default field layout for one
;   extracted occultation event.  Used as the template for REPLICATE when
;   allocating the event array in NSP_EXTRACT_OCCULTATION_EVENTS.
;
; CATEGORY:
;   NAIF Satellite Position / Occultation Events
;
; CALLING SEQUENCE:
;   result = NSP_EMPTY_OCCULTATION_EVENTS()
;
; INPUTS:
;   None
;
; OUTPUTS:
;   Anonymous structure with the following fields:
;     type           - STRING.  'ING' (ingress) or 'EGR' (egress).
;     ingress        - BYTE.    1 for ingress, 0 for egress.
;     i_start        - LONG.    First CSV row index inside the event window.
;     i_end          - LONG.    Last CSV row index inside the event window.
;     t_start_interp - DOUBLE.  Interpolated ET of the event start threshold crossing.
;     t_end_interp   - DOUBLE.  Interpolated ET of the event end threshold crossing.
;     t_start        - DOUBLE.  ET of the first sampled row inside the window.
;     t_end          - DOUBLE.  ET of the last sampled row inside the window.
;     duration_interp - DOUBLE. t_end_interp - t_start_interp (seconds).
;     tang_alt_min   - DOUBLE.  Minimum tangent altitude inside the window (km).
;     lat_min        - DOUBLE.  Latitude at the minimum altitude (degrees).
;     lon_min        - DOUBLE.  Longitude at the minimum altitude (degrees).
;     tang_alt_max   - DOUBLE.  Maximum tangent altitude inside the window (km).
;     lat_max        - DOUBLE.  Latitude at the maximum altitude (degrees).
;     lon_max        - DOUBLE.  Longitude at the maximum altitude (degrees).
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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


;+
; NAME:
;   NSP_INTERPOLATE_OCCULTATION_CROSSING_TIME
;
; PURPOSE:
;   Linearly interpolates the ET at which the tangent altitude crosses a
;   given threshold between two adjacent bracketing samples.
;   Called internally by NSP_EXTRACT_OCCULTATION_EVENTS.
;
; CATEGORY:
;   NAIF Satellite Position / Occultation Events
;
; CALLING SEQUENCE:
;   result = NSP_INTERPOLATE_OCCULTATION_CROSSING_TIME(t0, a0, t1, a1, threshold)
;
; INPUTS:
;   t0        - DOUBLE scalar. ET of the sample before the crossing (seconds past J2000).
;   a0        - DOUBLE scalar. Tangent altitude at t0 (km).
;   t1        - DOUBLE scalar. ET of the sample after the crossing.
;   a1        - DOUBLE scalar. Tangent altitude at t1 (km).
;   threshold - DOUBLE scalar. Target altitude to interpolate (km).
;
; OUTPUTS:
;   DOUBLE scalar. Interpolated ET of the threshold crossing.
;   Raises an error if inputs are non-finite, times are identical, altitudes
;   are identical, or the threshold is not bracketed by [a0, a1].
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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

  ; Linear interpolation: fraction ∈ [0, 1] along the segment.
  fraction = (threshold_value - altitude0) / altitude_delta
  if (fraction lt 0D) or (fraction gt 1D) then begin
    message, 'Step 10 occultation-event extraction failed: threshold is not bracketed by adjacent tangent altitudes.', /NONAME
  endif

  return, time0 + (fraction * (time1 - time0))
end


;+
; NAME:
;   NSP_PREVIOUS_FINITE_OCCULTATION_INDEX
;
; PURPOSE:
;   Searches backwards from start_index for the nearest earlier index at
;   which both the time and tangent altitude are finite.
;   Called internally by NSP_EXTRACT_OCCULTATION_EVENTS for trend classification.
;
; CATEGORY:
;   NAIF Satellite Position / Occultation Events
;
; CALLING SEQUENCE:
;   result = NSP_PREVIOUS_FINITE_OCCULTATION_INDEX(time_values, altitude_values, start_index)
;
; INPUTS:
;   time_values     - DOUBLE array. ET values for each CSV row.
;   altitude_values - DOUBLE array. Tangent altitude for each row (km); may contain NaN.
;   start_index     - LONG scalar. Index from which the backward search begins (exclusive).
;
; OUTPUTS:
;   LONG scalar. Index of the nearest previous finite sample.
;   Raises an error if no finite sample exists before start_index.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_previous_finite_occultation_index, time_values, altitude_values, start_index
  compile_opt strictarr

  for candidate_index = start_index - 1L, 0L, -1L do begin
    if finite(double(time_values[candidate_index])) and finite(double(altitude_values[candidate_index])) then begin
      return, candidate_index
    endif
  endfor

  message, 'Step 10 occultation-event extraction failed: no previous finite sample was available for event classification.', /NONAME
end


;+
; NAME:
;   NSP_NEXT_FINITE_OCCULTATION_INDEX
;
; PURPOSE:
;   Searches forwards from start_index for the nearest later index at which
;   both the time and tangent altitude are finite.
;   Called internally by NSP_EXTRACT_OCCULTATION_EVENTS for trend classification.
;
; CATEGORY:
;   NAIF Satellite Position / Occultation Events
;
; CALLING SEQUENCE:
;   result = NSP_NEXT_FINITE_OCCULTATION_INDEX(time_values, altitude_values, start_index)
;
; INPUTS:
;   time_values     - DOUBLE array. ET values for each CSV row.
;   altitude_values - DOUBLE array. Tangent altitude for each row (km); may contain NaN.
;   start_index     - LONG scalar. Index from which the forward search begins (exclusive).
;
; OUTPUTS:
;   LONG scalar. Index of the nearest following finite sample.
;   Raises an error if no finite sample exists after start_index.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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


;+
; NAME:
;   NSP_PREVIOUS_BRACKETING_OCCULTATION_INDEX
;
; PURPOSE:
;   Searches backwards from start_index for the nearest earlier finite sample
;   that brackets a threshold crossing with the sample at start_index.
;   Used to find the sample just before a tangent altitude crosses a boundary
;   so the crossing time can be interpolated.
;   Called internally by NSP_EXTRACT_OCCULTATION_EVENTS.
;
; CATEGORY:
;   NAIF Satellite Position / Occultation Events
;
; CALLING SEQUENCE:
;   result = NSP_PREVIOUS_BRACKETING_OCCULTATION_INDEX( $
;              time_values, altitude_values, start_index, threshold)
;
; INPUTS:
;   time_values     - DOUBLE array. ET values for each CSV row.
;   altitude_values - DOUBLE array. Tangent altitude for each row (km).
;   start_index     - LONG scalar. Reference index (the post-crossing sample).
;   threshold       - DOUBLE scalar. Altitude boundary to bracket (km).
;
; OUTPUTS:
;   LONG scalar. Index of the nearest previous sample on the opposite side
;   of the threshold from the sample at start_index.
;   Raises an error if no bracketing sample is found.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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
    ; Bracketing condition: the candidate and current altitudes are on opposite sides of the threshold.
    if ((candidate_altitude - threshold_value) * (current_altitude - threshold_value)) le 0D then begin
      return, candidate_index
    endif
  endfor

  message, 'Step 10 occultation-event extraction failed: no previous bracketing sample was available for threshold interpolation.', /NONAME
end


;+
; NAME:
;   NSP_NEXT_BRACKETING_OCCULTATION_INDEX
;
; PURPOSE:
;   Searches forwards from start_index for the nearest later finite sample
;   that brackets a threshold crossing with the sample at start_index.
;   Called internally by NSP_EXTRACT_OCCULTATION_EVENTS.
;
; CATEGORY:
;   NAIF Satellite Position / Occultation Events
;
; CALLING SEQUENCE:
;   result = NSP_NEXT_BRACKETING_OCCULTATION_INDEX( $
;              time_values, altitude_values, start_index, threshold)
;
; INPUTS:
;   time_values     - DOUBLE array. ET values for each CSV row.
;   altitude_values - DOUBLE array. Tangent altitude for each row (km).
;   start_index     - LONG scalar. Reference index (the pre-crossing sample).
;   threshold       - DOUBLE scalar. Altitude boundary to bracket (km).
;
; OUTPUTS:
;   LONG scalar. Index of the nearest following sample on the opposite side
;   of the threshold from the sample at start_index.
;   Raises an error if no bracketing sample is found.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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
    ; Bracketing condition: the candidate and current altitudes are on opposite sides of the threshold.
    if ((candidate_altitude - threshold_value) * (current_altitude - threshold_value)) le 0D then begin
      return, candidate_index
    endif
  endfor

  message, 'Step 10 occultation-event extraction failed: no later bracketing sample was available for threshold interpolation.', /NONAME
end


;+
; NAME:
;   NSP_EXTRACT_OCCULTATION_EVENTS
;
; PURPOSE:
;   Reads one aggregate batch CSV file and extracts solar occultation events
;   (ingress and egress) by scanning the per-row tangent altitude sequence.
;   Returns both a per-row survey structure (one element per CSV row) and a
;   structure array of detected events with interpolated threshold crossing times.
;
;   A row is included in the event detection mask when all of the following
;   are true:
;     - batch_status = 'success'
;     - occultation_valid = 1
;     - tangent_altitude_km ∈ [0, altitude_max_km]
;
;   Contiguous masked segments are classified as ingress (descending altitude)
;   or egress (ascending altitude) by comparing the altitude at the segment
;   endpoints.  The start and end threshold crossings (altitude_max_km and
;   0 km) are linearly interpolated from the two bracketing samples.
;
;   The survey structure preserves one entry per CSV row, including failed
;   or non-occultation rows, so it can be used for full-orbit plotting.
;   survey.ss_lat is the first finite sub-solar latitude in the file (degrees),
;   used as a fixed-LsubS scalar for the current workflow.
;
; CATEGORY:
;   NAIF Satellite Position / Occultation Events
;
; CALLING SEQUENCE:
;   NSP_EXTRACT_OCCULTATION_EVENTS, csv_path $
;     [, SURVEY=survey] $
;     [, ALTITUDE_MAX_KM=altitude_max_km] $
;     [, EVENT_COUNT=event_count]
;
; INPUTS:
;   csv_path - STRING scalar. Path to the aggregate batch CSV file.
;
; OPTIONAL KEYWORDS:
;   ALTITUDE_MAX_KM - DOUBLE scalar. Upper tangent altitude boundary for
;                     event detection (km). Default: 150.0.
;   SURVEY          - Output. Anonymous structure with per-row arrays:
;                       time      - DOUBLE[n]. ET (seconds past J2000).
;                       tang_alt  - DOUBLE[n]. Tangent altitude (km).
;                       tang_lat  - DOUBLE[n]. Tangent latitude (degrees).
;                       tang_lon  - DOUBLE[n]. Tangent longitude (degrees).
;                       n_int     - LONG[n].   1 if row is in the event mask.
;                       sat_lat   - DOUBLE[n]. Spacecraft latitude (degrees).
;                       sat_lon   - DOUBLE[n]. Spacecraft longitude (degrees).
;                       sat_alt   - DOUBLE[n]. Spacecraft altitude (km).
;                       ss_lat    - DOUBLE scalar. First finite sub-solar latitude (degrees).
;                       ss_lon    - DOUBLE[n]. Sub-solar longitude (degrees).
;                       n_ingress - LONG scalar. Number of ingress events.
;                       n_egress  - LONG scalar. Number of egress events.
;                       events    - Structure array or -1L if no events found.
;   EVENT_COUNT     - Output. LONG scalar. Total number of detected events.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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

  ; Verify that every required column is present in the CSV structure.
  csv_tag_names = strlowcase(tag_names(csv_data))
  required_tags = ['et', 'occultation_valid', 'tangent_altitude_km', 'tangent_latitude_rad', 'tangent_longitude_rad', 'sc_latitude_rad', 'sc_longitude_rad', 'sc_altitude_km', 'subsolar_latitude_rad', 'subsolar_longitude_rad', 'batch_status']
  for tag_index = 0L, n_elements(required_tags) - 1L do begin
    if total(csv_tag_names eq required_tags[tag_index]) ne 1L then begin
      message, 'Step 10 occultation-event extraction failed: required batch CSV column was not found: ' + required_tags[tag_index], /NONAME
    endif
  endfor

  ; Validate that all column arrays have the same length.
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

  ; Allocate per-row survey arrays.
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

  ; Build the per-row survey arrays and the binary event detection mask.
  event_mask = bytarr(row_count)
  for row_index = 0L, row_count - 1L do begin
    time_values[row_index] = double(csv_data.et[row_index])
    tang_alt_values[row_index] = double(csv_data.tangent_altitude_km[row_index])
    ; Convert radian columns to degrees for the survey structure.
    tang_lat_values[row_index] = double(csv_data.tangent_latitude_rad[row_index]) * (180D / !dpi)
    tang_lon_values[row_index] = double(csv_data.tangent_longitude_rad[row_index]) * (180D / !dpi)
    sat_lat_values[row_index] = double(csv_data.sc_latitude_rad[row_index]) * (180D / !dpi)
    sat_lon_values[row_index] = double(csv_data.sc_longitude_rad[row_index]) * (180D / !dpi)
    sat_alt_values[row_index] = double(csv_data.sc_altitude_km[row_index])
    ss_lat_values[row_index] = double(csv_data.subsolar_latitude_rad[row_index]) * (180D / !dpi)
    ss_lon_values[row_index] = double(csv_data.subsolar_longitude_rad[row_index]) * (180D / !dpi)

    ; Capture the first finite sub-solar latitude as the fixed-LsubS scalar.
    if ~finite(ss_lat_scalar) and finite(ss_lat_values[row_index]) then ss_lat_scalar = ss_lat_values[row_index]

    ; Only successful, occultation-valid rows within the altitude window enter the mask.
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

  ; Scan for contiguous masked segments; each segment is one event.
  segment_start = 0L
  while segment_start lt row_count do begin
    if event_mask[segment_start] eq 0B then begin
      segment_start = segment_start + 1L
      continue
    endif

    ; Find the end of the contiguous masked segment.
    segment_end = segment_start
    while (segment_end + 1L lt row_count) and (event_mask[segment_end + 1L] eq 1B) do begin
      segment_end = segment_end + 1L
    endwhile

    ; Classify as ingress (decreasing) or egress (increasing) by altitude trend.
    trend_delta = tang_alt_values[segment_end] - tang_alt_values[segment_start]
    if (~finite(trend_delta)) or (trend_delta eq 0D) then begin
      ; Fall back to samples outside the segment when the trend is ambiguous.
      previous_trend_index = nsp_previous_finite_occultation_index(time_values, tang_alt_values, segment_start)
      next_trend_index = nsp_next_finite_occultation_index(time_values, tang_alt_values, segment_end)
      trend_delta = tang_alt_values[next_trend_index] - tang_alt_values[previous_trend_index]
    endif
    if (~finite(trend_delta)) or (trend_delta eq 0D) then begin
      message, 'Step 10 occultation-event extraction failed: unable to classify event trend for rows ' + strtrim(segment_start, 2) + ' through ' + strtrim(segment_end, 2) + '.', /NONAME
    endif

    if trend_delta lt 0D then begin
      ; Ingress: altitude is decreasing; event window runs from altitude_max_km down to 0 km.
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
      ; Egress: altitude is increasing; event window runs from 0 km up to altitude_max_km.
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

    ; Find the minimum and maximum tangent altitude within the event window.
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
