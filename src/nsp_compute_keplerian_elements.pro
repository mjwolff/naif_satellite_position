pro nsp_compute_keplerian_elements, et, inertial_state_vector, keplerian_elements=keplerian_elements, mars_gm=mars_gm
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 9 export failed: ET was not provided for Keplerian-element calculation.', /NONAME
  endif

  if n_elements(inertial_state_vector) ne 6 then begin
    message, 'Step 9 export failed: expected a 6-element inertial state vector for Keplerian-element calculation.', /NONAME
  endif

  et_value = double(et)
  if ~finite(et_value) then begin
    message, 'Step 9 export failed: ET must be finite for Keplerian-element calculation.', /NONAME
  endif

  state_values = double(inertial_state_vector)
  if total(finite(state_values)) ne 6 then begin
    message, 'Step 9 export failed: inertial state vector contains non-finite values.', /NONAME
  endif

  status = execute("cspice_bodvrd, 'MARS', 'GM', 1, gm_values")
  if status eq 0 then begin
    message, 'Step 9 export failed: unable to read Mars GM with cspice_bodvrd.', /NONAME
  endif

  if n_elements(gm_values) lt 1 then begin
    message, 'Step 9 export failed: Mars GM was not returned by cspice_bodvrd.', /NONAME
  endif

  mars_gm = double(gm_values[0])
  if ~finite(mars_gm) then begin
    message, 'Step 9 export failed: Mars GM is non-finite.', /NONAME
  endif

  status = execute('cspice_oscelt, state_values, et_value, mars_gm, keplerian_elements')
  if status eq 0 then begin
    message, 'Step 9 export failed: cspice_oscelt did not complete successfully.', /NONAME
  endif

  if n_elements(keplerian_elements) ne 8 then begin
    message, 'Step 9 export failed: expected 8 osculating-element values from cspice_oscelt.', /NONAME
  endif

  if total(finite(keplerian_elements)) ne 8 then begin
    message, 'Step 9 export failed: Keplerian elements contain non-finite values.', /NONAME
  endif
end
