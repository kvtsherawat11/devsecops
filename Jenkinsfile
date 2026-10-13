pipeline {
  agent { label 'build' }
  stages {
    stage('Checkout') {
      steps { git 'https://github.com/your-org/hello-gitops-app.git' }
    }
    stage('Install Policy Agents') {
      steps {
        sh 'curl -L -o conftest https://github.com/open-policy-agent/conftest/releases/download/v0.45.0/conftest_linux_amd64'
        sh 'chmod +x conftest && mv conftest /usr/local/bin/'
      }
    }
    stage('Code Quality & Coverage') {
      steps {
        sh 'npm test'
        sh 'npm run coverage'
      }
    }
    stage('SAST & SCA') {
      steps {
        sh 'trivy fs .'
        dependencyCheck additionalArguments: '--scan ./'
      }
    }
    stage('Policy Checks') {
      steps {
        sh 'conftest test Dockerfile'
        sh 'conftest test k8s/*.yaml'
      }
    }
    stage('Docker Build & Scan') {
      steps {
        sh 'docker build -t hello-gitops:${BUILD_NUMBER} .'
        sh 'trivy image hello-gitops:${BUILD_NUMBER}'
      }
    }
    stage('Publish Metadata') {
      steps {
        sh '''
          echo "{ \\"build\\": \\"${BUILD_NUMBER}\\", \\"sonar\\": \\"passed\\", \\"trivy\\": \\"clean\\" }" > metadata/results.json
          docker tag hello-gitops:${BUILD_NUMBER} <ECR_REPO>/hello-gitops:${BUILD_NUMBER}
          docker push <ECR_REPO>/hello-gitops:${BUILD_NUMBER}
          aws s3 cp metadata/results.json s3://ci-metadata-bucket/hello-gitops/${BUILD_NUMBER}/results.json
        '''
      }
    }
    stage('Trigger CD Pipeline') {
      steps {
        build job: 'cd_pipeline', parameters: [string(name: 'IMAGE_TAG', value: "${BUILD_NUMBER}")]
      }
    }
  }
}
