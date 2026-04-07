;+
; NAME:
;   NSP_GET_TGO_STATE
;
; PURPOSE:
;   Retrieves the ExoMars Trace Gas Orbiter (TGO) state vector in the
;   IAU_MARS rotating body-fixed frame at a given ephemeris time, using
;   the SPICE cspice_spkezr routine from the ICY DLM.
;
; CATEGORY:
;   NAIF Satellite Position / State Vectors
;
; CALLING SEQUENCE:
;   NSP_GET_TGO_STATE, et, STATE_VECTOR=state_vector [, LIGHT_TIME=light_time]
;
; INPUTS:
;   et - DOUBLE scalar. Ephemeris time in seconds past J2000.
;
; OUTPUTS:
;   STATE_VECTOR - DOUBLE array[6]. Position (km) and velocity (km/s)
;                  of TGO relative to MARS in the IAU_MARS frame:
;                  [x, y, z, vx, vy, vz].
;   LIGHT_TIME   - DOUBLE scalar. One-way light time in seconds between
;                  target and observer at the requested epoch.
;
; NOTES:
;   Requires a loaded SPICE meta-kernel (furnished via NSP_LOAD_KERNELS).
;   The working directory is temporarily changed to the meta-kernel
;   directory before calling cspice_spkezr so that any relative kernel
;   paths inside the meta-kernel resolve correctly.
;   Frame: IAU_MARS. Observer: MARS. Target: TGO.
;   Aberration correction: NSP_STATE_VECTOR_ABCORR() (default 'NONE').
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_get_tgo_state, et, state_vector=state_vector, light_time=light_time
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 5 state-vector retrieval failed: ET was not provided.', /NONAME
  endif

  et_value = double(et)
  if ~finite(et_value) then begin
    message, 'Step 5 state-vector retrieval failed: ET must be finite.', /NONAME
  endif

  meta_kernel_path = nsp_loaded_meta_kernel_path()
  if strtrim(meta_kernel_path, 2) eq '' then begin
    message, 'Step 5 state-vector retrieval failed: no loaded meta-kernel path is available. Run Step 3 kernel loading first.', /NONAME
  endif

  meta_kernel_directory = file_dirname(meta_kernel_path)
  if ~file_test(meta_kernel_directory, /DIRECTORY) then begin
    message, 'Step 5 state-vector retrieval failed: loaded meta-kernel directory is not available: ' + meta_kernel_directory, /NONAME
  endif

  abcorr = nsp_state_vector_abcorr()
  cd, current=original_directory

  ; Temporarily change to the meta-kernel directory so that relative
  ; kernel paths inside the meta-kernel resolve correctly at runtime.
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    cd, original_directory
    message, 'Step 5 state-vector retrieval failed: ' + !error_state.msg, /NONAME
  endif

  cd, meta_kernel_directory
  status = execute("cspice_spkezr, 'TGO', et_value, 'IAU_MARS', abcorr, 'MARS', state_vector, light_time")
  cd, original_directory

  catch, /cancel

  if status eq 0 then begin
    message, 'Step 5 state-vector retrieval failed: cspice_spkezr did not complete successfully for ET=' + strtrim(et_value, 2), /NONAME
  endif

  if n_elements(state_vector) ne 6 then begin
    message, 'Step 5 state-vector retrieval failed: expected a 6-element state vector.', /NONAME
  endif

  if total(finite(state_vector)) ne 6 then begin
    message, 'Step 5 state-vector retrieval failed: state vector contains non-finite values.', /NONAME
  endif

  if ~finite(light_time) then begin
    message, 'Step 5 state-vector retrieval failed: light time is non-finite.', /NONAME
  endif
end
