;+
; NAME:
;   NSP_RESOLVE_RELATIVE_META_KERNEL
;
; PURPOSE:
;   Resolves a meta-kernel given as a relative path (containing a '/')
;   beneath KERNEL_PATH.  Verifies that the file exists and is readable.
;   Called internally by NSP_RESOLVE_META_KERNEL.
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Resolution
;
; CALLING SEQUENCE:
;   result = NSP_RESOLVE_RELATIVE_META_KERNEL(kernels_path, relative_name)
;
; INPUTS:
;   kernels_path  - STRING. Absolute path to the SPICE kernel root directory.
;   relative_name - STRING. Relative path of the meta-kernel beneath
;                   kernels_path (must contain at least one '/').
;
; OUTPUTS:
;   STRING scalar. Fully expanded, readable path to the meta-kernel file.
;   Raises an error if the file is absent or unreadable.
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_resolve_relative_meta_kernel, kernels_path, relative_name
  compile_opt strictarr

  candidate_path = file_expand_path(kernels_path + '/' + relative_name)

  if ~file_test(candidate_path, /REGULAR) then begin
    message, 'Step 2 kernel resolution failed: specified meta-kernel was not found beneath KERNEL_PATH: ' + candidate_path, /NONAME
  endif

  if ~file_test(candidate_path, /READ) then begin
    message, 'Step 2 kernel resolution failed: specified meta-kernel is not readable: ' + candidate_path, /NONAME
  endif

  return, candidate_path
end


;+
; NAME:
;   NSP_RESOLVE_META_KERNEL
;
; PURPOSE:
;   Locates the SPICE meta-kernel file beneath the kernel root directory.
;   Applies the following search strategy:
;     - If meta_kernel_name contains '/', treat it as a relative path and
;       delegate to NSP_RESOLVE_RELATIVE_META_KERNEL.
;     - Otherwise, search <KERNEL_PATH>/<name> and <KERNEL_PATH>/mk/<name>
;       in order; fail if neither or both locations match.
;   Rejects absolute paths and names containing '..'.
;   Called internally by NSP_RESOLVE_KERNELS.
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Resolution
;
; CALLING SEQUENCE:
;   result = NSP_RESOLVE_META_KERNEL([META_KERNEL_NAME=name] $
;                                    [, KERNEL_PATH=path])
;
; OPTIONAL KEYWORDS:
;   META_KERNEL_NAME - STRING. Meta-kernel filename or relative path.
;                      Default: 'em16_ops.tm'.
;   KERNEL_PATH      - STRING. Override for the KERNEL_PATH environment
;                      variable.  The environment variable is used if this
;                      keyword is absent or empty.
;
; OUTPUTS:
;   STRING scalar. Fully expanded, readable path to the resolved meta-kernel.
;   Raises an error on any resolution failure (not found, ambiguous, unreadable).
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
function nsp_resolve_meta_kernel, meta_kernel_name=meta_kernel_name, kernel_path=kernel_path
  compile_opt strictarr

  ; Determine the kernel root: prefer keyword, then environment variable.
  kernels_path = ''
  if n_elements(kernel_path) gt 0 then begin
    kernels_path = strtrim(kernel_path, 2)
  endif else begin
    kernels_path = strtrim(getenv('KERNEL_PATH'), 2)
  endelse

  if kernels_path eq '' then begin
    message, 'Step 2 kernel resolution failed: KERNEL_PATH is not set. Run environment validation before kernel resolution.', /NONAME
  endif

  ; Default meta-kernel name when not supplied by the caller.
  selected_name = 'em16_ops.tm'
  if n_elements(meta_kernel_name) gt 0 then begin
    if strtrim(meta_kernel_name, 2) ne '' then selected_name = strtrim(meta_kernel_name, 2)
  endif

  ; Reject path traversal sequences.
  if strpos(selected_name, '..') ge 0 then begin
    message, 'Step 2 kernel resolution failed: meta-kernel name must not contain "..": ' + selected_name, /NONAME
  endif

  ; Reject absolute paths; all resolution must be relative to KERNEL_PATH.
  if strmid(selected_name, 0, 1) eq '/' then begin
    message, 'Step 2 kernel resolution failed: meta-kernel must be resolved from KERNEL_PATH, not from an absolute path: ' + selected_name, /NONAME
  endif

  ; Relative path: delegate directly without the two-location search.
  if strpos(selected_name, '/') ge 0 then begin
    return, nsp_resolve_relative_meta_kernel(kernels_path, selected_name)
  endif

  ; Bare filename: check both <KERNEL_PATH>/<name> and <KERNEL_PATH>/mk/<name>.
  root_candidate = file_expand_path(kernels_path + '/' + selected_name)
  mk_candidate = file_expand_path(kernels_path + '/mk/' + selected_name)

  root_found = file_test(root_candidate, /REGULAR)
  mk_found = file_test(mk_candidate, /REGULAR)

  if ~root_found and ~mk_found then begin
    diagnostic = 'Step 2 kernel resolution failed: no meta-kernel named "' + selected_name + '" was found in the deterministic search locations beneath KERNEL_PATH=' + kernels_path
    diagnostic = diagnostic + string(10B) + '  ' + root_candidate
    diagnostic = diagnostic + string(10B) + '  ' + mk_candidate
    message, diagnostic, /NONAME
  endif

  ; Both locations found and different paths: ambiguous, refuse to guess.
  if root_found and mk_found and (root_candidate ne mk_candidate) then begin
    diagnostic = 'Step 2 kernel resolution failed: meta-kernel name "' + selected_name + '" is ambiguous beneath KERNEL_PATH. Matching files:'
    diagnostic = diagnostic + string(10B) + '  ' + root_candidate
    diagnostic = diagnostic + string(10B) + '  ' + mk_candidate
    message, diagnostic, /NONAME
  endif

  resolved_path = root_found ? root_candidate : mk_candidate

  if ~file_test(resolved_path, /READ) then begin
    message, 'Step 2 kernel resolution failed: resolved meta-kernel is not readable: ' + resolved_path, /NONAME
  endif

  return, resolved_path
