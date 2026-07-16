# Фінальний проєкт: EKS CI/CD платформа для Django (Terraform + Jenkins + Argo CD + Prometheus/Grafana)

Terraform-репозиторій, що піднімає AWS-інфраструктуру (VPC, EKS, ECR, опційно RDS/Aurora) і повністю декларативно (Helm + JCasC) розгортає в кластері:

- **Jenkins** — збирає Docker-образ Django-застосунку (Kaniko) і пушить його в ECR, потім оновлює тег образу в Git;
- **Argo CD** — стежить за Git і синхронізує Helm-чарт застосунку в кластер після кожного оновлення тегу;
- **Prometheus + Grafana** — збирають метрики кластера й застосунку, живлять HPA (автомасштабування подів Django за CPU);
- **RDS/Aurora** (`modules/rds`) — гнучкий модуль БД, вимкнений за замовчуванням (`enable_rds=false`), застосунок наразі працює на self-hosted Postgres у кластері — деталі в `modules/rds/README.md`.

> ⚠️ **Застосунок (Dockerfile + Jenkinsfile) живе в окремому репозиторії, не тут.**
> Цей репозиторій — лише інфраструктура (Terraform) і маніфест деплою (`charts/django-app`).
> Репозиторій застосунку: `<TF_VAR_django_repo_url з .env>` (наприклад, `https://github.com/bigmasy/django-app-ci.git`).
> Jenkinsfile, який там знаходиться, наведений нижче в розділі [Jenkins pipeline](#jenkins-pipeline-django-app-ci).

---

## Архітектура CI/CD

```
Розробник               GitHub                    Jenkins (EKS, ns=jenkins)              ECR         GitHub (infra)          Argo CD (EKS, ns=argocd)        EKS
    │                      │                              │                               │               │                          │                     │
    │ git push             │                               │                               │               │                          │                     │
    ├─────────────────────►│                               │                               │               │                          │                     │
    │              (django-app-ci)                         │                               │               │                          │                     │
    │                      │  webhook POST                 │                               │               │                          │                     │
    │                      ├──────────────────────────────►│                               │               │                          │                     │
    │                      │                     job goit-django-docker                    │               │                          │                     │
    │                      │                     agent: kaniko + git (jenkins-sa/IRSA)      │               │                          │                     │
    │                      │                     stage Build & Push ─────────────────────► │               │                          │                     │
    │                      │                     stage Update Chart Tag in Git              │               │                          │                     │
    │                      │                              ├──────────────────────────────────────────────►│                          │                     │
    │                      │                                                              git push          (charts/django-app/values.yaml: tag: v1.0.N)     │
    │                      │                                                                                │  Argo CD polls Git       │                     │
    │                      │                                                                                ├─────────────────────────►│                     │
    │                      │                                                                                │              автоматично: prune + selfHeal      │
    │                      │                                                                                │                          ├────────────────────►│
    │                      │                                                                                │                          │        helm upgrade django-app
```

Коротко: **push у django-app-ci → Jenkins білдить і пушить образ в ECR → Jenkins комітить новий тег у цей репозиторій → Argo CD бачить зміну в Git і сам синхронізує кластер.** Жодного ручного кроку між пушем коду і оновленням застосунку в кластері, крім першого запуску `seed-job` (одноразово).

---

## Структура проєкту

```
.
├── main.tf                      # Підключення всіх модулів
├── backend.tf                   # S3 + DynamoDB backend
├── variables.tf                 # Змінні, що керуються через TF_VAR_* (.env)
├── outputs.tf                   # Загальні виводи
├── .env.example                 # Шаблон змінних оточення (секрети, URL-и, теги)
│
├── modules/
│   ├── s3-backend/               # S3-бакет + DynamoDB для стейту
│   ├── vpc/                      # VPC, підмережі, маршрутизація
│   ├── ecr/                      # ECR-репозиторій для Docker-образу
│   ├── eks/                      # EKS-кластер + EBS CSI driver (IRSA) + OIDC provider
│   ├── jenkins/                  # Helm-реліз Jenkins + JCasC (credentials, seed-job, GitHub server) + IRSA-роль для Kaniko
│   ├── argo-cd/                  # Helm-реліз Argo CD + локальний чарт charts/, що створює Application і repo-credentials Secret
│   │   └── charts/               # Helm-чарт: templates/application.yaml, templates/repository.yaml
│   ├── monitoring/               # Prometheus + Grafana + metrics-server (Helm-релізи)
│   └── rds/                      # Гнучкий модуль RDS instance / Aurora Cluster (вимкнений за замовчуванням)
│
└── charts/
    └── django-app/                # Helm-чарт застосунку — саме його відстежує Argo CD Application
        ├── Chart.yaml
        ├── values.yaml            # image.tag тут оновлює Jenkins після кожного білду
        └── templates/
```

---

## Налаштування (.env)

```bash
cp .env.example .env
# відредагуйте .env — заповніть github_pat, jenkins_admin_password, ecr_registry,
# django_repo_url (реальний репозиторій застосунку) тощо
set -a && source .env && set +a
```

Усі секрети (GitHub PAT, паролі, URL-и репозиторіїв, ECR registry) передаються через змінні оточення `TF_VAR_*` — жодних хардкод-значень у `.tf`/`.yaml` файлах. Деталі кожної змінної — у коментарях `.env.example`.

---

## Запуск інфраструктури

### 1. Бутстрап S3-бекенду

`backend.tf` вказує на S3-бакет, якого при першому запуску ще не існує — тому спочатку застосовуємо тільки `s3_backend` з локальним стейтом:

```bash
mv backend.tf backend.tf.disabled
terraform init
terraform apply -target=module.s3_backend
```

### 2. Міграція на S3-бекенд і повний apply

```bash
mv backend.tf.disabled backend.tf
terraform init -migrate-state
terraform apply
```

Це підніме VPC → ECR → EKS → EBS CSI driver → Jenkins (Helm + JCasC) → Argo CD (Helm + Application) → Prometheus + Grafana + metrics-server (`module.monitoring`). RDS/Aurora не піднімається (`enable_rds=false` за замовчуванням).

### 3. Другий apply — публічний URL Jenkins

`manageHooks` (авторегістрація GitHub-вебхука) потребує коректного Jenkins root URL, який відомий лише після створення LoadBalancer:

```bash
kubectl get svc -n jenkins jenkins
# TF_VAR_jenkins_url=http://<LB-hostname>/  →  у .env
set -a && source .env && set +a
terraform apply
```

---

## Перевірка Jenkins

```bash
terraform output jenkins_namespace
kubectl get svc -n jenkins jenkins        # зовнішня адреса
```

Логін — `jenkins_admin_username` / `jenkins_admin_password` з `.env`.

1. Відкрийте job **seed-job** → **Build Now** (один раз, вручну) — він через Job DSL створює pipeline **goit-django-docker**, який клонує `TF_VAR_django_repo_url`.
2. Переконайтесь, що в django-app-ci є `Dockerfile` і `Jenkinsfile` (див. нижче).
3. Пуш у django-app-ci → GitHub webhook → `goit-django-docker` запускається автоматично (`githubPush()` trigger), білдить образ через Kaniko, пушить у ECR, і комітить новий `image.tag` у `charts/django-app/values.yaml` цього репозиторію.

### Jenkins pipeline (django-app-ci)

Цей `Jenkinsfile` має лежати в корені репозиторію застосунку (`TF_VAR_django_repo_url`), не тут:

```groovy
pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-kaniko
spec:
  serviceAccountName: jenkins-sa
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.16.0-debug
      imagePullPolicy: Always
      command: ["sleep"]
      args: ["99d"]
      resources:
        requests:
          memory: "400Mi"
          cpu: "200m"
        limits:
          memory: "768Mi"
          cpu: "500m"
    - name: git
      image: alpine/git
      command: ["sleep"]
      args: ["99d"]
      resources:
        requests:
          memory: "32Mi"
          cpu: "50m"
        limits:
          memory: "64Mi"
          cpu: "100m"
"""
    }
  }

  environment {
    IMAGE_TAG = "v1.0.${BUILD_NUMBER}"
  }

  stages {
    stage('Build & Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \\
              --context `pwd` \\
              --dockerfile `pwd`/Dockerfile \\
              --destination=$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG \\
              --cache=true --insecure --skip-tls-verify
          '''
        }
      }
    }

    stage('Update Chart Tag in Git') {
      steps {
        container('git') {
          withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PAT')]) {
            sh '''
              git clone --branch $INFRA_REPO_BRANCH https://$GIT_USERNAME:$GIT_PAT@${INFRA_REPO_URL#https://} infra
              cd infra/$CHART_PATH
              sed -i "s/tag: .*/tag: $IMAGE_TAG/" values.yaml
              git config user.email "$GIT_COMMIT_EMAIL"
              git config user.name "$GIT_COMMIT_NAME"
              git add values.yaml
              git commit -m "Update image tag to $IMAGE_TAG"
              git push origin HEAD:$INFRA_REPO_BRANCH
            '''
          }
        }
      }
    }
  }
}
```

`ECR_REGISTRY`, `IMAGE_NAME`, `INFRA_REPO_URL`, `INFRA_REPO_BRANCH`, `CHART_PATH`, `GIT_COMMIT_EMAIL`, `GIT_COMMIT_NAME` і credential `github-token` уже налаштовані в Jenkins через JCasC (модуль `jenkins`) — у django-app-ci нічого додатково конфігурувати не треба, окрім самих `Dockerfile` і `Jenkinsfile`.

---

## Перевірка Argo CD

```bash
terraform output argo_cd_server_hint       # команда для зовнішньої адреси UI
terraform output argo_cd_admin_password_hint

# або напряму через port-forward (без LoadBalancer):
kubectl port-forward svc/argo-cd-argocd-server 8081:443 -n argocd
```

Логін — `admin` / пароль з команди вище.

У UI: **Applications → django-app** — застосунок має бути `Synced` + `Healthy`. Дерево ресурсів покаже Deployment/ReplicaSet/Pod/Service/ConfigMap з `charts/django-app`. Після кожного коміту Jenkins в `values.yaml` (новий `image.tag`) Argo CD сам підхоплює зміну (`syncPolicy.automated: prune + selfHeal`) — без ручного Sync.

---

## Моніторинг (Prometheus + Grafana)

```bash
kubectl get all -n monitoring

# metrics-server — доказ, що працює (без нього HPA нижче показує <unknown>)
kubectl top nodes
kubectl top pods -n django

# Grafana UI
kubectl port-forward svc/grafana 3000:80 -n monitoring
# http://localhost:3000 — логін TF_VAR_grafana_admin_username/password з .env
```

Джерело даних Prometheus у Grafana підключене автоматично (декларативно через Helm values, `modules/monitoring/grafana-values.yaml.tpl`) — після логіну дані вже видно, ручного налаштування datasource не потрібно. Готових дашбордів не імпортовано (щоб не роздувати чарт) — за бажанням: **Dashboards → Import**, ID `1860` (Node Exporter Full) або `7249` (Kubernetes Cluster Monitoring).

Prometheus UI (Targets/Graph) — за потреби:
```bash
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

---

## Перевірка HPA (автомасштабування Django)

`charts/django-app/templates/hpa.yaml` тримає 1-6 реплік за CPU utilization (target 70%) — працює лише завдяки `metrics-server` з `module.monitoring`.

```bash
kubectl get hpa django-app-hpa -n django
# TARGETS має показувати число (напр. 3%/70%), не <unknown>

# короткий генератор навантаження
kubectl run load-generator --image=busybox:1.36 --restart=Never -n django -- \
  /bin/sh -c "while true; do wget -q -O- http://django-app-service/ > /dev/null; done"

kubectl get hpa django-app-hpa -n django -w   # дочекатись REPLICAS > 1
kubectl get pods -n django -w

kubectl delete pod load-generator -n django   # зупинити навантаження
# зменшення реплік назад — автоматичне, за замовчуванням через ~5 хв (stabilizationWindow)
```

---

## Безпека: VPC / IAM / Security Groups

- **Мережа**: worker-ноди EKS і RDS (коли увімкнений) — лише в приватних підмережах (`module.vpc.private_subnet_ids`), вихід в інтернет через NAT Gateway. Публічні підмережі — тільки для LoadBalancer'ів (Jenkins UI).
- **IAM-ролі (least privilege, кожна — під конкретний сервіс)**:
  - `aws_iam_role.cluster` (`${cluster_name}-role`) — EKS control plane, лише `AmazonEKSClusterPolicy`.
  - `aws_iam_role.node` (`${cluster_name}-node-role`) — worker-ноди: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly` (тільки pull, без push).
  - `aws_iam_role.ebs_csi_irsa_role` (`${cluster_name}-ebs-csi-irsa-role`) — IRSA, scoped лише до `system:serviceaccount:kube-system:ebs-csi-controller-sa`, `AmazonEBSCSIDriverPolicy`.
  - `aws_iam_role.jenkins_kaniko_role` (`${cluster_name}-jenkins-kaniko-role`) — IRSA, scoped лише до `system:serviceaccount:jenkins:jenkins-sa`, inline-політика обмежена конкретними ECR push-діями (без `ecr:*`/delete).
- **Security Groups**: RDS SG (`modules/rds/shared.tf`) — ingress обмежений `ingress_cidr_blocks` (CIDR VPC, `10.0.0.0/16`), жодного `0.0.0.0/0` на вхід.
- **Секрети**: ніде не хардкодяться — усі паролі/токени (`jenkins_admin_password`, `github_pat`, `django_secret_key`, `grafana_admin_password`, `rds_password` тощо) передаються через `TF_VAR_*` з гітігноред `.env`, позначені `sensitive = true`, і кладуться в Kubernetes Secret самим Terraform (не через Helm values у git).

---

## Видалення інфраструктури

⚠️ **Порядок важливий.** `terraform destroy` видаляє й S3-бакет/DynamoDB-таблицю зі стейтом — Terraform сам коректно впорядковує видалення (спочатку EKS/Jenkins/Argo CD/Prometheus-Grafana/VPC, бекенд — останнім), тому досить одного виклику:

```bash
terraform destroy
```

Не використовуйте `-target` вибірково для частини стеку, лишаючи `module.s3_backend` "напризволяще" в тому ж прогоні — targeted/ручне видалення бекенду до завершення решти видалень небезпечне (Terraform може спробувати писати оновлений state в уже видалений бакет). Якщо треба видаляти частинами (напр. після помилки apply) — завжди лишайте `module.s3_backend` на потім окремим викликом.

Якщо після цього знадобиться підняти інфраструктуру знову — почніть з кроку 1 (бутстрап S3-бекенду), оскільки бакет і DynamoDB-таблиця також були видалені.
