;+
; NAME:
;   NSP_GET_SUN_STATE
;
; PURPOSE:
;   Retrieves the state vector of the Sun relative to Mars in the
;   IAU_MARS rotating body-fixed frame at a given ephemeris time.
;   Used by Step 7 to compute solar geometry and by Step 8 to determine
;   the spacecraft-to-Sun direction for occultation calculations.
;
; CATEGORY:
;   NAIF Satellite Position / State Vectors
;
; CALLING SEQUENCE:
;   NSP_GET_SUN_STATE, et, SUN_STATE_VECTOR=sun_state_vector $
;                      [, LIGHT_TIME=light_time]
;
; INPUTS:
;   et - DOUBLE scalar. Ephemeris time in seconds past J2000.
;
; OUTPUTS:
;   SUN_STATE_VECTOR - DOUBLE array[6]. Position (km) and velocity
;                      (km/s) of the Sun relative to MARS in the
;                      IAU_MARS frame: [x, y, z, vx, vy, vz].
;   LIGHT_TIME       - DOUBLE scalar. One-way light time in seconds.
;
; NOTES:
;   Requires a loaded SPICE meta-kernel (furnished via NSP_LOAD_KERNELS).
;   The working directory is temporarily changed to the meta-kernel
;   directory before calling cspice_spkezr so that relative kernel
;   paths resolve correctly.
;   Frame: IAU_MARS. Observer: MARS. Target: SUN.
;   Aberration correction: NSP_SOLAR_GEOMETRY_ABCORR() (default 'NONE').
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_get_sun_state, et, sun_state_vector=sun_state_vector, light_time=light_time
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 7 solar geometry failed: ET was not provided.', /NONAME
  endif

  et_value = double(et)
  if ~finite(et_value) then begin
    message, 'Step 7 solar geometry failed: ET must be finite.', /NONAME
  endif

  meta_kernel_path = nsp_loaded_meta_kernel_path()
  if strtrim(meta_kernel_path, 2) eq '' then begin
    message, 'Step 7 solar geometry failed: no loaded meta-kernel path is available. Run Step 3 kernel loading first.', /NONAME
  endif

  meta_kernel_directory = file_dirname(meta_kernel_path)
  if ~file_test(meta_kernel_directory, /DIRECTORY) then begin
    message, 'Step 7 solar geometry failed: loaded meta-kernel directory is not available: ' + meta_kernel_directory, /NONAME
  endif

  abcorr = nsp_solar_geometry_abcorr()
  cd, current=original_directory

  ; Temporarily change to the meta-kernel directory so that relative
  ; kernel paths inside the meta-kernel resolve correctly at runtime.
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    cd, original_directory
    message, 'Step 7 solar geometry failed: ' + !error_state.msg, /NONAME
  endif

  cd, meta_kernel_directory
  status = execute("cspice_spkezr, 'SUN', et_value, 'IAU_MARS', abcorr, 'MARS', sun_state_vector, light_time")
  cd, original_directory

  catch, /cancel

  if status eq 0 then begin
    message, 'Step 7 solar geometry failed: cspice_spkezr did not complete successfully for the Sun at ET=' + strtrim(et_value, 2), /NONAME
  endif

  if n_elements(sun_state_vector) ne 6 then begin
    message, 'Step 7 solar geometry failed: expected a 6-element Sun state vector.', /NONAME
  endif

  if total(finite(sun_state_vector)) ne 6 then begin
    message, 'Step 7 solar geometry failed: Sun state vector contains non-finite values.', /NONAME
  endif

  if ~finite(light_time) then begin
    message, 'Step 7 solar geometry failed: Sun light time is non-finite.', /NONAME
  endif
end
