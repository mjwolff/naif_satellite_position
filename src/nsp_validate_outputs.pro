;+
; NAME:
;   NSP_VALIDATE_OUTPUTS
;
; PURPOSE:
;   Performs Step 11 of the NSP pipeline: validates the full set of computed
;   outputs for one epoch against a suite of physical consistency checks.
;   Verifies finiteness, sign constraints, planetocentric angle ranges, and
;   the altitude/radius/mean-radius identity.  For occultation-valid cases,
;   applies the same checks to the tangent-point geometry and confirms that
;   all tangent fields are finite.  For non-occultation cases, confirms that
;   all tangent fields are explicitly non-finite.
;   Called internally by NSP_BUILD_EXPORT_ROW (Step 9).
;
; CATEGORY:
;   NAIF Satellite Position / Validation
;
; CALLING SEQUENCE:
;   NSP_VALIDATE_OUTPUTS, state_vector, $
;     LONGITUDE=longitude, $
;     LATITUDE=latitude, $
;     RADIUS=radius, $
;     ALTITUDE=altitude, $
;     SOLAR_ZENITH_ANGLE=solar_zenith_angle, $
;     OCCULTATION_VALID=occultation_valid, $
;     TANGENT_POINT_VECTOR=tangent_point_vector, $
;     TANGENT_LONGITUDE=tangent_longitude, $
;     TANGENT_LATITUDE=tangent_latitude, $
;     TANGENT_RADIUS=tangent_radius, $
;     TANGENT_ALTITUDE=tangent_altitude
;
; INPUTS:
;   state_vector - DOUBLE array[6]. Spacecraft state in IAU_MARS (km, km/s).
;
; OPTIONAL KEYWORDS:
;   LONGITUDE            - DOUBLE scalar. Spacecraft IAU_MARS longitude (rad).
;   LATITUDE             - DOUBLE scalar. Spacecraft IAU_MARS latitude (rad).
;   RADIUS               - DOUBLE scalar. Spacecraft radial distance (km).
;   ALTITUDE             - DOUBLE scalar. Spacecraft altitude above Mars mean sphere (km).
;   SOLAR_ZENITH_ANGLE   - DOUBLE scalar. Spacecraft-local solar zenith angle (rad).
;   OCCULTATION_VALID    - BYTE scalar. 1 if solar occultation geometry is valid.
;   TANGENT_POINT_VECTOR - DOUBLE array[3]. Tangent-point position (km); NaN if invalid.
;   TANGENT_LONGITUDE    - DOUBLE scalar. Tangent-point longitude (rad); NaN if invalid.
;   TANGENT_LATITUDE     - DOUBLE scalar. Tangent-point latitude (rad); NaN if invalid.
;   TANGENT_RADIUS       - DOUBLE scalar. Tangent-point radial distance (km); NaN if invalid.
;   TANGENT_ALTITUDE     - DOUBLE scalar. Tangent-point altitude (km); NaN if invalid.
;
; OUTPUTS:
;   None. Prints a validation summary on success.  Raises a fatal error on
;   any failed check, halting execution.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_validate_outputs, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, solar_zenith_angle=solar_zenith_angle, occultation_valid=occultation_valid, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude
  compile_opt strictarr

  if n_elements(state_vector) ne 6 then begin
    message, 'Step 11 validation failed: expected a 6-element spacecraft state vector.', /NONAME
  endif

  state_values = double(state_vector)
  if total(finite(state_values)) ne 6 then begin
    message, 'Step 11 validation failed: spacecraft state vector contains non-finite values.', /NONAME
  endif

  ; Verify that each required scalar keyword was provided.
  if n_elements(longitude) ne 1 then begin
    message, 'Step 11 validation failed: longitude was not provided as a scalar.', /NONAME
  endif

  if n_elements(latitude) ne 1 then begin
    message, 'Step 11 validation failed: latitude was not provided as a scalar.', /NONAME
  endif

  if n_elements(radius) ne 1 then begin
    message, 'Step 11 validation failed: radius was not provided as a scalar.', /NONAME
  endif

  if n_elements(altitude) ne 1 then begin
    message, 'Step 11 validation failed: altitude was not provided as a scalar.', /NONAME
  endif

  if n_elements(solar_zenith_angle) ne 1 then begin
    message, 'Step 11 validation failed: solar_zenith_angle was not provided as a scalar.', /NONAME
  endif

  longitude_value = double(longitude)
  latitude_value = double(latitude)
  radius_value = double(radius)
  altitude_value = double(altitude)
  solar_zenith_angle_value = double(solar_zenith_angle)

  ; Finiteness checks.
  if ~finite(longitude_value) then begin
    message, 'Step 11 validation failed: longitude is non-finite.', /NONAME
  endif

  if ~finite(latitude_value) then begin
    message, 'Step 11 validation failed: latitude is non-finite.', /NONAME
  endif

  if (~finite(radius_value)) or (radius_value le 0D) then begin
    message, 'Step 11 validation failed: radius must be finite and positive.', /NONAME
  endif

  if ~finite(altitude_value) then begin
    message, 'Step 11 validation failed: altitude is non-finite.', /NONAME
  endif

  if (~finite(solar_zenith_angle_value)) then begin
    message, 'Step 11 validation failed: solar zenith angle is non-finite.', /NONAME
  endif

  ; Planetocentric angle range checks.
  if (latitude_value lt (-0.5D * !dpi)) or (latitude_value gt (0.5D * !dpi)) then begin
    message, 'Step 11 validation failed: latitude is outside the valid planetocentric range.', /NONAME
  endif

  if (longitude_value lt (-1D * !dpi)) or (longitude_value gt !dpi) then begin
    message, 'Step 11 validation failed: longitude is outside the documented planetocentric range.', /NONAME
  endif

  if (solar_zenith_angle_value lt 0D) or (solar_zenith_angle_value gt !dpi) then begin
    message, 'Step 11 validation failed: solar zenith angle is outside the valid range [0, pi].', /NONAME
  endif

  ; Altitude/radius identity: altitude = radius - Mars mean radius.
  radius_tolerance = 1D-9
  altitude_tolerance = 1D-9
  if abs(radius_value - (altitude_value + nsp_mars_mean_radius_km())) gt radius_tolerance then begin
    message, 'Step 11 validation failed: altitude does not match radius minus the documented Mars mean radius.', /NONAME
  endif

  if n_elements(occultation_valid) ne 1 then begin
    message, 'Step 11 validation failed: occultation_valid was not provided as a scalar.', /NONAME
  endif

  occultation_flag = long(occultation_valid)
  if (occultation_flag ne 0L) and (occultation_flag ne 1L) then begin
    message, 'Step 11 validation failed: occultation_valid must be an explicit 0 or 1 flag.', /NONAME
  endif

  if n_elements(tangent_point_vector) ne 3 then begin
    message, 'Step 11 validation failed: expected a 3-element tangent-point vector.', /NONAME
  endif

  tangent_values = double(tangent_point_vector)
  tangent_longitude_value = double(tangent_longitude)
  tangent_latitude_value = double(tangent_latitude)
  tangent_radius_value = double(tangent_radius)
  tangent_altitude_value = double(tangent_altitude)

  if occultation_flag eq 1L then begin
    ; Occultation-valid: all tangent fields must be finite and physically plausible.
    if total(finite(tangent_values)) ne 3 then begin
      message, 'Step 11 validation failed: occultation-valid tangent-point vector contains non-finite values.', /NONAME
    endif

    if (~finite(tangent_longitude_value)) or (~finite(tangent_latitude_value)) then begin
      message, 'Step 11 validation failed: occultation-valid tangent longitude/latitude contains non-finite values.', /NONAME
    endif

    if (~finite(tangent_radius_value)) or (tangent_radius_value le 0D) then begin
      message, 'Step 11 validation failed: occultation-valid tangent radius must be finite and positive.', /NONAME
    endif

    if ~finite(tangent_altitude_value) then begin
      message, 'Step 11 validation failed: occultation-valid tangent altitude is non-finite.', /NONAME
    endif

    if (tangent_latitude_value lt (-0.5D * !dpi)) or (tangent_latitude_value gt (0.5D * !dpi)) then begin
      message, 'Step 11 validation failed: occultation-valid tangent latitude is outside the valid planetocentric range.', /NONAME
    endif

    if (tangent_longitude_value lt (-1D * !dpi)) or (tangent_longitude_value gt !dpi) then begin
      message, 'Step 11 validation failed: occultation-valid tangent longitude is outside the documented planetocentric range.', /NONAME
    endif

    if abs(tangent_radius_value - (tangent_altitude_value + nsp_mars_mean_radius_km())) gt altitude_tolerance then begin
      message, 'Step 11 validation failed: occultation-valid tangent altitude does not match tangent radius minus the documented Mars mean radius.', /NONAME
    endif

    if tangent_altitude_value le (-1D * nsp_mars_mean_radius_km()) then begin
      message, 'Step 11 validation failed: occultation-valid tangent altitude is physically implausible for a positive-radius tangent point.', /NONAME
    endif
  endif else begin
    ; Non-occultation: all tangent fields must be explicitly non-finite (NaN).
    if total(finite(tangent_values)) gt 0 then begin
      message, 'Step 11 validation failed: non-occultation cases must not report finite tangent-point vector values.', /NONAME
    endif

    if finite(tangent_longitude_value) or finite(tangent_latitude_value) or finite(tangent_radius_value) or finite(tangent_altitude_value) then begin
      message, 'Step 11 validation failed: non-occultation cases must keep tangent geometry explicitly non-finite.', /NONAME
    endif
  endelse

  print, 'Step 11 validation passed.'
  print, 'Validated required output finiteness, angle ranges, and tangent-geometry consistency.'
end
