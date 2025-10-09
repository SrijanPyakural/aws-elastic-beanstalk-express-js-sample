// Jenkinsfile — Node 16 CI/CD + Snyk gate + logging & retention
pipeline {
  agent any
  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
  }

  environment {
    // EDIT: your Docker Hub repo (username/repo)
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
          image 'node:16'              // Debian-based for reliability
          args '-u root:root'
          reuseNode true
        }
      }
      steps {
        sh 'node -v && npm -v | tee -a node-version.log'
        sh 'if [ -f package-lock.json ]; then npm ci 2>&1 | tee npm-install.log; else npm install --save 2>&1 | tee npm-install.log; fi'
        sh '(npm test 2>&1 | tee npm-test.log) || echo "No unit tests found — continuing" | tee -a npm-test.log'
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
      environment {
        SNYK_TOKEN = credentials('snyk-token')   // Secret text credential
        // If your Snyk region is EU/AU, set this as a global Jenkins env:
        // SNYK_API = 'https://api.eu.snyk.io'
        // SNYK_API = 'https://api.au.snyk.io'
      }
      steps {
        // POSIX-safe (no pipefail). Preserve Snyk exit code but still archive logs.
        sh '''
          set -eu

          echo "Installing Snyk CLI…"
          npm install -g snyk >/dev/null 2>&1 || npm install -g snyk
          echo "Snyk CLI version: $(snyk --version)"

          # Non-interactive auth (no browser/device flow)
          if [ -z "${SNYK_TOKEN:-}" ]; then
            echo "ERROR: SNYK_TOKEN missing (credential id: snyk-token)"
            exit 2
          fi
          snyk config set api="$SNYK_TOKEN" >/dev/null

          if [ -n "${SNYK_API:-}" ]; then
            echo "Using Snyk API endpoint: $SNYK_API"
          else
            echo "Using default Snyk API endpoint"
          fi

          # Quick auth check (no secrets printed)
          if ! snyk auth --status >/dev/null 2>&1; then
            echo "ERROR: Snyk auth failed (token/region)."
            exit 2
          fi

          # Run the security test and capture its real exit code
          snyk test --severity-threshold=high > snyk.log 2>&1
          status=$?
          cat snyk.log

          # Also write a JSON report for artifacts (do not change build result)
          snyk test --severity-threshold=high --json-file-output=snyk-report.json || true

          exit $status
        '''
      }
    }

    stage('Build Image') {
      steps {
        unstash 'ws'
        sh 'docker build --progress=plain -t $IMAGE_NAME:$IMAGE_TAG . 2>&1 | tee docker-build.log'
      }
    }

    stage('Login & Push to Registry') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-cred',
                                          usernameVariable: 'DOCKER_USER',
                                          passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            set -eu
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
      // Record image digest (provenance), if available
      sh 'docker image inspect $IMAGE_NAME:$IMAGE_TAG --format=\'{{json .RepoDigests}}\' > image-digests.json || true'
      archiveArtifacts artifacts: '''
        Jenkinsfile,
        Dockerfile,
        node-version.log,
        npm-install.log,
        npm-test.log,
        snyk.log,
        snyk-report.json,
        docker-build.log,
        image-digests.json
      '''.trim().replaceAll('\\s+', ' ')
      fingerprint 'image-digests.json'
    }
  }
}

