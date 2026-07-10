# Namespace і Secret для django-app створює Terraform, а не Helm/git — це
# єдиний спосіб дати Argo CD доступ до реальних SECRET_KEY/POSTGRES_PASSWORD,
# оскільки Argo CD деплоїть charts/django-app напряму з git, в обхід Terraform
# templatefile(). Application.yaml все одно має syncOptions CreateNamespace=true —
# це нешкідливо, якщо namespace вже існує.
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_namespace
  }
}

resource "kubernetes_secret" "django_app" {
  metadata {
    name      = "django-app-secrets"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    SECRET_KEY        = var.django_secret_key
    POSTGRES_PASSWORD = var.django_postgres_password
  }

  type = "Opaque"
}
