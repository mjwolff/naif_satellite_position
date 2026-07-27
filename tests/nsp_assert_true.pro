pro nsp_assert_true, condition, failure_message
  compile_opt idl2

  if ~condition then begin
    message, 'Tests failed: ' + failure_message, /NONAME
  endif
end
