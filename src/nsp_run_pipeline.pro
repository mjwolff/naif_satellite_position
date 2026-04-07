;+
; NAME:
;   NSP_RUN_PIPELINE
;
; PURPOSE:
;   Runs Steps 1–3 of the NSP pipeline in sequence: environment validation,
;   kernel resolution, and kernel loading.  After this procedure returns,
;   the SPICE kernel pool is populated and all NSP computation routines
;   (Steps 4–11) are ready to use.
;
;   NSP_RUN_PIPELINE is also called internally by NSP_RUN_BATCH and
;   NSP_ET_TO_UTC (auto-load path) to ensure the pipeline is initialised
;   before any SPICE call is attempted.
;
; CATEGORY:
;   NAIF Satellite Position / Pipeline
;
; CALLING SEQUENCE:
;   NSP_RUN_PIPELINE $
;     [, META_KERNEL_NAME=meta_kernel_name] $
;     [, ICY_DLM_PATH=icy_dlm_path] $
;     [, /DEBUG]
;
; OPTIONAL KEYWORDS:
;   META_KERNEL_NAME - STRING. Override for the meta-kernel filename.
;                      Default: 'em16_ops.tm'. Passed to NSP_RESOLVE_KERNELS.
;   ICY_DLM_PATH     - STRING. Override path to the ICY DLM directory.
;                      Passed to NSP_VALIDATE_ENVIRONMENT and NSP_LOAD_KERNELS.
;   DEBUG            - When set, allows a hardcoded local KERNEL_PATH fallback
;                      if the KERNEL_PATH environment variable is not set.
;                      For development use only.
;
; OUTPUTS:
;   None. Side effects: SPICE kernel pool loaded, ICY DLM initialised.
;   Prints a step-by-step validation summary. Raises an error on any failure.
;
; EXAMPLE:
;   NSP_RUN_PIPELINE
;   NSP_RUN_PIPELINE, META_KERNEL_NAME='custom.tm', /DEBUG
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_run_pipeline, meta_kernel_name=meta_kernel_name, icy_dlm_path=icy_dlm_path, debug=debug
  compile_opt strictarr

  ; Read KERNEL_PATH once so it can be forwarded to both Step 1 and Step 2.
  kernel_path_value = strtrim(getenv('KERNEL_PATH'), 2)
  if (kernel_path_value eq '') and keyword_set(debug) then begin
    kernel_path_value = '/Volumes/Wolff_misc1/nomad_naif/tgo_kernels/'
  endif

  nsp_validate_environment, icy_dlm_path=icy_dlm_path, debug=debug
  nsp_resolve_kernels, meta_kernel_name=meta_kernel_name, kernel_path=kernel_path_value, resolved_meta_kernel=resolved_meta_kernel
  nsp_load_kernels, resolved_meta_kernel, kernel_count=kernel_count, icy_dlm_path=icy_dlm_path
end
