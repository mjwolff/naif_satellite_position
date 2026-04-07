;+
; NAME:
;   NSP_LOADED_META_KERNEL_PATH
;
; PURPOSE:
;   Gets or sets the resolved meta-kernel path held in the pipeline
;   common block. Acts as a single shared register so that any pipeline
;   step can confirm which meta-kernel is currently furnished without
;   re-querying the SPICE kernel pool.
;
; CATEGORY:
;   NAIF Satellite Position / Pipeline State
;
; CALLING SEQUENCE:
;   path = NSP_LOADED_META_KERNEL_PATH()
;   NSP_LOADED_META_KERNEL_PATH, SET_VALUE=path
;   NSP_LOADED_META_KERNEL_PATH, /CLEAR
;
; INPUTS:
;   None
;
; OPTIONAL KEYWORDS:
;   SET_VALUE - STRING. When present, stores this path in the common
;               block, overwriting any previously stored value.
;   CLEAR     - When set, resets the stored path to an empty string.
;
; OUTPUTS:
;   Result - Scalar STRING. The currently stored meta-kernel path, or
;            an empty string if none has been set.
;
; NOTES:
;   State is held in the IDL COMMON block NSP_PIPELINE_STATE_COMMON and
;   persists for the lifetime of the IDL session. CLEAR should be called
;   if kernels are unloaded or a different meta-kernel is furnished.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_loaded_meta_kernel_path, set_value=set_value, clear=clear
  compile_opt strictarr

  common nsp_pipeline_state_common, stored_meta_kernel_path

  if keyword_set(clear) then begin
    stored_meta_kernel_path = ''
  endif

  if arg_present(set_value) then begin
    stored_meta_kernel_path = strtrim(set_value, 2)
  endif

  ; Initialise on first call before any value has been stored.
  if n_elements(stored_meta_kernel_path) eq 0 then stored_meta_kernel_path = ''

  return, stored_meta_kernel_path
end
