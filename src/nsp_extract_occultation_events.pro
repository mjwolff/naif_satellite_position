; Return an empty occultation-event result structure.
;
; Calling sequence:
;   events = nsp_empty_occultation_events()
;
; Returns:
;   Anonymous structure with one array-valued tag per event property.
function nsp_empty_occultation_events
  compile_opt strictarr

  return, create_struct($
    'event_id', strarr(0), $
    'event_type', strarr(0), $
    'start_row_index', lonarr(0), $
    'end_row_index', lonarr(0), $
    'sample_count', lonarr(0), $
    'start_case_id', strarr(0), $
    'end_case_id', strarr(0), $
    'start_utc', strarr(0), $
    'end_utc', strarr(0), $
    'start_tangent_altitude_km', dblarr(0), $
    'end_tangent_altitude_km', dblarr(0), $
    'minimum_tangent_altitude_km', dblarr(0), $
    'maximum_tangent_altitude_km', dblarr(0))
end


; Extract ingress and egress occultation events from one aggregate batch CSV.
;
; Calling sequence:
;   nsp_extract_occultation_events, csv_path, events=events, [altitude_max_km=altitude_max_km], [event_count=event_count]
;
; Inputs:
;   csv_path         - path to one aggregate CSV written by NSP_RUN_BATCH.
;   altitude_max_km  - optional upper tangent-altitude bound for event extraction.
;                      Defaults to 150 km.
;
; Output keywords:
;   events      - structure of event-property arrays. Each index describes one event.
;   event_count - number of extracted events.
;
; Notes:
;   The extractor requires batch rows with batch_status='success', occultation_valid=1,
;   and finite tangent_altitude_km inside 0 <= altitude <= altitude_max_km. Contiguous
;   runs of such rows become events. Decreasing altitude is labeled 'ingress' and
;   increasing altitude is labeled 'egress'.
pro nsp_extract_occultation_events, csv_path, events=events, altitude_max_km=altitude_max_km, event_count=event_count
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
  required_tags = ['case_id', 'utc', 'occultation_valid', 'tangent_altitude_km', 'batch_status']
  for tag_index = 0L, n_elements(required_tags) - 1L do begin
    if total(csv_tag_names eq required_tags[tag_index]) ne 1L then begin
      message, 'Step 10 occultation-event extraction failed: required batch CSV column was not found: ' + required_tags[tag_index], /NONAME
    endif
  endfor

  row_count = n_elements(csv_data.case_id)
  if n_elements(csv_data.utc) ne row_count then message, 'Step 10 occultation-event extraction failed: utc column length does not match case_id.', /NONAME
  if n_elements(csv_data.occultation_valid) ne row_count then message, 'Step 10 occultation-event extraction failed: occultation_valid column length does not match case_id.', /NONAME
  if n_elements(csv_data.tangent_altitude_km) ne row_count then message, 'Step 10 occultation-event extraction failed: tangent_altitude_km column length does not match case_id.', /NONAME
  if n_elements(csv_data.batch_status) ne row_count then message, 'Step 10 occultation-event extraction failed: batch_status column length does not match case_id.', /NONAME

  if row_count eq 0L then begin
    events = nsp_empty_occultation_events()
    event_count = 0L
    return
  endif

  in_event_mask = bytarr(row_count)
  tangent_altitudes = dblarr(row_count)
  tangent_altitudes[*] = !values.d_nan

  for row_index = 0L, row_count - 1L do begin
    batch_status_value = strlowcase(strtrim(csv_data.batch_status[row_index], 2))
    if batch_status_value ne 'success' then continue

    occultation_flag = long(strtrim(csv_data.occultation_valid[row_index], 2))
    if occultation_flag ne 1L then continue

    tangent_altitude_value = double(csv_data.tangent_altitude_km[row_index])
    tangent_altitudes[row_index] = tangent_altitude_value

    if finite(tangent_altitude_value) and (tangent_altitude_value ge 0D) and (tangent_altitude_value le altitude_limit) then begin
      in_event_mask[row_index] = 1B
    endif
  endfor

  if total(long(in_event_mask)) eq 0L then begin
    events = nsp_empty_occultation_events()
    event_count = 0L
    return
  endif

  event_ids = strarr(row_count)
  event_types = strarr(row_count)
  start_row_indices = lonarr(row_count)
  end_row_indices = lonarr(row_count)
  sample_counts = lonarr(row_count)
  start_case_ids = strarr(row_count)
  end_case_ids = strarr(row_count)
  start_utcs = strarr(row_count)
  end_utcs = strarr(row_count)
  start_altitudes = dblarr(row_count)
  end_altitudes = dblarr(row_count)
  minimum_altitudes = dblarr(row_count)
  maximum_altitudes = dblarr(row_count)
  event_count = 0L

  row_index = 0L
  while row_index lt row_count do begin
    if in_event_mask[row_index] eq 0B then begin
      row_index = row_index + 1L
      continue
    endif

    start_index = row_index
    while (row_index + 1L lt row_count) and (in_event_mask[row_index + 1L] eq 1B) do begin
      row_index = row_index + 1L
    endwhile
    end_index = row_index

    trend_delta = tangent_altitudes[end_index] - tangent_altitudes[start_index]
    if (~finite(trend_delta)) or (abs(trend_delta) le 0D) then begin
      message, 'Step 10 occultation-event extraction failed: unable to classify event trend for rows ' + strtrim(start_index, 2) + ' through ' + strtrim(end_index, 2) + '.', /NONAME
    endif

    if trend_delta lt 0D then begin
      event_type = 'ingress'
    endif else begin
      event_type = 'egress'
    endelse

    event_ids[event_count] = 'occultation_event_' + strtrim(event_count + 1L, 2)
    event_types[event_count] = event_type
    start_row_indices[event_count] = start_index
    end_row_indices[event_count] = end_index
    sample_counts[event_count] = end_index - start_index + 1L
    start_case_ids[event_count] = csv_data.case_id[start_index]
    end_case_ids[event_count] = csv_data.case_id[end_index]
    start_utcs[event_count] = csv_data.utc[start_index]
    end_utcs[event_count] = csv_data.utc[end_index]
    start_altitudes[event_count] = tangent_altitudes[start_index]
    end_altitudes[event_count] = tangent_altitudes[end_index]

    segment_altitudes = tangent_altitudes[start_index:end_index]
    segment_maximum_altitude = !values.d_nan
    minimum_altitudes[event_count] = min(segment_altitudes, max=segment_maximum_altitude)
    maximum_altitudes[event_count] = segment_maximum_altitude
    event_count = event_count + 1L
    row_index = row_index + 1L
  endwhile

  events = create_struct($
    'event_id', event_ids[0:event_count - 1L], $
    'event_type', event_types[0:event_count - 1L], $
    'start_row_index', start_row_indices[0:event_count - 1L], $
    'end_row_index', end_row_indices[0:event_count - 1L], $
    'sample_count', sample_counts[0:event_count - 1L], $
    'start_case_id', start_case_ids[0:event_count - 1L], $
    'end_case_id', end_case_ids[0:event_count - 1L], $
    'start_utc', start_utcs[0:event_count - 1L], $
    'end_utc', end_utcs[0:event_count - 1L], $
    'start_tangent_altitude_km', start_altitudes[0:event_count - 1L], $
    'end_tangent_altitude_km', end_altitudes[0:event_count - 1L], $
    'minimum_tangent_altitude_km', minimum_altitudes[0:event_count - 1L], $
    'maximum_tangent_altitude_km', maximum_altitudes[0:event_count - 1L])
end
