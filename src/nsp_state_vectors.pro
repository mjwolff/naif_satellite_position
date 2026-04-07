;+
; NAME:
;   NSP_STATE_VECTORS
;
; PURPOSE:
;   Reporting wrapper around NSP_GET_TGO_STATE. Retrieves the TGO state
;   vector at a given ET and prints a summary to the IDL console.
;   Intended for interactive use and pipeline step validation.
;
; CATEGORY:
;   NAIF Satellite Position / State Vectors
;
; CALLING SEQUENCE:
;   NSP_STATE_VECTORS, ET=et [, STATE_VECTOR=state_vector] $
;                      [, LIGHT_TIME=light_time]
;
; OPTIONAL KEYWORDS:
;   ET           - DOUBLE scalar. Ephemeris time in seconds past J2000.
;                  Required.
;   STATE_VECTOR - Output. DOUBLE array[6]. TGO state in IAU_MARS frame.
;   LIGHT_TIME   - Output. DOUBLE scalar. One-way light time in seconds.
;
; OUTPUTS:
;   STATE_VECTOR - DOUBLE array[6]: [x, y, z, vx, vy, vz] in km and km/s.
;   LIGHT_TIME   - DOUBLE scalar in seconds.
;
; EXAMPLE:
;   et = NSP_UTC_TO_ET('2025-01-01T00:00:00')
;   NSP_STATE_VECTORS, ET=et, STATE_VECTOR=sv, LIGHT_TIME=lt
;   print, sv
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_state_vectors, et=et, state_vector=state_vector, light_time=light_time
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 5 state-vector retrieval failed: ET was not provided.', /NONAME
  endif

  nsp_get_tgo_state, et, state_vector=state_vector, light_time=light_time

  print, 'Step 5 state-vector retrieval passed.'
  print, 'Frame=IAU_MARS'
  print, 'Aberration correction=' + nsp_state_vector_abcorr()
  print, 'Observer=MARS'
  print, 'Target=TGO'
  print, 'State X=' + strtrim(state_vector[0], 2)
  print, 'State VZ=' + strtrim(state_vector[5], 2)
  print, 'Light time=' + strtrim(light_time, 2)
end
