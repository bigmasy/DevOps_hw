resource "kubernetes_storage_class_v1" "ebs_sc" {
  metadata {
    name = "ebs-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"

  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type = "gp3"
  }
}

resource "aws_iam_role" "jenkins_kaniko_role" {
  name = "${var.cluster_name}-jenkins-kaniko-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:jenkins:jenkins-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "jenkins_ecr_policy" {
  name = "${var.cluster_name}-jenkins-kaniko-ecr-policy"
  role = aws_iam_role.jenkins_kaniko_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "helm_release" "jenkins" {
  name             = "jenkins"
  namespace        = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = "5.8.27"
  create_namespace = true
  # Дефолт (300с) закороткий для повного reboot з нуля: init-контейнери +
  # install усіх плагінів + JVM boot.
  timeout = 900

  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      jenkins_admin_username = var.jenkins_admin_username
      jenkins_admin_password = var.jenkins_admin_password
      github_username        = var.github_username
      github_pat             = var.github_pat
      infra_repo_url         = var.infra_repo_url
      infra_repo_branch      = var.infra_repo_branch
      django_repo_url        = var.django_repo_url
      django_repo_branch     = var.django_repo_branch
      ecr_registry           = var.ecr_registry
      ecr_image_name         = var.ecr_image_name
      ecr_image_tag          = var.ecr_image_tag
      jenkins_url            = var.jenkins_url
      app_chart_path         = var.app_chart_path
      git_commit_email       = var.git_commit_email
      git_commit_name        = var.git_commit_name
    })
  ]

  depends_on = [
    kubernetes_storage_class_v1.ebs_sc
  ]
}

resource "kubernetes_service_account" "jenkins_sa" {
  metadata {
    name      = "jenkins-sa"
    namespace = "jenkins"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_kaniko_role.arn
    }
  }
  depends_on = [
    helm_release.jenkins
  ]
}
