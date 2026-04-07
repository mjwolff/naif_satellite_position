;+
; NAME:
;   NSP_COMPUTE_GEOMETRY_FROM_STATE
;
; PURPOSE:
;   Extracts the position vector from a 6-element state vector and
;   computes planetocentric geometry by delegating to
;   NSP_COMPUTE_GEOMETRY_FROM_POSITION.
;
; CATEGORY:
;   NAIF Satellite Position / Geometry
;
; CALLING SEQUENCE:
;   NSP_COMPUTE_GEOMETRY_FROM_STATE, state_vector, $
;     LONGITUDE=longitude, LATITUDE=latitude, $
;     RADIUS=radius, ALTITUDE=altitude $
;     [, POSITION_VECTOR=position_vector]
;
; INPUTS:
;   state_vector - DOUBLE array[6]. Cartesian state [x, y, z, vx, vy, vz]
;                  in km and km/s in the IAU_MARS body-fixed frame.
;
; OUTPUTS:
;   LONGITUDE       - DOUBLE scalar. Planetocentric east longitude in radians.
;   LATITUDE        - DOUBLE scalar. Planetocentric latitude in radians.
;   RADIUS          - DOUBLE scalar. Distance from Mars centre in km.
;   ALTITUDE        - DOUBLE scalar. Height above Mars mean sphere in km.
;   POSITION_VECTOR - DOUBLE array[3]. The extracted [x, y, z] position in km.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_compute_geometry_from_state, state_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude, position_vector=position_vector
  compile_opt strictarr

  if n_elements(state_vector) ne 6 then begin
    message, 'Step 6 geometry conversion failed: expected a 6-element state vector.', /NONAME
  endif

  state_values = double(state_vector)
  if total(finite(state_values)) ne 6 then begin
    message, 'Step 6 geometry conversion failed: state vector contains non-finite values.', /NONAME
  endif

  position_vector = state_values[0:2]
  nsp_compute_geometry_from_position, position_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude
end
