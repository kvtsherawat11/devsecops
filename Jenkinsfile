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
                // First run: omit --noupdate so DB is created
                // Later runs: add --noupdate to avoid lock contention
                dependencyCheck odcInstallation: 'DC-CLI',
                                additionalArguments: '--scan . --format XML --out ./dependency-check-report.xml --data /var/jenkins_home/dependency-check-data'
            }
            post {
                always {
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('Sonar') {
                        withCredentials([string(credentialsId: 'Sonar', variable: 'SONAR')]) {
                            sh """
                                sonar-scanner \
                                -Dsonar.projectKey=myapp \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=http://ec2-18-237-173-189.us-west-2.compute.amazonaws.com:9000 \
                                -Dsonar.login=$SONAR
                            """
                        }
                    }
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Policy as Code Checks') {
            steps {
                sh '''
                    curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
                    chmod +x opa
                    ./opa test policies/ > policy-check-report.txt
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t myapp:latest -f app/Dockerfile .'
            }
        }

        stage('Smoke Test Container') {
            steps {
                sh 'docker run --rm myapp:latest echo "Smoke test passed"'
            }
        }

        stage('Push Image to Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ecr-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws ecr get-login-password --region ap-south-1 | \
                        docker login --username AWS --password-stdin 054221783339.dkr.ecr.ap-south-1.amazonaws.com
                        docker tag myapp:latest 054221783339.dkr.ecr.ap-south-1.amazonaws.com/myapp:latest
                        docker push 054221783339.dkr.ecr.ap-south-1.amazonaws.com/myapp:latest
                    '''
                }
            }
        }

        stage('Publish Metadata') {
            steps {
                sh '''
                    echo "Collecting scan results into metadata.json"
                    jq -n \
                      --arg depCheck "$(cat dependency-check-report.xml)" \
                      --arg sonar "SonarQube results available in server dashboard" \
                      --arg policy "$(cat policy-check-report.txt)" \
                      '{dependencyCheck: $depCheck, sonarQube: $sonar, policyChecks: $policy}' > metadata.json

                    # Push metadata.json to same ECR registry
                    echo "FROM alpine:3.18\nCOPY metadata.json /metadata.json" > Dockerfile.metadata
                    docker build -t myapp-metadata:latest -f Dockerfile.metadata .
                    docker tag myapp-metadata:latest 054221783339.dkr.ecr.ap-south-1.amazonaws.com/myapp-metadata:latest
                    docker push 054221783339.dkr.ecr.ap-south-1.amazonaws.com/myapp-metadata:latest
                '''
                archiveArtifacts artifacts: 'metadata.json', fingerprint: true
            }
        }

        stage('Trigger CD Pipeline') {
            steps {
                build job: 'cd_pipeline', wait: false
            }
        }
    }
}
