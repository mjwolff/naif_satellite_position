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
