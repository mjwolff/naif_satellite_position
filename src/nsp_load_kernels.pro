;+
; NAME:
;   NSP_INITIALIZE_ICY_RUNTIME
;
; PURPOSE:
;   Prepends the ICY DLM directory to !DLM_PATH (if not already present)
;   and verifies that the ICY runtime can be exercised by calling
;   cspice_ktotal via EXECUTE.  Raises a fatal error if the DLM files
;   are missing or the runtime cannot be initialised.
;   Called internally by NSP_LOAD_KERNELS (Step 3).
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Loading
;
; CALLING SEQUENCE:
;   NSP_INITIALIZE_ICY_RUNTIME [, ICY_DLM_PATH=icy_dlm_path]
;
; OPTIONAL KEYWORDS:
;   ICY_DLM_PATH - STRING. Override path to the ICY DLM directory.
;                  Resolved via NSP_RESOLVE_ICY_DLM_PATH if not supplied.
;
; OUTPUTS:
;   None. Modifies !DLM_PATH as a side effect. Raises an error on failure.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_initialize_icy_runtime, icy_dlm_path=icy_dlm_path
  compile_opt strictarr

  icy_dlm_directory = nsp_resolve_icy_dlm_path(icy_dlm_path=icy_dlm_path)
  icy_dlm_file = icy_dlm_directory + '/icy.dlm'
  icy_shared_library = icy_dlm_directory + '/icy.so'

  ; Use colon-wrapped substrings to avoid false partial-directory matches.
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

  ; Prepend the ICY directory to !DLM_PATH so IDL can locate icy.dlm.
  if strpos(dlm_path_with_separators, icy_path_with_separators) lt 0 then begin
    !DLM_PATH = icy_dlm_directory + ':' + !DLM_PATH
  endif

  ; Probe the runtime: cspice_ktotal is lightweight and requires no loaded kernels.
  status = execute("cspice_ktotal, 'ALL', kernel_count")

  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: unable to initialize the ICY runtime from !DLM_PATH=' + !DLM_PATH, /NONAME
  endif
end


;+
; NAME:
;   NSP_SPICE_KCLEAR_CHECKED
;
; PURPOSE:
;   Calls cspice_kclear via EXECUTE to unload all kernels from the SPICE
;   kernel pool.  Raises a fatal error if the call fails.
;   Called internally by NSP_LOAD_KERNELS (Step 3).
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Loading
;
; CALLING SEQUENCE:
;   NSP_SPICE_KCLEAR_CHECKED
;
; INPUTS:
;   None
;
; OUTPUTS:
;   None. Clears the SPICE kernel pool as a side effect.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_spice_kclear_checked
  compile_opt strictarr

  ; Wrapped in EXECUTE so the call resolves correctly even if the ICY DLM
  ; was loaded after this routine was compiled.
  status = execute('cspice_kclear')
  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: unable to clear the SPICE kernel pool with cspice_kclear.', /NONAME
  endif
end


;+
; NAME:
;   NSP_SPICE_FURNSH_CHECKED
;
; PURPOSE:
;   Calls cspice_furnsh via EXECUTE to load a SPICE meta-kernel into the
;   kernel pool.  Raises a fatal error if the call fails.
;   Called internally by NSP_LOAD_KERNELS (Step 3).
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Loading
;
; CALLING SEQUENCE:
;   NSP_SPICE_FURNSH_CHECKED, meta_kernel_path
;
; INPUTS:
;   meta_kernel_path - STRING. Absolute path to the SPICE meta-kernel file.
;
; OUTPUTS:
;   None. Loads kernels into the SPICE pool as a side effect.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_spice_furnsh_checked, meta_kernel_path
  compile_opt strictarr

  command = 'cspice_furnsh, meta_kernel_path'
  status = execute(command)
  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: cspice_furnsh did not complete successfully for ' + meta_kernel_path, /NONAME
  endif
end


;+
; NAME:
;   NSP_SPICE_KTOTAL_CHECKED
;
; PURPOSE:
;   Calls cspice_ktotal via EXECUTE to query the total number of loaded
;   SPICE kernels.  Raises a fatal error if the call fails.
;   Called internally by NSP_LOAD_KERNELS and NSP_IS_LOADED_META_KERNEL.
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Loading
;
; CALLING SEQUENCE:
;   NSP_SPICE_KTOTAL_CHECKED, kernel_count
;
; INPUTS:
;   None
;
; OUTPUTS:
;   kernel_count - LONG scalar. Total number of kernels currently registered
;                  in the SPICE kernel pool.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_spice_ktotal_checked, kernel_count
  compile_opt strictarr

  status = execute("cspice_ktotal, 'ALL', kernel_count")
  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: unable to query the SPICE kernel registry with cspice_ktotal.', /NONAME
  endif
end


;+
; NAME:
;   NSP_SPICE_KDATA_CHECKED
;
; PURPOSE:
;   Calls cspice_kdata via EXECUTE to retrieve metadata for a single loaded
;   kernel by its index.  Raises a fatal error if the call fails.
;   Called internally by NSP_IS_LOADED_META_KERNEL.
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Loading
;
; CALLING SEQUENCE:
;   NSP_SPICE_KDATA_CHECKED, kernel_index, file, kernel_type, $
;     source_file, handle, found
;
; INPUTS:
;   kernel_index - LONG scalar. Zero-based index into the loaded-kernel list.
;
; OUTPUTS:
;   file        - STRING. Filename of the loaded kernel.
;   kernel_type - STRING. Kernel type string (e.g., 'META', 'SPK', 'CK').
;   source_file - STRING. Meta-kernel that furnished this kernel, if any.
;   handle      - LONG scalar. SPICE handle for the kernel.
;   found       - BYTE scalar. 1 if the kernel at kernel_index was found.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_spice_kdata_checked, kernel_index, file, kernel_type, source_file, handle, found
  compile_opt strictarr

  status = execute("cspice_kdata, kernel_index, 'ALL', file, kernel_type, source_file, handle, found")
  if status eq 0 then begin
    message, 'Step 3 kernel loading failed: unable to inspect loaded kernel index ' + strtrim(kernel_index, 2) + ' with cspice_kdata.', /NONAME
  endif
