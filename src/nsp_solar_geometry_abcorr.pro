;+
; NAME:
;   NSP_SOLAR_GEOMETRY_ABCORR
;
; PURPOSE:
;   Returns the SPICE aberration correction string used for all solar
;   geometry calculations in the NSP pipeline. Centralising this value
;   ensures that Steps 7 and 8 share an identical, explicitly documented
;   convention.
;
; CATEGORY:
;   NAIF Satellite Position / Constants
;
; CALLING SEQUENCE:
;   abcorr = NSP_SOLAR_GEOMETRY_ABCORR()
;
; INPUTS:
;   None
;
; OUTPUTS:
;   Result - Scalar STRING. SPICE aberration correction code ('NONE').
;
; NOTES:
;   'NONE' requests geometric (instantaneous) states with no light-time
;   or stellar aberration correction. This is consistent with the
;   convention used for spacecraft state retrieval in Step 5.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_solar_geometry_abcorr
  compile_opt strictarr

  return, 'NONE'
end
