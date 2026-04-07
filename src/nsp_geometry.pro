;+
; NAME:
;   NSP_GEOMETRY
;
; PURPOSE:
;   Reporting wrapper for Step 6. Retrieves the TGO state at a given ET
;   and computes planetocentric geometry, printing a summary to the IDL
;   console. Intended for interactive use and pipeline step validation.
;
; CATEGORY:
;   NAIF Satellite Position / Geometry
;
; CALLING SEQUENCE:
;   NSP_GEOMETRY, ET=et [, STATE_VECTOR=state_vector] $
;                 [, LONGITUDE=longitude] [, LATITUDE=latitude] $
;                 [, RADIUS=radius] [, ALTITUDE=altitude]
;
; OPTIONAL KEYWORDS:
;   ET           - DOUBLE scalar. Ephemeris time in seconds past J2000.
;                  Required.
;   STATE_VECTOR - Output. DOUBLE array[6]. TGO state in IAU_MARS frame.
;   LONGITUDE    - Output. DOUBLE scalar. Planetocentric longitude in radians.
;   LATITUDE     - Output. DOUBLE scalar. Planetocentric latitude in radians.
;   RADIUS       - Output. DOUBLE scalar. Radial distance from Mars centre in km.
;   ALTITUDE     - Output. DOUBLE scalar. Altitude above Mars mean sphere in km.
;
; EXAMPLE:
;   et = NSP_UTC_TO_ET('2025-01-01T00:00:00')
;   NSP_GEOMETRY, ET=et, LONGITUDE=lon, LATITUDE=lat, ALTITUDE=alt
;   print, alt
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_geometry, et=et, state_vector=state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 6 geometry conversion failed: ET was not provided.', /NONAME
  endif

  nsp_get_tgo_state, et, state_vector=state_vector, light_time=light_time
  nsp_compute_geometry_from_state, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, position_vector=position_vector

  print, 'Step 6 geometry conversion passed.'
  print, 'Mars mean radius km=' + strtrim(nsp_mars_mean_radius_km(), 2)
  print, 'Longitude radians=' + strtrim(longitude, 2)
  print, 'Latitude radians=' + strtrim(latitude, 2)
  print, 'Radius km=' + strtrim(radius, 2)
  print, 'Altitude km=' + strtrim(altitude, 2)
end
