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
      command:
        - sleep
      args:
        - 99d
      resources:
        requests:
          memory: "400Mi"
          cpu: "200m"
        limits:
          memory: "768Mi"
          cpu: "500m"
    - name: git
      image: alpine/git
      command:
        - sleep
      args:
        - 99d
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
              --cache=true \\
              --insecure \\
              --skip-tls-verify
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
