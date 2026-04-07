;+
; NAME:
;   NSP_DEFAULT_ICY_DLM_PATH
;
; PURPOSE:
;   Returns the built-in default directory for the ICY DLM.  Used as
;   the last-resort fallback when neither the ICY_DLM_PATH keyword nor
;   the NSP_ICY_DLM_PATH environment variable is set.
;   Called internally by NSP_RESOLVE_ICY_DLM_PATH.
;
; CATEGORY:
;   NAIF Satellite Position / Environment
;
; CALLING SEQUENCE:
;   result = NSP_DEFAULT_ICY_DLM_PATH()
;
; INPUTS:
;   None
;
; OUTPUTS:
;   STRING scalar. Absolute path to the default ICY DLM directory.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_default_icy_dlm_path
  compile_opt strictarr

  return, '/Users/mwolff/lib/Darwin_arm64'
end


;+
; NAME:
;   NSP_RESOLVE_ICY_DLM_PATH
;
; PURPOSE:
;   Determines the ICY DLM directory through a three-level priority chain:
;     1. ICY_DLM_PATH keyword (caller-supplied override)
;     2. NSP_ICY_DLM_PATH environment variable
;     3. NSP_DEFAULT_ICY_DLM_PATH built-in default
;   Returns the first non-empty value found.
;
; CATEGORY:
;   NAIF Satellite Position / Environment
;
; CALLING SEQUENCE:
;   result = NSP_RESOLVE_ICY_DLM_PATH([ICY_DLM_PATH=icy_dlm_path])
;
; OPTIONAL KEYWORDS:
;   ICY_DLM_PATH - STRING. Caller-supplied override path.  When provided
;                  and non-empty, all other resolution steps are skipped.
;
; OUTPUTS:
;   STRING scalar. Resolved absolute path to the ICY DLM directory.
;
; EXAMPLE:
;   path = NSP_RESOLVE_ICY_DLM_PATH()
;   path = NSP_RESOLVE_ICY_DLM_PATH(ICY_DLM_PATH='/usr/local/lib/icy')
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_resolve_icy_dlm_path, icy_dlm_path=icy_dlm_path
  compile_opt strictarr

  resolved_path = ''

  ; Priority 1: caller-supplied keyword.
  if n_elements(icy_dlm_path) gt 0 then begin
    if strtrim(icy_dlm_path, 2) ne '' then resolved_path = strtrim(icy_dlm_path, 2)
  endif

  ; Priority 2: NSP_ICY_DLM_PATH environment variable.
  if resolved_path eq '' then begin
    resolved_path = strtrim(getenv('ICY_DLM_PATH'), 2)
  endif

  ; Priority 3: built-in default path.
  if resolved_path eq '' then begin
    resolved_path = nsp_default_icy_dlm_path()
  endif

  return, resolved_path
end
