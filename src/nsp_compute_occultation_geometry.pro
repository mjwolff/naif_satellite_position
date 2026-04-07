;+
; NAME:
;   NSP_COMPUTE_OCCULTATION_GEOMETRY
;
; PURPOSE:
;   Computes the solar occultation tangent point for a given spacecraft
;   position and spacecraft-to-Sun direction. The tangent point is the
;   point of closest approach of the spacecraft-to-Sun ray to the centre
;   of Mars, which defines the atmospheric layer being sampled.
;
; CATEGORY:
;   NAIF Satellite Position / Geometry
;
; CALLING SEQUENCE:
;   NSP_COMPUTE_OCCULTATION_GEOMETRY, state_vector, spacecraft_to_sun_vector, $
;     TANGENT_POINT_VECTOR=tangent_point_vector, $
;     TANGENT_LONGITUDE=tangent_longitude, $
;     TANGENT_LATITUDE=tangent_latitude, $
;     TANGENT_RADIUS=tangent_radius, $
;     TANGENT_ALTITUDE=tangent_altitude, $
;     OCCULTATION_VALID=occultation_valid, $
;     CLOSEST_APPROACH_DISTANCE=closest_approach_distance
;
; INPUTS:
;   state_vector             - DOUBLE array[6]. TGO state in IAU_MARS (km, km/s).
;   spacecraft_to_sun_vector - DOUBLE array[3]. Vector from spacecraft to
;                              Sun in km (IAU_MARS frame).
;
; OUTPUTS:
;   TANGENT_POINT_VECTOR     - DOUBLE array[3]. Tangent-point position in km
;                              (IAU_MARS frame), or NaN if non-occultation.
;   TANGENT_LONGITUDE        - DOUBLE scalar. Tangent-point longitude in radians.
;   TANGENT_LATITUDE         - DOUBLE scalar. Tangent-point latitude in radians.
;   TANGENT_RADIUS           - DOUBLE scalar. Tangent-point radial distance in km.
;   TANGENT_ALTITUDE         - DOUBLE scalar. Tangent-point altitude above the
;                              Mars mean sphere in km.
;   OCCULTATION_VALID        - BYTE scalar. 1 if the ray has a forward
;                              closest approach (Sun is ahead of spacecraft);
;                              0 otherwise. When 0, all tangent-point outputs
;                              are set to NaN.
;   CLOSEST_APPROACH_DISTANCE - DOUBLE scalar. Signed distance along the
;                               ray to the point of closest approach in km.
;
; ALGORITHM:
;   The ray is parameterised as r(s) = spacecraft_position + s * unit_direction.
;   The closest approach occurs at s = -dot(spacecraft_position, unit_direction).
;   A positive s means the closest approach is in the forward (Sun) direction,
;   indicating a potential occultation geometry. The tangent point is then
;   r(s_min) and its geometry is computed via NSP_COMPUTE_GEOMETRY_FROM_POSITION.
;   Orthogonality of the tangent vector with the ray direction is verified
;   to within 1e-8 km as a numerical consistency check.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_compute_occultation_geometry, state_vector, spacecraft_to_sun_vector, tangent_point_vector=tangent_point_vector, tangent_longitude=tangent_longitude, tangent_latitude=tangent_latitude, tangent_radius=tangent_radius, tangent_altitude=tangent_altitude, occultation_valid=occultation_valid, closest_approach_distance=closest_approach_distance
  compile_opt strictarr

  if n_elements(state_vector) ne 6 then begin
    message, 'Step 8 occultation geometry failed: expected a 6-element spacecraft state vector.', /NONAME
  endif

  if n_elements(spacecraft_to_sun_vector) ne 3 then begin
    message, 'Step 8 occultation geometry failed: expected a 3-element spacecraft-to-Sun vector.', /NONAME
  endif

  state_values = double(state_vector)
  direction_values = double(spacecraft_to_sun_vector)

  if total(finite(state_values)) ne 6 then begin
    message, 'Step 8 occultation geometry failed: spacecraft state vector contains non-finite values.', /NONAME
  endif

  if total(finite(direction_values)) ne 3 then begin
    message, 'Step 8 occultation geometry failed: spacecraft-to-Sun vector contains non-finite values.', /NONAME
  endif

  spacecraft_position = state_values[0:2]
  sun_range = sqrt(total(direction_values * direction_values))
  if (~finite(sun_range)) or (sun_range le 0D) then begin
    message, 'Step 8 occultation geometry failed: spacecraft-to-Sun range must be finite and positive.', /NONAME
  endif

  ; Normalise the spacecraft-to-Sun vector to a unit direction.
  line_direction = direction_values / sun_range

  ; s_min = -dot(spacecraft_position, unit_direction): parameter along
  ; the ray at which the closest approach to the origin occurs.
  closest_approach_distance = -total(spacecraft_position * line_direction)

  if ~finite(closest_approach_distance) then begin
    message, 'Step 8 occultation geometry failed: closest-approach distance is non-finite.', /NONAME
  endif

  ; A non-positive s_min means the Sun is behind the spacecraft; flag
  ; as a non-occultation case and return NaN tangent-point outputs.
  if closest_approach_distance le 0D then begin
    occultation_valid = 0B
    tangent_point_vector = dblarr(3)
    tangent_point_vector[*] = !values.d_nan
    tangent_longitude = !values.d_nan
    tangent_latitude = !values.d_nan
    tangent_radius = !values.d_nan
    tangent_altitude = !values.d_nan
    return
  endif

  ; Tangent point: position on the ray at closest approach.
  tangent_point_vector = spacecraft_position + (closest_approach_distance * line_direction)
  if total(finite(tangent_point_vector)) ne 3 then begin
    message, 'Step 8 occultation geometry failed: tangent-point vector contains non-finite values.', /NONAME
  endif

  ; Verify orthogonality of the tangent vector with the ray direction
  ; as a numerical consistency check (tolerance 1e-8 km).
  orthogonality = abs(total(tangent_point_vector * line_direction))
  if orthogonality gt 1D-8 then begin
    message, 'Step 8 occultation geometry failed: tangent-point vector is not orthogonal to the line-of-sight direction at closest approach.', /NONAME
  endif

  nsp_compute_geometry_from_position, tangent_point_vector, longitude=tangent_longitude, latitude=tangent_latitude, radius=tangent_radius, altitude=tangent_altitude
  occultation_valid = 1B
end
