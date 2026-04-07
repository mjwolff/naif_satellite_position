;+
; NAME:
;   NSP_SOLAR_GEOMETRY
;
; PURPOSE:
;   Reporting wrapper for Step 7. Retrieves TGO and Sun state vectors at
;   a given ET, computes solar geometry, and prints a summary to the IDL
;   console. Intended for interactive use and pipeline step validation.
;
; CATEGORY:
;   NAIF Satellite Position / Geometry
;
; CALLING SEQUENCE:
;   NSP_SOLAR_GEOMETRY, ET=et $
;     [, STATE_VECTOR=state_vector] $
;     [, SUN_STATE_VECTOR=sun_state_vector] $
;     [, SPACECRAFT_TO_SUN_VECTOR=spacecraft_to_sun_vector] $
;     [, SOLAR_ZENITH_ANGLE=solar_zenith_angle]
;
; OPTIONAL KEYWORDS:
;   ET                       - DOUBLE scalar. Ephemeris time in seconds
;                              past J2000. Required.
;   STATE_VECTOR             - Output. DOUBLE array[6]. TGO state in IAU_MARS.
;   SUN_STATE_VECTOR         - Output. DOUBLE array[6]. Sun state in IAU_MARS.
;   SPACECRAFT_TO_SUN_VECTOR - Output. DOUBLE array[3]. Spacecraft-to-Sun
;                              vector in km.
;   SOLAR_ZENITH_ANGLE       - Output. DOUBLE scalar. Spacecraft-local SZA
;                              in radians.
;
; EXAMPLE:
;   et = NSP_UTC_TO_ET('2025-01-01T00:00:00')
;   NSP_SOLAR_GEOMETRY, ET=et, SOLAR_ZENITH_ANGLE=sza
;   print, sza * !radeg
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_solar_geometry, et=et, state_vector=state_vector, sun_state_vector=sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 7 solar geometry failed: ET was not provided.', /NONAME
  endif

  nsp_get_tgo_state, et, state_vector=state_vector, light_time=spacecraft_light_time
  nsp_get_sun_state, et, sun_state_vector=sun_state_vector, light_time=sun_light_time
  nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle

  print, 'Step 7 solar geometry passed.'
  print, 'Frame=IAU_MARS'
  print, 'Aberration correction=' + nsp_solar_geometry_abcorr()
  print, 'Observer=MARS'
  print, 'Target=SUN'
  print, 'Solar zenith angle radians=' + strtrim(solar_zenith_angle, 2)
  print, 'Spacecraft-to-Sun range km=' + strtrim(sqrt(total(spacecraft_to_sun_vector * spacecraft_to_sun_vector)), 2)
end
