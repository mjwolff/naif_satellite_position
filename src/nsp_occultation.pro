;+
; NAME:
;   NSP_OCCULTATION
;
; PURPOSE:
;   Reporting wrapper for Step 8. Retrieves TGO and Sun states, computes
;   solar and occultation geometry, and prints a summary to the IDL
;   console. Intended for interactive use and pipeline step validation.
;
; CATEGORY:
;   NAIF Satellite Position / Geometry
;
; CALLING SEQUENCE:
;   NSP_OCCULTATION, ET=et $
;     [, STATE_VECTOR=state_vector] $
;     [, SUN_STATE_VECTOR=sun_state_vector] $
;     [, SPACECRAFT_TO_SUN_VECTOR=spacecraft_to_sun_vector] $
;     [, TANGENT_POINT_VECTOR=tangent_point_vector] $
;     [, TANGENT_LONGITUDE=tangent_longitude] $
;     [, TANGENT_LATITUDE=tangent_latitude] $
;     [, TANGENT_RADIUS=tangent_radius] $
;     [, TANGENT_ALTITUDE=tangent_altitude] $
;     [, OCCULTATION_VALID=occultation_valid] $
;     [, CLOSEST_APPROACH_DISTANCE=closest_approach_distance]
;
; OPTIONAL KEYWORDS:
;   ET                        - DOUBLE scalar. Ephemeris time. Required.
;   STATE_VECTOR              - Output. DOUBLE array[6]. TGO state.
;   SUN_STATE_VECTOR          - Output. DOUBLE array[6]. Sun state.
;   SPACECRAFT_TO_SUN_VECTOR  - Output. DOUBLE array[3]. S/C-to-Sun vector.
;   TANGENT_POINT_VECTOR      - Output. DOUBLE array[3]. Tangent point (km).
;   TANGENT_LONGITUDE         - Output. DOUBLE scalar. Tangent longitude (rad).
;   TANGENT_LATITUDE          - Output. DOUBLE scalar. Tangent latitude (rad).
;   TANGENT_RADIUS            - Output. DOUBLE scalar. Tangent radius (km).
;   TANGENT_ALTITUDE          - Output. DOUBLE scalar. Tangent altitude (km).
;   OCCULTATION_VALID         - Output. BYTE scalar. 1 if occultation geometry
;                               is valid, 0 otherwise.
;   CLOSEST_APPROACH_DISTANCE - Output. DOUBLE scalar. Distance along ray
;                               to closest approach (km).
;
; EXAMPLE:
;   et = NSP_UTC_TO_ET('2025-01-01T00:00:00')
;   NSP_OCCULTATION, ET=et, TANGENT_ALTITUDE=tang_alt, OCCULTATION_VALID=valid
;   if valid then print, tang_alt
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_occultation, et=et, state_vector=state_vector, sun_state_vector=sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 8 occultation geometry failed: ET was not provided.', /NONAME
  endif

  nsp_get_tgo_state, et, state_vector=state_vector, light_time=spacecraft_light_time
  nsp_get_sun_state, et, sun_state_vector=sun_state_vector, light_time=sun_light_time
  nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  nsp_compute_occultation_geometry, state_vector, spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance

  print, 'Step 8 occultation geometry passed.'
  print, 'Occultation valid=' + strtrim(fix(occultation_valid), 2)
  print, 'Closest approach distance km=' + strtrim(closest_approach_distance, 2)

  if occultation_valid then begin
    print, 'Tangent longitude radians=' + strtrim(tangent_longitude, 2)
    print, 'Tangent latitude radians=' + strtrim(tangent_latitude, 2)
    print, 'Tangent radius km=' + strtrim(tangent_radius, 2)
    print, 'Tangent altitude km=' + strtrim(tangent_altitude, 2)
  endif else begin
    print, 'Non-occultation case flagged explicitly; tangent-point geometry is not reported as valid.'
  endelse
end
