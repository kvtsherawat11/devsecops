package docker.security

deny[msg] {
  input.instruction == "USER"
  input.value == "root"
  msg = "Dockerfile must not run as root"
}
