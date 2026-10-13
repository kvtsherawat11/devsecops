pipeline {
  agent { label 'build' }
  environment {
    ECR_REPO = "<your-ecr-repo-url>"
    METADATA_BUCKET = "ci-cd-metadata-bucket"
  }
  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/your-org/sample-app.git'
      }
    }

    stage('Build & Test') {
      steps {
        sh 'npm install'
        sh 'npm test'
      }
    }

    stage('Code Coverage') {
      steps {
        sh 'npm run coverage'
        sh 'cp coverage/coverage-summary.json metadata/coverage.json'
      }
    }

    stage('SAST & SCA') {
      steps {
        sh 'trivy fs --exit-code 0 --severity HIGH,CRITICAL . > metadata/trivy_fs.txt'
        dependencyCheck additionalArguments: '--scan ./ --format XML --out metadata/dependency-check-report.xml'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        sh 'mvn sonar:sonar -Dsonar.projectKey=sample-app -Dsonar.host.url=http://<SONARQUBE_URL> -Dsonar.login=<TOKEN>'
        sh 'cp target/sonar/report-task.txt metadata/sonar_report.txt'
      }
    }

    stage('Install Policy Agent') {
      steps {
        sh 'wget https://github.com/open-policy-agent/conftest/releases/download/v0.37.0/conftest_0.37.0_Linux_x86_64.tar.gz'
        sh 'tar xzf conftest_0.37.0_Linux_x86_64.tar.gz'
        sh 'mv conftest /usr/local/bin/'
      }
    }

    stage('Policy Checks - Code') {
      steps {
        sh 'echo \'{"coverage":{"percent":85},"sca":{"vulnerabilities":[]}, "sonar":{"quality_gate":"PASSED"}}\' > input.json'
        sh 'conftest test --policy policies/code.rego input.json > metadata/code_policy.txt'
      }
    }

    stage('Docker Build & Scan') {
      steps {
        sh 'docker build -t sample-app:${BUILD_NUMBER} .'
        sh 'trivy image sample-app:${BUILD_NUMBER} > metadata/image_scan.txt'
      }
    }

    stage('Policy Checks - Image') {
      steps {
        sh 'echo \'{"image":{"tag":"${BUILD_NUMBER}","size_mb":320,"base":"node:16-alpine"}}\' > input.json'
        sh 'conftest test --policy policies/docker.rego input.json > metadata/image_policy.txt'
      }
    }

    stage('Smoke Test') {
      steps {
        sh 'docker run -d -p 3000:3000 sample-app:${BUILD_NUMBER}'
        sh 'sleep 10 && curl -f http://localhost:3000 || exit 1'
      }
    }

    stage('Push Image & Metadata') {
      steps {
        sh 'docker tag sample-app:${BUILD_NUMBER} ${ECR_REPO}/sample-app:${BUILD_NUMBER}'
        sh 'docker push ${ECR_REPO}/sample-app:${BUILD_NUMBER}'
        sh 'tar czf metadata-${BUILD_NUMBER}.tar.gz metadata/*'
        sh 'aws s3 cp metadata-${BUILD_NUMBER}.tar.gz s3://${METADATA_BUCKET}/'
      }
    }

    stage('Trigger CD Pipeline') {
      steps {
        build job: 'cd_pipeline', parameters: [
          string(name: 'IMAGE_TAG', value: "${BUILD_NUMBER}"),
          string(name: 'METADATA_PATH', value: "s3://${METADATA_BUCKET}/metadata-${BUILD_NUMBER}.tar.gz")
        ]
      }
    }
  }
}