end


;+
; NAME:
;   NSP_IS_LOADED_META_KERNEL
;
; PURPOSE:
;   Determines whether a specific meta-kernel file is currently registered
;   in the SPICE kernel pool.  Iterates over all loaded kernels and checks
;   for a TYPE='META' entry whose filename matches resolved_meta_kernel.
;   Called internally by NSP_LOAD_KERNELS (Step 3).
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Loading
;
; CALLING SEQUENCE:
;   result = NSP_IS_LOADED_META_KERNEL(resolved_meta_kernel)
;
; INPUTS:
;   resolved_meta_kernel - STRING. Absolute path to the meta-kernel file
;                          to search for in the kernel pool.
;
; OUTPUTS:
;   BYTE scalar. 1 if the meta-kernel is loaded; 0 otherwise.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_is_loaded_meta_kernel, resolved_meta_kernel
  compile_opt strictarr

  nsp_spice_ktotal_checked, kernel_count

  ; No kernels loaded at all.
  if kernel_count le 0 then return, 0B

  ; Search for an entry whose filename and type both match.
  for kernel_index = 0L, kernel_count - 1L do begin
    nsp_spice_kdata_checked, kernel_index, file, kernel_type, source_file, handle, found
    if found then begin
      if (file eq resolved_meta_kernel) and (kernel_type eq 'META') then return, 1B
    endif
  endfor

  return, 0B
end


;+
; NAME:
;   NSP_LOAD_KERNELS
;
; PURPOSE:
;   Performs Step 3 of the NSP pipeline: initialises the ICY runtime,
;   clears the SPICE kernel pool, loads the resolved meta-kernel, and
;   verifies the resulting pool state.
;
;   The working directory is temporarily changed to the meta-kernel's
;   directory before calling cspice_furnsh.  This is necessary because
;   SPICE meta-kernels use PATH_VALUES that are relative to the directory
;   in which the meta-kernel resides.  The original directory is restored
;   on both success and failure.
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Loading
;
; CALLING SEQUENCE:
;   NSP_LOAD_KERNELS, resolved_meta_kernel $
;     [, KERNEL_COUNT=kernel_count] $
;     [, ICY_DLM_PATH=icy_dlm_path]
;
; INPUTS:
;   resolved_meta_kernel - STRING. Absolute path to the SPICE meta-kernel
;                          as returned by NSP_RESOLVE_KERNELS.
;
; OPTIONAL KEYWORDS:
;   KERNEL_COUNT  - Output. LONG scalar. Number of kernels loaded into the
;                   SPICE pool after a successful furnsh call.
;   ICY_DLM_PATH  - STRING. Override path to the ICY DLM directory.
;
; OUTPUTS:
;   KERNEL_COUNT keyword set on success.
;   Prints a loading summary. Raises an error on any failure.
;
; EXAMPLE:
;   NSP_RESOLVE_KERNELS, RESOLVED_META_KERNEL=mk
;   NSP_LOAD_KERNELS, mk, KERNEL_COUNT=n
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_load_kernels, resolved_meta_kernel, kernel_count=kernel_count, icy_dlm_path=icy_dlm_path
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

  ; Save the current directory; it will be restored after cspice_furnsh.
  meta_kernel_directory = file_dirname(meta_kernel_path)
  cd, current=original_directory

  ; Catch handler: restore the original directory and re-raise on any error.
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    cd, original_directory
    dummy_meta_kernel_path = nsp_loaded_meta_kernel_path(/clear)
    message, 'Step 3 kernel loading failed: ' + !error_state.msg, /NONAME
  endif

  ; Clear any stale kernel-pool state before loading.
  dummy_meta_kernel_path = nsp_loaded_meta_kernel_path(/clear)
  nsp_initialize_icy_runtime, icy_dlm_path=icy_dlm_path
  nsp_spice_kclear_checked

  ; CD to the meta-kernel directory so that relative PATH_VALUES resolve correctly.
  cd, meta_kernel_directory
  nsp_spice_furnsh_checked, meta_kernel_path
  nsp_spice_ktotal_checked, kernel_count
  cd, original_directory

  if kernel_count le 0 then begin
    message, 'Step 3 kernel loading failed: cspice_furnsh completed but no kernels are registered in the SPICE kernel pool.', /NONAME
  endif

  if ~nsp_is_loaded_meta_kernel(meta_kernel_path) then begin
    message, 'Step 3 kernel loading failed: the resolved meta-kernel is not present in the loaded kernel registry: ' + meta_kernel_path, /NONAME
  endif

  ; Record the successfully loaded meta-kernel path for downstream consumers.
  meta_kernel_state = nsp_loaded_meta_kernel_path(set_value=meta_kernel_path)
  catch, /cancel

  print, 'Step 3 kernel loading passed.'
  print, 'Loaded meta-kernel=' + meta_kernel_state
  print, 'Loaded kernel count=' + strtrim(kernel_count, 2)
end
