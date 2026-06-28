# Lesson 7: EKS Infrastructure Deployment & Django App Orchestration via Helm

Цей проєкт демонструє створення повноцінної хмарної інфраструктури в AWS за допомогою Terraform (IaC) та розгортання масштабованого, відмовостійкого Django-застосунку в кластері Amazon EKS за допомогою Helm.

## Архітектура рішення

Застосунок розгорнуто в одному поді, що містить три контейнери (Multi-container Pod):

1. Django App — вебзастосунок, налаштований на роботу в режимі --insecure для автоматичної роздачі вбудованої статики адмінки.
2. Nginx — вебсервер, який виступає як Reverse Proxy для Django.
3. PostgreSQL — локальна база даних для збереження даних.

Масштабування забезпечується за допомогою Horizontal Pod Autoscaler (HPA) на основі утилізації CPU.

---

## Структура проєкту

lesson-7/
│
├── main.tf # Головний файл інфраструктури Terraform
├── backend.tf # Налаштування віддаленого бекенду (S3 + DynamoDB)
├── outputs.tf # Загальні виводи створених ресурсів
├── .gitignore # Виключення системних та секретних файлів з Git
│
├── modules/ # Каталог з інфраструктурними модулями Terraform
│ ├── s3-backend/ # Модуль для створення S3 бакета та DynamoDB lock-таблиці
│ ├── vpc/ # Модуль мережі VPC, підмереж та маршрутизації
│ ├── ecr/ # Модуль репозиторію Amazon ECR
│ └── eks/ # Модуль кластера Amazon EKS та Node Groups
│
└── charts/ # Helm-чарти для деплою застосунку
└── django-app/
├── Chart.yaml # Метадані Helm-чарту
├── values.yaml # Конфігурація чарту (параметри образів, ліміти, HPA, Env)
└── templates/ # Шаблони маніфестів Kubernetes
├── deployment.yaml # Маніфест деплойменту (з initContainers та hostAliases)
├── service.yaml # Сервіс типу LoadBalancer для зовнішнього доступу
├── configmap.yaml # Карта конфігурацій для змінних оточення та Nginx
└── hpa.yaml # Налаштування Horizontal Pod Autoscaler (2-6 подів)

---

## Кроки розгортання інфраструктури

### 1. Ініціалізація та запуск Terraform

Перейдіть у корінь проєкту та ініціалізуйте інфраструктуру:

> terraform init
> terraform apply -auto-approve

_Після успішного завершення ви отримаєте URL вашого ECR репозиторію та дані EKS кластера._

### 2. Налаштування доступу до кластера

Оновіть локальний kubeconfig для підключення kubectl до вашого EKS кластера:

> aws eks update-kubeconfig --region us-west-2 --name <назва*вашого*кластера>

### 3. Авторизація в ECR та завантаження Docker-образу

Авторизуйте локальний Docker в AWS ECR:

> aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <ваш_aws_account_id>.dkr.ecr.us-west-2.amazonaws.com

Затегайте та запушіть ваш готовий образ Django (створений у ДЗ-4) до репозиторію:

> docker tag django-app:latest <ваш_aws_account_id>[.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django-repo:latest](https://.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django-repo:latest)
> docker push <ваш_aws_account_id>[.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django-repo:latest](https://.dkr.ecr.us-west-2.amazonaws.com/lesson-7-django-repo:latest)

---

## Розгортання застосунку через Helm

### 1. Перевірка конфігурації

Перенесіть ваші змінні середовища з Теми 4 у блок config: всередині файлу charts/django-app/values.yaml. Перевірте параметри масштабування HPA (від 2 до 6 подів):
[Конфігурація у values.yaml]
autoscaling:
enabled: true
minReplicas: 2
maxReplicas: 6
targetCPUUtilizationPercentage: 70

### 2. Встановлення Helm-чарту

Виконайте команду для встановлення релізу:

> helm install my-django-release ./charts/django-app

### 3. Моніторинг запуску

Запуск Django контролюється за допомогою initContainers, який очікує 12 секунд для повної ініціалізації сокета PostgreSQL перед початком застосування міграцій.

Перевірте статус подів:

> kubectl get pods

_Завдяки налаштованому HPA, Kubernetes автоматично змасштабує деплоймент до 2 подів мінімально._

---

## Валідація та перевірка працездатності

1. Отримання зовнішньої адреси сайту:
   > kubectl get svc django-app-service

Знайдіть адресу в колонці EXTERNAL-IP (наприклад, a22d199a7536e4669904849aeac45e9e-144395864.us-west-2.elb.amazonaws.com).

2. Перевірка веб-інтерфейсу:

- Головна сторінка віддає стандартний 404 Not Found від Django (якщо для / не налаштовано View), що підтверджує успішне проксіювання AWS ELB -> Nginx -> Django.
- Панель адміністратора доступна за адресою: http://<EXTERNAL-IP>/admin/. Завдяки прапорцю --insecure статика та CSS-стилі відображаються коректно.

---

## Результати виконання

- У вашому AWS-акаунті створено кластер Kubernetes.
- ECR містить завантажений Docker-образ Django-застосунку.
- Застосунок розгорнутий у кластері за допомогою Helm-чарта.
- Service забезпечує доступ до застосунку через публічну IP-адресу вашого LoadBalancer.
- ConfigMap підключено до застосунку через Helm.
- HPA динамічно масштабує кількість подів (утримує мінімум 2 поди).
