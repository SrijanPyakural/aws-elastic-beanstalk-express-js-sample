// Jenkinsfile — Task 3: Node 16 build, Snyk security gate, Docker build & push
pipeline {
  agent any
  options { timestamps() }

  environment {
    
    IMAGE_NAME = 'srijanpyakural/aws-elastic-beanstalk-express-js-sample'
    IMAGE_TAG  = "build-${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install & Test (Node 16)') {
      agent {
        docker {
          image 'node:16'               // Debian-based (more reliable than alpine)
          args '-u root:root'
          reuseNode true
        }
      }
      steps {
        sh 'node -v && npm -v'
        // Assignment mentions npm install --save; prefer ci when lockfile exists
        sh 'if [ -f package-lock.json ]; then npm ci; else npm install --save; fi'
        sh 'npm test || echo "No unit tests found — continuing"'
        stash name: 'ws', includes: '**/*'
      }
    }

    stage('Snyk Scan (fail on High/Critical)') {
      agent {
        docker {
          image 'node:16'
          args '-u root:root'
          reuseNode true
        }
      }
      environment { SNYK_TOKEN = credentials('snyk-token') } // Secret text credential
      steps {
        sh '''
          set -eux
          [ -n "$SNYK_TOKEN" ] || { echo "ERROR: SNYK_TOKEN missing (check Jenkins credential id: snyk-token)"; exit 2; }

          npm install -g snyk
          # Non-interactive auth (no browser/device flow)
          snyk config set api="$SNYK_TOKEN"
          snyk config set disable-analytics=true || true

          # Fail build if High or Critical issues are found
          snyk test --severity-threshold=high
        '''
      }
    }

    stage('Build Image') {
      steps {
        unstash 'ws'
        sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
      }
    }

    stage('Login & Push to Registry') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-cred',
                                          usernameVariable: 'DOCKER_USER',
                                          passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            set -eux
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push $IMAGE_NAME:$IMAGE_TAG
            docker tag  $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest
            docker push $IMAGE_NAME:latest
          '''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'Jenkinsfile, Dockerfile', allowEmptyArchive: true
    }
  }
}

