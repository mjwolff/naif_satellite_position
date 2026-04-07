;+
; NAME:
;   NSP_COMPUTE_KEPLERIAN_ELEMENTS
;
; PURPOSE:
;   Derives osculating Keplerian elements from a Mars-centred inertial
;   (J2000) state vector at a given epoch using the SPICE cspice_oscelt
;   routine. The Mars gravitational parameter is read directly from the
;   loaded PCK kernel via cspice_bodvrd.
;
; CATEGORY:
;   NAIF Satellite Position / Orbital Mechanics
;
; CALLING SEQUENCE:
;   NSP_COMPUTE_KEPLERIAN_ELEMENTS, et, inertial_state_vector, $
;     KEPLERIAN_ELEMENTS=keplerian_elements [, MARS_GM=mars_gm]
;
; INPUTS:
;   et                    - DOUBLE scalar. Ephemeris time in seconds
;                           past J2000 corresponding to the state vector.
;   inertial_state_vector - DOUBLE array[6]. Mars-centred J2000 state
;                           vector [x, y, z, vx, vy, vz] in km and km/s,
;                           as returned by NSP_GET_TGO_STATE_J2000.
;
; OUTPUTS:
;   KEPLERIAN_ELEMENTS - DOUBLE array[8]. Osculating elements returned
;                        by cspice_oscelt in the following order:
;                        [rp, ecc, inc, lnode, argp, m0, t0, mu]
;                        where rp   = periapsis radius (km)
;                              ecc  = eccentricity
;                              inc  = inclination (rad)
;                              lnode = longitude of ascending node (rad)
;                              argp  = argument of periapsis (rad)
;                              m0   = mean anomaly at epoch (rad)
;                              t0   = epoch (ET seconds past J2000)
;                              mu   = central-body GM (km^3/s^2)
;   MARS_GM            - DOUBLE scalar. Mars gravitational parameter
;                        (km^3/s^2) as read from the PCK kernel.
;
; NOTES:
;   A J2000 state vector must be used rather than the IAU_MARS rotating
;   frame, because osculating elements are defined in an inertial frame.
;   Both cspice_bodvrd and cspice_oscelt are called via EXECUTE so that
;   they resolve correctly regardless of when the ICY DLM was loaded.
;
; REFERENCES:
;   Bate, R. R., Mueller, D. D., & White, J. E. (1971). Fundamentals
;   of Astrodynamics. Dover Publications.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_compute_keplerian_elements, et, inertial_state_vector, keplerian_elements=keplerian_elements, mars_gm=mars_gm
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 9 export failed: ET was not provided for Keplerian-element calculation.', /NONAME
  endif

  if n_elements(inertial_state_vector) ne 6 then begin
    message, 'Step 9 export failed: expected a 6-element inertial state vector for Keplerian-element calculation.', /NONAME
  endif

  et_value = double(et)
  if ~finite(et_value) then begin
    message, 'Step 9 export failed: ET must be finite for Keplerian-element calculation.', /NONAME
  endif

  state_values = double(inertial_state_vector)
  if total(finite(state_values)) ne 6 then begin
    message, 'Step 9 export failed: inertial state vector contains non-finite values.', /NONAME
  endif

  ; Read Mars GM from the loaded PCK kernel; wrapped in EXECUTE for
  ; DLM resolution safety.
  status = execute("cspice_bodvrd, 'MARS', 'GM', 1, gm_values")
  if status eq 0 then begin
    message, 'Step 9 export failed: unable to read Mars GM with cspice_bodvrd.', /NONAME
  endif

  if n_elements(gm_values) lt 1 then begin
    message, 'Step 9 export failed: Mars GM was not returned by cspice_bodvrd.', /NONAME
  endif

  mars_gm = double(gm_values[0])
  if ~finite(mars_gm) then begin
    message, 'Step 9 export failed: Mars GM is non-finite.', /NONAME
  endif

  ; Compute osculating elements from the J2000 inertial state vector.
  status = execute('cspice_oscelt, state_values, et_value, mars_gm, keplerian_elements')
  if status eq 0 then begin
    message, 'Step 9 export failed: cspice_oscelt did not complete successfully.', /NONAME
  endif

  if n_elements(keplerian_elements) ne 8 then begin
    message, 'Step 9 export failed: expected 8 osculating-element values from cspice_oscelt.', /NONAME
  endif

  if total(finite(keplerian_elements)) ne 8 then begin
    message, 'Step 9 export failed: Keplerian elements contain non-finite values.', /NONAME
  endif
end
