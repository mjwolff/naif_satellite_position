;+
; NAME:
;   NSP_GET_TGO_STATE_J2000
;
; PURPOSE:
;   Retrieves the ExoMars Trace Gas Orbiter (TGO) state vector in the
;   inertial J2000 frame at a given ephemeris time. Used by Step 9 to
;   derive osculating Keplerian elements, which require an inertial
;   frame rather than the rotating IAU_MARS frame used for geometry.
;
; CATEGORY:
;   NAIF Satellite Position / State Vectors
;
; CALLING SEQUENCE:
;   NSP_GET_TGO_STATE_J2000, et, STATE_VECTOR=state_vector $
;                            [, LIGHT_TIME=light_time]
;
; INPUTS:
;   et - DOUBLE scalar. Ephemeris time in seconds past J2000.
;
; OUTPUTS:
;   STATE_VECTOR - DOUBLE array[6]. Position (km) and velocity (km/s)
;                  of TGO relative to MARS in the J2000 inertial frame:
;                  [x, y, z, vx, vy, vz].
;   LIGHT_TIME   - DOUBLE scalar. One-way light time in seconds.
;
; NOTES:
;   Requires a loaded SPICE meta-kernel (furnished via NSP_LOAD_KERNELS).
;   The working directory is temporarily changed to the meta-kernel
;   directory before calling cspice_spkezr so that relative kernel
;   paths resolve correctly.
;   Frame: J2000. Observer: MARS. Target: TGO.
;   Aberration correction: NSP_STATE_VECTOR_ABCORR() (default 'NONE').
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_get_tgo_state_j2000, et, state_vector=state_vector, light_time=light_time
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 9 export failed: ET was not provided for J2000 state retrieval.', /NONAME
  endif

  et_value = double(et)
  if ~finite(et_value) then begin
    message, 'Step 9 export failed: ET must be finite for J2000 state retrieval.', /NONAME
  endif

  meta_kernel_path = nsp_loaded_meta_kernel_path()
  if strtrim(meta_kernel_path, 2) eq '' then begin
    message, 'Step 9 export failed: no loaded meta-kernel path is available. Run Step 3 kernel loading first.', /NONAME
  endif

  meta_kernel_directory = file_dirname(meta_kernel_path)
  if ~file_test(meta_kernel_directory, /DIRECTORY) then begin
    message, 'Step 9 export failed: loaded meta-kernel directory is not available: ' + meta_kernel_directory, /NONAME
  endif

  abcorr = nsp_state_vector_abcorr()
  cd, current=original_directory

  ; Temporarily change to the meta-kernel directory so that relative
  ; kernel paths inside the meta-kernel resolve correctly at runtime.
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    cd, original_directory
    message, 'Step 9 export failed: ' + !error_state.msg, /NONAME
  endif

  cd, meta_kernel_directory
  status = execute("cspice_spkezr, 'TGO', et_value, 'J2000', abcorr, 'MARS', state_vector, light_time")
  cd, original_directory

  catch, /cancel

  if status eq 0 then begin
    message, 'Step 9 export failed: cspice_spkezr did not complete successfully for the J2000 TGO state at ET=' + strtrim(et_value, 2), /NONAME
  endif

  if n_elements(state_vector) ne 6 then begin
    message, 'Step 9 export failed: expected a 6-element J2000 state vector.', /NONAME
  endif

  if total(finite(state_vector)) ne 6 then begin
    message, 'Step 9 export failed: J2000 state vector contains non-finite values.', /NONAME
  endif

  if ~finite(light_time) then begin
    message, 'Step 9 export failed: J2000 light time is non-finite.', /NONAME
  endif
end
