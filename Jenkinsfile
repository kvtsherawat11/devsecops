pipeline {
  agent any
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
      }
    }

    stage('SAST & SCA') {
      steps {
        // Trivy for SAST
        sh 'trivy fs --exit-code 0 --severity HIGH,CRITICAL . > metadata/trivy_report.txt'
        // OWASP Dependency Check for SCA
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

    stage('Policy Checks') {
      steps {
        sh 'conftest test k8s/*.yaml --policy policies/ > metadata/policy_report.txt'
      }
    }

    stage('Docker Build & Scan') {
      steps {
        sh 'docker build -t sample-app:${BUILD_NUMBER} .'
        sh 'trivy image sample-app:${BUILD_NUMBER} > metadata/image_scan.txt'
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
        sh 'docker tag sample-app:${BUILD_NUMBER} <ECR_REPO>/sample-app:${BUILD_NUMBER}'
        sh 'docker push <ECR_REPO>/sample-app:${BUILD_NUMBER}'
        // Push metadata to repo or artifact store
        sh 'tar czf metadata-${BUILD_NUMBER}.tar.gz metadata/*'
        sh 'aws s3 cp metadata-${BUILD_NUMBER}.tar.gz s3://ci-cd-metadata-bucket/'
      }
    }

    stage('Trigger CD Pipeline') {
      steps {
        build job: 'cd_pipeline', parameters: [
          string(name: 'IMAGE_TAG', value: "${BUILD_NUMBER}"),
          string(name: 'METADATA_PATH', value: "s3://ci-cd-metadata-bucket/metadata-${BUILD_NUMBER}.tar.gz")
        ]
      }
    }
  }
}
