pro nsp_assert_true, condition, failure_message
  compile_opt strictarr

  if ~condition then begin
    message, 'Tests failed: ' + failure_message, /NONAME
  endif
end
