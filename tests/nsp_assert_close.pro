pro nsp_assert_close, actual_value, expected_value, tolerance, failure_message
  compile_opt strictarr

  difference = abs(double(actual_value) - double(expected_value))
  if difference gt double(tolerance) then begin
    message, 'Tests failed: ' + failure_message, /NONAME
  endif
end
