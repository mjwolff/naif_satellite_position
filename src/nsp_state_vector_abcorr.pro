;+
; NAME:
;   NSP_STATE_VECTOR_ABCORR
;
; PURPOSE:
;   Returns the SPICE aberration correction string used for spacecraft
;   state vector retrieval in the NSP pipeline. Centralising this value
;   ensures all state retrieval calls share an identical, explicitly
;   documented convention.
;
; CATEGORY:
;   NAIF Satellite Position / Constants
;
; CALLING SEQUENCE:
;   abcorr = NSP_STATE_VECTOR_ABCORR()
;
; INPUTS:
;   None
;
; OUTPUTS:
;   Result - Scalar STRING. SPICE aberration correction code ('NONE').
;
; NOTES:
;   'NONE' requests geometric (instantaneous) states with no light-time
;   or stellar aberration correction. Aberration corrections can be
;   introduced explicitly by passing a different code to the underlying
;   SPICE calls via the ICY_DLM_PATH keyword chain if required.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_state_vector_abcorr
  compile_opt strictarr

  return, 'NONE'
end
