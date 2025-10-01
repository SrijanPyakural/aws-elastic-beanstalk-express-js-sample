pipeline {
  agent none

  environment {
    DOCKER_REPO     = 'your-dockerhub-username/aws-eb-express'  // ⬅️ update with your repo
    IMAGE_TAG       = "${env.BRANCH_NAME ?: 'main'}-${env.BUILD_NUMBER}"
    DOCKERHUB_CREDS = 'dockerhub-creds'   // Jenkins credential ID
  }

  options {
    ansiColor('xterm')
    timestamps()
  }

  stages {

    /* ---- 1. Checkout source ---- */
    stage('Checkout') {
      agent any
      steps { checkout scm }
    }

    /* ---- 2. Node 16 build agent ---- */
    stage('Install & Test (Node16)') {
      agent { docker { image 'node:16-alpine' } }
      steps {
        sh '''
          set -eux
          node -v
          npm -v
          npm install --save           # per assignment
          npm test --if-present        # runs tests if defined
        '''
      }
    }

    /* ---- 3. Build Docker image ---- */
    stage('Build Docker Image') {
      agent any
      steps {
        sh '''
          set -eux
          docker version
          docker build -t ${DOCKER_REPO}:${IMAGE_TAG} .
        '''
      }
    }

    /* ---- 4. Push to Docker Hub ---- */
    stage('Push Image') {
      agent any
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDS}",
                                          usernameVariable: 'DH_USER',
                                          passwordVariable: 'DH_PASS')]) {
          sh '''
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker push ${DOCKER_REPO}:${IMAGE_TAG}
            docker logout
          '''
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline finished for ${DOCKER_REPO}:${IMAGE_TAG}"
    }
  }
}

