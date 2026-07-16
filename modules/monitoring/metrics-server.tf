# kube-system, а не var.namespace — стандартне розташування для цього
# аддона (не залежить від namespace "monitoring", працює для всього
# кластера); kube-system завжди існує, create_namespace не потрібен.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version

  values = [file("${path.module}/metrics-server-values.yaml")]
}
