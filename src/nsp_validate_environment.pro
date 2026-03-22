function nsp_validation_icy_dlm_directory
  compile_opt strictarr

  return, '/Users/mwolff/lib/Darwin_arm64'
end


pro nsp_validate_python_yaml_environment
  compile_opt strictarr

  spawn, 'python3 -c "import yaml"', result, EXIT_STATUS=exit_status

  if exit_status ne 0 then begin
    message, 'Step 1 environment validation failed: python3 with the yaml module is required. Install PyYAML for python3 before running repository validation workflows.', /NONAME
  endif
end


pro nsp_validate_icy_environment
  compile_opt strictarr

  icy_dlm_directory = nsp_validation_icy_dlm_directory()
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


pro nsp_validate_environment
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

  nsp_validate_python_yaml_environment
  nsp_validate_icy_environment

  print, 'Step 1 environment validation passed.'
  print, 'KERNELS_PATH=' + kernels_path
  print, 'python3 yaml module=available'
  print, 'ICY DLM directory=' + nsp_validation_icy_dlm_directory()
end
