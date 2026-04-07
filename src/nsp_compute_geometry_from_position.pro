;+
; NAME:
;   NSP_COMPUTE_GEOMETRY_FROM_POSITION
;
; PURPOSE:
;   Converts a 3-element Cartesian position vector in the IAU_MARS frame
;   to planetocentric longitude, latitude, radius, and altitude above the
;   Mars mean sphere. Results are cross-validated against cspice_reclat.
;
; CATEGORY:
;   NAIF Satellite Position / Geometry
;
; CALLING SEQUENCE:
;   NSP_COMPUTE_GEOMETRY_FROM_POSITION, position_vector, $
;     LONGITUDE=longitude, LATITUDE=latitude, $
;     RADIUS=radius, ALTITUDE=altitude
;
; INPUTS:
;   position_vector - DOUBLE array[3]. Cartesian position [x, y, z] in
;                     kilometres in the IAU_MARS body-fixed frame.
;
; OUTPUTS:
;   LONGITUDE - DOUBLE scalar. Planetocentric east longitude in radians,
;               range [-pi, pi].
;   LATITUDE  - DOUBLE scalar. Planetocentric latitude in radians,
;               range [-pi/2, pi/2].
;   RADIUS    - DOUBLE scalar. Distance from the Mars centre in km.
;   ALTITUDE  - DOUBLE scalar. Height above the Mars mean sphere in km,
;               defined as RADIUS minus NSP_MARS_MEAN_RADIUS_KM().
;
; ALGORITHM:
;   Longitude = atan(y, x)
;   Latitude  = asin(z / radius)
;   Both values are independently confirmed against cspice_reclat to
;   within angular tolerance 1e-10 rad and radius tolerance 1e-6 km.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_compute_geometry_from_position, position_vector, longitude=longitude, latitude=latitude, radius=radius, altitude=altitude
  compile_opt strictarr

  if n_elements(position_vector) ne 3 then begin
    message, 'Step 6 geometry conversion failed: expected a 3-element position vector.', /NONAME
  endif

  position_values = double(position_vector)
  if total(finite(position_values)) ne 3 then begin
    message, 'Step 6 geometry conversion failed: position vector contains non-finite values.', /NONAME
  endif

  x = position_values[0]
  y = position_values[1]
  z = position_values[2]

  ; Spherical radius from Cartesian components.
  radius = sqrt(x * x + y * y + z * z)
  if (~finite(radius)) or (radius le 0D) then begin
    message, 'Step 6 geometry conversion failed: position radius must be finite and positive.', /NONAME
  endif

  ; Planetocentric longitude and latitude in radians.
  longitude = atan(y, x)
  latitude = asin(z / radius)

  ; Cross-validate against cspice_reclat; wrapped in EXECUTE so the
  ; call resolves even if the ICY DLM was loaded after compilation.
  status = execute("cspice_reclat, position_values, spice_radius, spice_longitude, spice_latitude")
  if status eq 0 then begin
    message, 'Step 6 geometry conversion failed: cspice_reclat did not complete successfully.', /NONAME
  endif

  if (~finite(spice_radius)) or (~finite(spice_longitude)) or (~finite(spice_latitude)) then begin
    message, 'Step 6 geometry conversion failed: cspice_reclat returned non-finite geometry values.', /NONAME
  endif

  ; Agreement tolerances: 1e-10 rad angular, 1e-6 km absolute radius.
  ; Longitude difference is wrapped to handle the -pi/+pi branch cut.
  angular_tolerance = 1D-10
  radius_absolute_tolerance = 1D-6
  radius_relative_tolerance = 1D-14
  radius_difference = abs(radius - spice_radius)
  allowed_radius_difference = radius_absolute_tolerance > (radius_relative_tolerance * abs(spice_radius))
  longitude_difference = abs(longitude - spice_longitude)
  if longitude_difference gt !dpi then longitude_difference = abs(longitude_difference - (2D * !dpi))
  latitude_difference = abs(latitude - spice_latitude)

  if radius_difference gt allowed_radius_difference then begin
    message, 'Step 6 geometry conversion failed: manual radius does not agree with cspice_reclat.', /NONAME
  endif

  if longitude_difference gt angular_tolerance then begin
    message, 'Step 6 geometry conversion failed: manual longitude does not agree with cspice_reclat.', /NONAME
  endif

  if latitude_difference gt angular_tolerance then begin
    message, 'Step 6 geometry conversion failed: manual latitude does not agree with cspice_reclat.', /NONAME
  endif

  if (latitude lt (-0.5D * !dpi)) or (latitude gt (0.5D * !dpi)) then begin
    message, 'Step 6 geometry conversion failed: latitude is outside the valid planetocentric range.', /NONAME
  endif

  if (longitude lt (-1D * !dpi)) or (longitude gt !dpi) then begin
    message, 'Step 6 geometry conversion failed: longitude is outside the valid planetocentric range.', /NONAME
  endif

  altitude = radius - nsp_mars_mean_radius_km()
  if ~finite(altitude) then begin
    message, 'Step 6 geometry conversion failed: altitude is non-finite.', /NONAME
  endif
end
