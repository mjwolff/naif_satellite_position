;+
; NAME:
;   NSP_COMPUTE_SOLAR_GEOMETRY
;
; PURPOSE:
;   Computes the spacecraft-to-Sun vector and the spacecraft-local solar
;   zenith angle from TGO and Sun state vectors in the IAU_MARS frame.
;
; CATEGORY:
;   NAIF Satellite Position / Geometry
;
; CALLING SEQUENCE:
;   NSP_COMPUTE_SOLAR_GEOMETRY, state_vector, sun_state_vector, $
;     SPACECRAFT_TO_SUN_VECTOR=spacecraft_to_sun_vector, $
;     SOLAR_ZENITH_ANGLE=solar_zenith_angle
;
; INPUTS:
;   state_vector     - DOUBLE array[6]. TGO state in IAU_MARS frame (km, km/s).
;   sun_state_vector - DOUBLE array[6]. Sun state relative to Mars in
;                      IAU_MARS frame (km, km/s).
;
; OUTPUTS:
;   SPACECRAFT_TO_SUN_VECTOR - DOUBLE array[3]. Vector from the spacecraft
;                              to the Sun in km (IAU_MARS frame).
;   SOLAR_ZENITH_ANGLE       - DOUBLE scalar. Spacecraft-local solar zenith
;                              angle in radians, range [0, pi]. Defined as
;                              the angle between the outward radial vector
;                              at the spacecraft and the spacecraft-to-Sun
;                              direction.
;
; ALGORITHM:
;   spacecraft_to_sun = sun_position - spacecraft_position
;   cos(SZA) = dot(spacecraft_position, spacecraft_to_sun) /
;              (|spacecraft_position| * |spacecraft_to_sun|)
;   Cosine is clamped to [-1, 1] before acos to guard against
;   floating-point rounding outside the valid domain.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_compute_solar_geometry, state_vector, sun_state_vector, spacecraft_to_sun_vector=spacecraft_to_sun_vector, solar_zenith_angle=solar_zenith_angle
  compile_opt strictarr

  if n_elements(state_vector) ne 6 then begin
    message, 'Step 7 solar geometry failed: expected a 6-element spacecraft state vector.', /NONAME
  endif

  if n_elements(sun_state_vector) ne 6 then begin
    message, 'Step 7 solar geometry failed: expected a 6-element Sun state vector.', /NONAME
  endif

  spacecraft_state_values = double(state_vector)
  sun_state_values = double(sun_state_vector)

  if total(finite(spacecraft_state_values)) ne 6 then begin
    message, 'Step 7 solar geometry failed: spacecraft state vector contains non-finite values.', /NONAME
  endif

  if total(finite(sun_state_values)) ne 6 then begin
    message, 'Step 7 solar geometry failed: Sun state vector contains non-finite values.', /NONAME
  endif

  spacecraft_position = spacecraft_state_values[0:2]
  sun_position = sun_state_values[0:2]
  spacecraft_to_sun_vector = sun_position - spacecraft_position

  if total(finite(spacecraft_to_sun_vector)) ne 3 then begin
    message, 'Step 7 solar geometry failed: spacecraft-to-Sun vector contains non-finite values.', /NONAME
  endif

  spacecraft_radius = sqrt(total(spacecraft_position * spacecraft_position))
  sun_range = sqrt(total(spacecraft_to_sun_vector * spacecraft_to_sun_vector))

  if (~finite(spacecraft_radius)) or (spacecraft_radius le 0D) then begin
    message, 'Step 7 solar geometry failed: spacecraft radius must be finite and positive.', /NONAME
  endif

  if (~finite(sun_range)) or (sun_range le 0D) then begin
    message, 'Step 7 solar geometry failed: spacecraft-to-Sun range must be finite and positive.', /NONAME
  endif

  cosine_sza = total(spacecraft_position * spacecraft_to_sun_vector) / (spacecraft_radius * sun_range)
  if ~finite(cosine_sza) then begin
    message, 'Step 7 solar geometry failed: computed cosine of solar zenith angle is non-finite.', /NONAME
  endif

  ; Clamp to [-1, 1] to guard against floating-point rounding before acos.
  if cosine_sza gt 1D then cosine_sza = 1D
  if cosine_sza lt (-1D) then cosine_sza = -1D

  solar_zenith_angle = acos(cosine_sza)
  if ~finite(solar_zenith_angle) then begin
    message, 'Step 7 solar geometry failed: solar zenith angle is non-finite.', /NONAME
  endif

  if (solar_zenith_angle lt 0D) or (solar_zenith_angle gt !dpi) then begin
    message, 'Step 7 solar geometry failed: solar zenith angle is outside the valid range [0, pi].', /NONAME
  endif
end
