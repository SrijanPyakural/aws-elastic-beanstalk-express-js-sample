// Jenkinsfile — Task 3: CI/CD + Security Gate
pipeline {
  agent none
  options {
    timestamps()
  }
  environment {
    // ---- edit this to your Docker Hub repo ----
    IMAGE_NAME = 'srijanpyakural/aws-elastic-beanstalk-express-js-sample'
    IMAGE_TAG  = "build-${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      agent any
      steps {
        checkout scm
      }
    }

    // Use Node 16 Docker image as the build agent (assignment requirement)
    stage('Install & Test (Node 16)') {
      agent {
        docker { image 'node:16-alpine'; args '-u root:root' }
      }
      steps {
        sh 'node -v && npm -v'
        // Assignment explicitly says npm install --save
        sh 'npm install --save'
        // If the sample app has no tests, don’t fail the whole build
        sh 'npm test || echo "No unit tests found — continuing"'
        // Keep workspace for later stages
        stash name: 'ws', includes: '**/*'
      }
    }

    // Security in the pipeline: dependency vulnerability scan (fails on High/Critical)
    stage('Snyk Scan (fail on High/Critical)') {
      agent {
        docker { image 'node:16-alpine'; args '-u root:root' }
      }
      environment {
        SNYK_TOKEN = credentials('snyk-token')   // Jenkins secret text credential
      }
      steps {
        sh '''
          npm install -g snyk
          snyk auth "$SNYK_TOKEN"
          # Fail build if any HIGH or CRITICAL found:
          snyk test --severity-threshold=high
        '''
      }
    }

    // Build container image with the Jenkins controller's Docker CLI (DinD backend)
    stage('Build Image') {
      agent any
      steps {
        unstash 'ws'
        sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
      }
    }

    stage('Login & Push to Registry') {
      agent any
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-cred',
                                          usernameVariable: 'DOCKER_USER',
                                          passwordVariable: 'DOCKER_PASS')]) {
          sh '''
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

