# fullnameOverride гарантує ім'я Service рівно "grafana" (не "grafana-grafana"
# чи інше похідне від release name) — саме це ім'я жорстко очікує команда
# перевірки завдання: kubectl port-forward svc/grafana 3000:80 -n monitoring
fullnameOverride: "grafana"

adminUser: "${grafana_admin_username}"
adminPassword: "${grafana_admin_password}"

service:
  type: ClusterIP

# Ефемерне сховище (без PVC) — прийнятний компроміс для домашнього завдання:
# перевірка робиться через port-forward одразу після apply. Втрачаються лише
# кастомні дашборди/зміни, зроблені вручну через UI між рестартами пода.
persistence:
  enabled: false

resources:
  requests:
    cpu: "50m"
    memory: "128Mi"
  limits:
    cpu: "200m"
    memory: "256Mi"

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: "http://prometheus-server.${namespace}.svc.cluster.local"
        isDefault: true
