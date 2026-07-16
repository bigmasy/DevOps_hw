# Легкий standalone prometheus-community/prometheus chart замість
# kube-prometheus-stack — той тягне за собою завжди-увімкнений operator +
# admission-webhook поди + CRDs, яких тут ніхто не використовує, а пам'яті
# на 3×t3.small (2 vCPU/2GiB кожна) і так вистачає впритул.
resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = var.namespace
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = var.prometheus_chart_version
  create_namespace = false

  values = [file("${path.module}/prometheus-values.yaml")]

  depends_on = [kubernetes_namespace.monitoring]
}
