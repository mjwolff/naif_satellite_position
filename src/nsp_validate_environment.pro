;+
; NAME:
;   NSP_VALIDATE_IDL_YAML_ENVIRONMENT
;
; PURPOSE:
;   Verifies that the native IDL YAML_PARSE routine is available and
;   returns a well-formed YAML mapping for a minimal test document.
;   Called internally by NSP_VALIDATE_ENVIRONMENT (Step 1).
;
; CATEGORY:
;   NAIF Satellite Position / Environment Validation
;
; CALLING SEQUENCE:
;   NSP_VALIDATE_IDL_YAML_ENVIRONMENT
;
; INPUTS:
;   None
;
; OUTPUTS:
;   None. Raises an error if YAML_PARSE is unavailable or misbehaves.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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


;+
; NAME:
;   NSP_VALIDATE_ICY_ENVIRONMENT
;
; PURPOSE:
;   Verifies that the ICY DLM directory, descriptor file (icy.dlm), and
;   shared library (icy.so) all exist and are readable.
;   Called internally by NSP_VALIDATE_ENVIRONMENT (Step 1).
;
; CATEGORY:
;   NAIF Satellite Position / Environment Validation
;
; CALLING SEQUENCE:
;   NSP_VALIDATE_ICY_ENVIRONMENT [, ICY_DLM_PATH=icy_dlm_path]
;
; OPTIONAL KEYWORDS:
;   ICY_DLM_PATH - STRING. Override path to the ICY DLM directory.
;                  Resolved via NSP_RESOLVE_ICY_DLM_PATH if not supplied.
;
; OUTPUTS:
;   None. Raises an error if any required ICY component is missing or
;   unreadable.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
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


;+
; NAME:
;   NSP_VALIDATE_ENVIRONMENT
;
; PURPOSE:
;   Performs Step 1 of the NSP pipeline: validates that the KERNEL_PATH
;   environment variable points to a readable directory, that the IDL
;   YAML parser is available, and that the ICY DLM components are present
;   and readable.
;
; CATEGORY:
;   NAIF Satellite Position / Environment Validation
;
; CALLING SEQUENCE:
;   NSP_VALIDATE_ENVIRONMENT [, ICY_DLM_PATH=icy_dlm_path] [, /DEBUG]
;
; OPTIONAL KEYWORDS:
;   ICY_DLM_PATH - STRING. Override path to the ICY DLM directory.
;                  Resolved via NSP_RESOLVE_ICY_DLM_PATH if not supplied.
;   DEBUG        - When set, allows a hardcoded local KERNEL_PATH fallback
;                  if the environment variable is not set. For development
;                  use only.
;
; OUTPUTS:
;   None. Prints a validation summary on success. Raises an error and
;   halts execution on any validation failure.
;
; EXAMPLE:
;   NSP_VALIDATE_ENVIRONMENT
;   NSP_VALIDATE_ENVIRONMENT, ICY_DLM_PATH='/usr/local/lib/icy'
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_validate_environment, icy_dlm_path=icy_dlm_path, debug=debug
  compile_opt strictarr

  kernels_path = strtrim(getenv('KERNEL_PATH'), 2)
  if (kernels_path eq '') and keyword_set(debug) then begin
    ; Debug mode allows local validation without requiring the environment variable.
    kernels_path = '/Volumes/Wolff_misc1/nomad_naif/tgo_kernels/'
  endif

  if kernels_path eq '' then begin
    message, 'Step 1 environment validation failed: KERNEL_PATH is not set. Define KERNEL_PATH to the local SPICE kernel root directory before running the pipeline.', /NONAME
  endif

  if ~file_test(kernels_path, /DIRECTORY) then begin
    message, 'Step 1 environment validation failed: KERNEL_PATH does not point to an existing directory: ' + kernels_path, /NONAME
  endif

  if ~file_test(kernels_path, /READ) then begin
    message, 'Step 1 environment validation failed: KERNEL_PATH is not readable: ' + kernels_path, /NONAME
  endif

  nsp_validate_idl_yaml_environment
  nsp_validate_icy_environment, icy_dlm_path=icy_dlm_path

  print, 'Step 1 environment validation passed.'
  print, 'KERNEL_PATH=' + kernels_path
  print, 'IDL YAML parser=available'
  print, 'ICY DLM directory=' + nsp_resolve_icy_dlm_path(icy_dlm_path=icy_dlm_path)
end
