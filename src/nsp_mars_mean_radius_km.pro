;+
; NAME:
;   NSP_MARS_MEAN_RADIUS_KM
;
; PURPOSE:
;   Returns the Mars mean radius used throughout the NSP pipeline for
;   spherical altitude calculations. Centralising this value ensures
;   that all pipeline steps reference an identical constant.
;
; CATEGORY:
;   NAIF Satellite Position / Constants
;
; CALLING SEQUENCE:
;   radius = NSP_MARS_MEAN_RADIUS_KM()
;
; INPUTS:
;   None
;
; OUTPUTS:
;   Result - Scalar DOUBLE. Mars mean radius in kilometres (3389.5 km).
;
; NOTES:
;   The value 3389.5 km is the IAU 2015 mean radius for Mars and is
;   consistent with the SPICE PCK kernel pck00010.tpc.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_mars_mean_radius_km
  compile_opt strictarr

  return, 3389.5D
end
