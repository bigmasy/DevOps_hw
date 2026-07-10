resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  namespace        = var.namespace
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]
}

resource "helm_release" "argo_apps" {
  name      = "argo-apps"
  chart     = "${path.module}/charts"
  namespace = var.namespace

  values = [
    templatefile("${path.module}/apps-values.yaml.tpl", {
      app_name          = var.app_name
      app_namespace     = var.app_namespace
      app_chart_path    = var.app_chart_path
      infra_repo_url    = var.infra_repo_url
      infra_repo_branch = var.infra_repo_branch
      github_username   = var.github_username
      github_pat        = var.github_pat
    })
  ]

  depends_on = [helm_release.argo_cd]
}
