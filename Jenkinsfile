pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    component: jenkins-gke-agent
spec:
  containers:
  - name: python
    image: python:3.11-slim
    command: ['cat']
    tty: true
  - name: gcloud
    image: google/cloud-sdk:latest
    command: ['cat']
    tty: true
'''
        }
    }

    environment {
        PROJECT_ID    = 'guestbook-503604'
        GAR_LOCATION  = 'asia-southeast1'
        GKE_CLUSTER   = 'guestbook-cluster'
        GKE_ZONE      = 'asia-southeast1-b'
        REPOSITORY    = 'guestbook-repo'
        IMAGE         = 'gcp-guestbook'
        IMAGE_TAG     = "${GAR_LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE}:${BUILD_NUMBER}"
    }

    triggers {
        pollSCM('H/2 * * * *') // Backup automated poll every 2 minutes
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('DevSecOps SAST Scan (Bandit)') {
            steps {
                container('python') {
                    sh '''
                        python3 -m pip install --user --upgrade bandit
                        export PATH=$HOME/.local/bin:$PATH
                        bandit -r app.py -f txt
                    '''
                }
            }
        }

        stage('SonarQube Code Quality & Security Scan') {
            steps {
                container('python') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            if ! command -v sonar-scanner &> /dev/null; then
                                apt-get update && apt-get install -y unzip curl
                                curl -LO https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
                                unzip -q sonar-scanner-cli-5.0.1.3006-linux.zip -d /opt/
                                ln -sf /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner
                            fi
                            sonar-scanner \
                              -Dsonar.host.url=http://136.85.111.72:9000 \
                              -Dsonar.token=$SONAR_TOKEN \
                              -Dsonar.projectKey=gcp-guestbook \
                              -Dsonar.sources=. \
                              -Dsonar.exclusions=venv/**,.github/**,jenkins-setup/**,terraform/**
                        '''
                    }
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                container('python') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            echo "Querying SonarQube Quality Gate Status for project 'gcp-guestbook'..."
                            STATUS=$(curl -s -u $SONAR_TOKEN: "http://136.85.111.72:9000/api/qualitygates/project_status?projectKey=gcp-guestbook" | python3 -c "import sys, json; print(json.load(sys.stdin)['projectStatus']['status'])")
                            
                            echo "--------------------------------------------------"
                            echo "SonarQube Quality Gate Result: $STATUS"
                            echo "--------------------------------------------------"
                            
                            if [ "$STATUS" = "ERROR" ]; then
                                echo "ERROR: SonarQube Quality Gate FAILED! Aborting deployment."
                                exit 1
                            fi
                        '''
                    }
                }
            }
        }

        stage('GCP Authentication & Docker Config') {
            steps {
                container('gcloud') {
                    withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GCP_KEY_PATH')]) {
                        sh '''
                            gcloud auth activate-service-account --key-file=$GCP_KEY_PATH
                            gcloud config set project $PROJECT_ID
                        '''
                    }
                }
            }
        }

        stage('Get GKE Credentials & Deploy') {
            steps {
                container('gcloud') {
                    withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GCP_KEY_PATH')]) {
                        sh '''
                            gcloud auth activate-service-account --key-file=$GCP_KEY_PATH
                            gcloud container clusters get-credentials $GKE_CLUSTER --zone $GKE_ZONE --project $PROJECT_ID
                            
                            # Dynamically update container image tag in deployment manifest
                            sed -i "s|image: .*gcp-guestbook:.*|image: ${IMAGE_TAG}|g" k8s-deployment.yaml
                            
                            # Deploy to GKE
                            kubectl apply -f k8s-deployment.yaml
                            kubectl rollout status deployment/gke-guestbook -n guestbook-app
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            sh "docker rmi ${IMAGE_TAG} || true"
        }
        success {
            echo "Successfully built and deployed gcp-guestbook to GKE via Jenkins!"
        }
        failure {
            echo "Jenkins Pipeline build failed. Please check build logs."
        }
    }
}
