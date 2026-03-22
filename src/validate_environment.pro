pro validate_python_yaml_environment
  compile_opt strictarr

  spawn, 'python3 -c "import yaml"', result, EXIT_STATUS=exit_status

  if exit_status ne 0 then begin
    message, 'Step 1 environment validation failed: python3 with the yaml module is required. Install PyYAML for python3 before running repository validation workflows.', /NONAME
  endif
end


pro validate_environment
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

  validate_python_yaml_environment

  print, 'Step 1 environment validation passed.'
  print, 'KERNELS_PATH=' + kernels_path
  print, 'python3 yaml module=available'
end
