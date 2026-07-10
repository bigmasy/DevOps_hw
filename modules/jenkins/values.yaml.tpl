controller:
  # installPlugins нижче використовує :latest — фіксована версія образу з
  # чарта (2.492.2) занадто стара для сучасних версій цих плагінів
  # (вимагають Jenkins core 2.504.1+). lts-jdk17 — рухомий тег, що завжди
  # вказує на поточний LTS, тримає core в парі з :latest-плагінами.
  image:
    tag: "lts-jdk17"

  admin:
    username: ${jenkins_admin_username}
    password: ${jenkins_admin_password}

  serviceType: LoadBalancer
  servicePort: 80
  service:
    port: 80
    targetPort: 8080

  resources:
    limits:
      cpu: "500m"
      memory: "1Gi"
    requests:
      cpu: "250m"
      memory: "512Mi"

  installPlugins:
    - kubernetes:latest
    - workflow-aggregator:latest
    - git:latest
    - configuration-as-code:latest
    - credentials-binding:latest
    - github:latest
    - docker-plugin:latest
    - docker-workflow:latest
    - job-dsl:latest

  serviceAccount:
    name: jenkins-sa
    create: false

  JCasC:
    configScripts:
      credentials: |
        credentials:
          system:
            domainCredentials:
              - credentials:
                  - usernamePassword:
                      scope: GLOBAL
                      id: github-token
                      username: ${github_username}
                      password: ${github_pat}
                      description: GitHub PAT

      global-env: |
        jenkins:
          globalNodeProperties:
            - envVars:
                env:
                  - key: "ECR_REGISTRY"
                    value: "${ecr_registry}"
                  - key: "IMAGE_NAME"
                    value: "${ecr_image_name}"
                  - key: "IMAGE_TAG"
                    value: "${ecr_image_tag}"
                  - key: "INFRA_REPO_URL"
                    value: "${infra_repo_url}"
                  - key: "INFRA_REPO_BRANCH"
                    value: "${infra_repo_branch}"
                  - key: "CHART_PATH"
                    value: "${app_chart_path}"
                  - key: "GIT_COMMIT_EMAIL"
                    value: "${git_commit_email}"
                  - key: "GIT_COMMIT_NAME"
                    value: "${git_commit_name}"

      github-server: |
        unclassified:
          gitHubPluginConfig:
            configs:
              - name: "GitHub"
                apiUrl: "https://api.github.com"
                credentialsId: "github-token"
                manageHooks: true
%{ if jenkins_url != "" ~}

      location: |
        unclassified:
          location:
            url: "${jenkins_url}"
%{ endif ~}

      seed-job: |
        jobs:
          - script: >
              job('seed-job') {
                description('Job to generate the CI pipeline for the Django project')
                scm {
                  git {
                    remote {
                      url('${infra_repo_url}')
                      credentials('github-token')
                    }
                    branches('*/${infra_repo_branch}')
                  }
                }
                steps {
                  dsl {
                    text('''
                      pipelineJob("goit-django-docker") {
                        triggers {
                          githubPush()
                        }
                        definition {
                          cpsScm {
                            scm {
                              git {
                                remote {
                                  url("${django_repo_url}")
                                  credentials("github-token")
                                }
                                branches("*/${django_repo_branch}")
                              }
                            }
                          }
                        }
                      }
                    ''')
                  }
                }
              }

persistence:
  enabled: true
  storageClass: "ebs-sc"
  size: 10Gi
