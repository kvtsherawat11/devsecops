package code.security

# Deny if critical vulnerabilities found in SCA/SAST scan
deny[msg] {
  vuln := input.sca.vulnerabilities[_]
  vuln.severity == "CRITICAL"
  msg = sprintf("Critical vulnerability found: %s", [vuln.id])
}

# Deny if code coverage is below 80%
deny[msg] {
  input.coverage.percent < 80
  msg = sprintf("Code coverage too low: %d%% (minimum 80%%)", [input.coverage.percent])
}

# Deny if SonarQube quality gate fails
deny[msg] {
  input.sonar.quality_gate != "PASSED"
  msg = "SonarQube quality gate failed"
}
