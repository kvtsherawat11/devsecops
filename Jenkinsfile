pipeline {
    agent { label 'build' }

    stages {
        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM',
                          branches: [[name: '*/main']],
                          userRemoteConfigs: [[url: 'https://github.com/kvtsherawat11/devsecops.git']]
                ])
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                // Update DB first
                dependencyCheck odcInstallation: 'DC-CLI',
                                additionalArguments: '--updateonly'

                // Then run the actual scan
                dependencyCheck odcInstallation: 'DC-CLI',
                                additionalArguments: '--scan . --format XML --out ./dependency-check-report.xml'
            }
            post {
                always {
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }

        stage('Policy as Code Checks') {
            steps {
                sh '''
                    curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
                    chmod +x opa
                    ./opa test policies/
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t myapp:latest -f app/Dockerfile app/'
            }
        }

        stage('Smoke Test Container') {
            steps {
                sh '''
                    docker run --rm myapp:latest echo "Smoke test passed"
                '''
            }
        }

        stage('Push Image to Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ecr-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws ecr get-login-password --region ap-south-1 | \
                        docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.ap-south-1.amazonaws.com
                        docker tag myapp:latest <your-account-id>.dkr.ecr.ap-south-1.amazonaws.com/myapp:latest
                        docker push <your-account-id>.dkr.ecr.ap-south-1.amazonaws.com/myapp:latest
                    '''
                }
            }
        }

        stage('Trigger CD Pipeline') {
            steps {
                build job: 'cd_pipeline', wait: false
            }
        }
    }
}
