pro nsp_state_vectors, et=et, state_vector=state_vector, light_time=light_time
  compile_opt strictarr

  if n_elements(et) eq 0 then begin
    message, 'Step 5 state-vector retrieval failed: ET was not provided.', /NONAME
  endif

  nsp_get_tgo_state, et, state_vector=state_vector, light_time=light_time

  print, 'Step 5 state-vector retrieval passed.'
  print, 'Frame=IAU_MARS'
  print, 'Aberration correction=' + nsp_state_vector_abcorr()
  print, 'Observer=MARS'
  print, 'Target=TGO'
  print, 'State X=' + strtrim(state_vector[0], 2)
  print, 'State VZ=' + strtrim(state_vector[5], 2)
  print, 'Light time=' + strtrim(light_time, 2)
end
