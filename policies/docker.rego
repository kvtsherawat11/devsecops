package docker.security

# Deny if image tag is "latest"
deny[msg] {
  input.image.tag == "latest"
  msg = "Do not use 'latest' tag for Docker images"
}

# Deny if image size exceeds 500 MB
deny[msg] {
  input.image.size_mb > 500
  msg = sprintf("Image too large: %d MB (limit 500 MB)", [input.image.size_mb])
}

# Deny if base image is not from approved list
deny[msg] {
  not input.image.base in {"node:16-alpine", "python:3.9-slim", "ubuntu:20.04"}
  msg = sprintf("Unapproved base image: %s", [input.image.base])
}
