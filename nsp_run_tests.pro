pro nsp_run_tests
  compile_opt strictarr

  src_directory = file_expand_path('src')
  tests_directory = file_expand_path('tests')
  path_with_separators = ':' + !PATH + ':'
  src_with_separators = ':' + src_directory + ':'
  tests_with_separators = ':' + tests_directory + ':'

  if ~file_test(src_directory, /DIRECTORY) then begin
    message, 'nsp_run_tests failed: required source directory was not found relative to the current working directory: ' + src_directory, /NONAME
  endif

  if ~file_test(tests_directory, /DIRECTORY) then begin
    message, 'nsp_run_tests failed: required tests directory was not found relative to the current working directory: ' + tests_directory, /NONAME
  endif

  if strpos(path_with_separators, src_with_separators) lt 0 then begin
    !PATH = src_directory + ':' + !PATH
    path_with_separators = ':' + !PATH + ':'
  endif

  if strpos(path_with_separators, tests_with_separators) lt 0 then begin
    !PATH = tests_directory + ':' + !PATH
  endif

  nsp_run_pipeline
  nsp_test_time_handling
  nsp_test_state_vectors
  nsp_test_geometry
  nsp_test_solar_geometry
  nsp_test_occultation
  nsp_test_export_csv
  nsp_test_batch
  nsp_test_validate_outputs
end
