applications:
  - name: ${app_name}
    namespace: ${app_namespace}
    project: default
    source:
      repoURL: ${infra_repo_url}
      path: ${app_chart_path}
      targetRevision: ${infra_repo_branch}
      helm:
        valueFiles:
          - values.yaml
    destination:
      server: https://kubernetes.default.svc
      namespace: ${app_namespace}
    syncPolicy:
      automated:
        prune: true
        selfHeal: true

repositories:
  - name: infra
    url: ${infra_repo_url}
    username: ${github_username}
    password: ${github_pat}
