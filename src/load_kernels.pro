function pipeline_icy_dlm_directory
  compile_opt strictarr

  return, '/Users/mwolff/lib/Darwin_arm64'
end


pro initialize_icy_runtime
  compile_opt strictarr

  icy_dlm_directory = pipeline_icy_dlm_directory()
  icy_dlm_file = icy_dlm_directory + '/icy.dlm'
  icy_shared_library = icy_dlm_directory + '/icy.so'
  dlm_path_with_separators = ':' + !DLM_PATH + ':'
  icy_path_with_separators = ':' + icy_dlm_directory + ':'

  if ~file_test(icy_dlm_directory, /DIRECTORY) then begin
    message, 'Step 3 kernel loading failed: ICY DLM directory was not found: ' + icy_dlm_directory, /NONAME
  endif

  if ~file_test(icy_dlm_file, /REGULAR) then begin
    message, 'Step 3 kernel loading failed: ICY DLM descriptor was not found: ' + icy_dlm_file, /NONAME
  endif

  if ~file_test(icy_shared_library, /REGULAR) then begin
    message, 'Step 3 kernel loading failed: ICY shared library was not found: ' + icy_shared_library, /NONAME
  endif

  if ~file_test(icy_dlm_file, /READ) then begin
    message, 'Step 3 kernel loading failed: ICY DLM descriptor is not readable: ' + icy_dlm_file, /NONAME
  endif

  if ~file_test(icy_shared_library, /READ) then begin
    message, 'Step 3 kernel loading failed: ICY shared library is not readable: ' + icy_shared_library, /NONAME
  endif

  if strpos(dlm_path_with_separators, icy_path_with_separators) lt 0 then begin
    !DLM_PATH = icy_dlm_directory + ':' + !DLM_PATH
  endif

  ; Trigger DLM loading before kernel operations so failures happen here.
  status = execute("cspice_ktotal, 'ALL', kernel_count")

  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: unable to initialize the ICY runtime from !DLM_PATH=' + !DLM_PATH, /NONAME
  endif
end


pro spice_kclear_checked
  compile_opt strictarr

  status = execute('cspice_kclear')
  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: unable to clear the SPICE kernel pool with cspice_kclear.', /NONAME
  endif
end


pro spice_furnsh_checked, meta_kernel_path
  compile_opt strictarr

  command = 'cspice_furnsh, meta_kernel_path'
  status = execute(command)
  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: cspice_furnsh did not complete successfully for ' + meta_kernel_path, /NONAME
  endif
end


pro spice_ktotal_checked, kernel_count
  compile_opt strictarr

  status = execute("cspice_ktotal, 'ALL', kernel_count")
  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: unable to query the SPICE kernel registry with cspice_ktotal.', /NONAME
  endif
end


pro spice_kdata_checked, kernel_index, file, kernel_type, source_file, handle, found
  compile_opt strictarr

  status = execute("cspice_kdata, kernel_index, 'ALL', file, kernel_type, source_file, handle, found")
  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: unable to inspect loaded kernel index ' + strtrim(kernel_index, 2) + ' with cspice_kdata.', /NONAME
  endif
end


function is_loaded_meta_kernel, resolved_meta_kernel
  compile_opt strictarr

  spice_ktotal_checked, kernel_count

  if kernel_count le 0 then return, 0B

  for kernel_index = 0L, kernel_count - 1L do begin
    spice_kdata_checked, kernel_index, file, kernel_type, source_file, handle, found
    if found then begin
      if (file eq resolved_meta_kernel) and (kernel_type eq 'META') then return, 1B
    endif
  endfor

  return, 0B
end


pro load_kernels, resolved_meta_kernel, kernel_count=kernel_count
  compile_opt strictarr

  if n_elements(resolved_meta_kernel) eq 0 then begin
    message, 'Step 3 kernel loading failed: resolved_meta_kernel was not provided.', /NONAME
  endif

  meta_kernel_path = strtrim(resolved_meta_kernel, 2)
  if meta_kernel_path eq '' then begin
    message, 'Step 3 kernel loading failed: resolved_meta_kernel is empty.', /NONAME
  endif

  if ~file_test(meta_kernel_path, /REGULAR) then begin
    message, 'Step 3 kernel loading failed: resolved meta-kernel does not exist: ' + meta_kernel_path, /NONAME
  endif

  if ~file_test(meta_kernel_path, /READ) then begin
    message, 'Step 3 kernel loading failed: resolved meta-kernel is not readable: ' + meta_kernel_path, /NONAME
  endif

  meta_kernel_directory = file_dirname(meta_kernel_path)
  cd, current=original_directory

  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    cd, original_directory
    message, 'Step 3 kernel loading failed: ' + !error_state.msg, /NONAME
  endif

  initialize_icy_runtime

  ; Clear prior kernel state so the load count reflects this step only.
  spice_kclear_checked

  ; Meta-kernels with relative PATH_VALUES resolve from the current directory.
  cd, meta_kernel_directory
  spice_furnsh_checked, meta_kernel_path
  spice_ktotal_checked, kernel_count
  cd, original_directory

  if kernel_count le 0 then begin
    message, 'Step 3 kernel loading failed: cspice_furnsh completed but no kernels are registered in the SPICE kernel pool.', /NONAME
  endif

  if ~is_loaded_meta_kernel(meta_kernel_path) then begin
    message, 'Step 3 kernel loading failed: the resolved meta-kernel is not present in the loaded kernel registry: ' + meta_kernel_path, /NONAME
  endif

  catch, /cancel

  print, 'Step 3 kernel loading passed.'
  print, 'Loaded meta-kernel=' + meta_kernel_path
  print, 'Loaded kernel count=' + strtrim(kernel_count, 2)
end
