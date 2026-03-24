pro nsp_validate_idl_yaml_environment
  compile_opt strictarr

  catch, error_status
  if error_status ne 0 then begin
    error_message = !ERROR_STATE.MSG
    catch, /cancel
    message, 'Step 1 environment validation failed: the native IDL YAML parser is not available. ' + error_message, /NONAME
  endif

  yaml_document = yaml_parse('cases: []')
  catch, /cancel

  if ~obj_isa(yaml_document, 'YAML_MAP') then begin
    message, 'Step 1 environment validation failed: the native IDL YAML parser did not return a YAML mapping for a basic YAML document.', /NONAME
  endif
end


pro nsp_validate_icy_environment, icy_dlm_path=icy_dlm_path
  compile_opt strictarr

  icy_dlm_directory = nsp_resolve_icy_dlm_path(icy_dlm_path=icy_dlm_path)
  icy_dlm_file = icy_dlm_directory + '/icy.dlm'
  icy_shared_library = icy_dlm_directory + '/icy.so'

  if ~file_test(icy_dlm_directory, /DIRECTORY) then begin
    message, 'Step 1 environment validation failed: ICY DLM directory was not found: ' + icy_dlm_directory, /NONAME
  endif

  if ~file_test(icy_dlm_directory, /READ) then begin
    message, 'Step 1 environment validation failed: ICY DLM directory is not readable: ' + icy_dlm_directory, /NONAME
  endif

  if ~file_test(icy_dlm_file, /REGULAR) then begin
    message, 'Step 1 environment validation failed: ICY DLM descriptor was not found: ' + icy_dlm_file, /NONAME
  endif

  if ~file_test(icy_dlm_file, /READ) then begin
    message, 'Step 1 environment validation failed: ICY DLM descriptor is not readable: ' + icy_dlm_file, /NONAME
  endif

  if ~file_test(icy_shared_library, /REGULAR) then begin
    message, 'Step 1 environment validation failed: ICY shared library was not found: ' + icy_shared_library, /NONAME
  endif

  if ~file_test(icy_shared_library, /READ) then begin
    message, 'Step 1 environment validation failed: ICY shared library is not readable: ' + icy_shared_library, /NONAME
  endif
end


pro nsp_validate_environment, icy_dlm_path=icy_dlm_path
  compile_opt strictarr

  kernels_path = strtrim(getenv('KERNELS_PATH'), 2)

  if kernels_path eq '' then begin
    message, 'Step 1 environment validation failed: KERNELS_PATH is not set. Define KERNELS_PATH to the local SPICE kernel root directory before running the pipeline.', /NONAME
  endif

  if ~file_test(kernels_path, /DIRECTORY) then begin
    message, 'Step 1 environment validation failed: KERNELS_PATH does not point to an existing directory: ' + kernels_path, /NONAME
  endif

  if ~file_test(kernels_path, /READ) then begin
    message, 'Step 1 environment validation failed: KERNELS_PATH is not readable: ' + kernels_path, /NONAME
  endif

  nsp_validate_idl_yaml_environment
  nsp_validate_icy_environment, icy_dlm_path=icy_dlm_path

  print, 'Step 1 environment validation passed.'
  print, 'KERNELS_PATH=' + kernels_path
  print, 'IDL YAML parser=available'
  print, 'ICY DLM directory=' + nsp_resolve_icy_dlm_path(icy_dlm_path=icy_dlm_path)
end
