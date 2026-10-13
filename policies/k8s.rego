package kubernetes.security

deny[msg] if {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot
  msg = "Kubernetes deployments must run as non-root"
}