end


;+
; NAME:
;   NSP_RESOLVE_KERNELS
;
; PURPOSE:
;   Performs Step 2 of the NSP pipeline: resolves the SPICE meta-kernel
;   to a fully qualified, readable path and prints a summary.
;
; CATEGORY:
;   NAIF Satellite Position / Kernel Resolution
;
; CALLING SEQUENCE:
;   NSP_RESOLVE_KERNELS [, META_KERNEL_NAME=name] $
;                       [, KERNEL_PATH=path] $
;                       [, RESOLVED_META_KERNEL=resolved_meta_kernel]
;
; OPTIONAL KEYWORDS:
;   META_KERNEL_NAME     - STRING. Meta-kernel filename or relative path.
;                          Default: 'em16_ops.tm'.
;   KERNEL_PATH          - STRING. Override for the KERNEL_PATH environment
;                          variable.
;   RESOLVED_META_KERNEL - Output. STRING scalar. Fully expanded path to the
;                          resolved meta-kernel file.
;
; OUTPUTS:
;   RESOLVED_META_KERNEL keyword set on success.
;   Prints a validation summary. Raises an error on any failure.
;
; EXAMPLE:
;   NSP_RESOLVE_KERNELS, RESOLVED_META_KERNEL=mk
;   NSP_RESOLVE_KERNELS, META_KERNEL_NAME='custom.tm', RESOLVED_META_KERNEL=mk
;
; MODIFICATION HISTORY:
;   2026-04-07: Initial implementation
;-
pro nsp_resolve_kernels, meta_kernel_name=meta_kernel_name, kernel_path=kernel_path, resolved_meta_kernel=resolved_meta_kernel
  compile_opt strictarr

  resolved_meta_kernel = nsp_resolve_meta_kernel(meta_kernel_name=meta_kernel_name, kernel_path=kernel_path)

  print, 'Step 2 kernel resolution passed.'
  print, 'Resolved meta-kernel=' + resolved_meta_kernel
end
