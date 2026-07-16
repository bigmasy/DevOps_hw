resource "helm_release" "grafana" {
  name             = "grafana"
  namespace        = var.namespace
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_chart_version
  create_namespace = false

  values = [
    templatefile("${path.module}/grafana-values.yaml.tpl", {
      namespace              = var.namespace
      grafana_admin_username = var.grafana_admin_username
      grafana_admin_password = var.grafana_admin_password
    })
  ]

  # URL датасорсу в values вище — статичний рядок (DNS Service, не залежність
  # від конкретного ресурсу), тому це лише явний порядок apply, як і в решті
  # модулів репозиторію.
  depends_on = [helm_release.prometheus]
}
