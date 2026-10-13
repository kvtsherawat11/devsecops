package code.security

deny[msg] if {
  input.language == "javascript"
  input.contains_eval == true
  msg = "Use of eval() is forbidden in JavaScript code"
}
