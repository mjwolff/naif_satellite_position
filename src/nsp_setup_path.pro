pro nsp_setup_path, include_tests=include_tests
  compile_opt strictarr

  src_directory = file_expand_path('src')
  tests_directory = file_expand_path('tests')
  path_with_separators = ':' + !PATH + ':'
  src_with_separators = ':' + src_directory + ':'
  tests_with_separators = ':' + tests_directory + ':'

  if ~file_test(src_directory, /DIRECTORY) then begin
    message, 'nsp_setup_path failed: required source directory was not found relative to the current working directory: ' + src_directory, /NONAME
  endif

  if strpos(path_with_separators, src_with_separators) lt 0 then begin
    !PATH = src_directory + ':' + !PATH
    path_with_separators = ':' + !PATH + ':'
  endif

  if keyword_set(include_tests) then begin
    if ~file_test(tests_directory, /DIRECTORY) then begin
      message, 'nsp_setup_path failed: required tests directory was not found relative to the current working directory: ' + tests_directory, /NONAME
    endif

    if strpos(path_with_separators, tests_with_separators) lt 0 then begin
      !PATH = tests_directory + ':' + !PATH
    endif
  endif
end
