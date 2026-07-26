pipeline {
    agent { label 'rhel-agent' }

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
                sh '''
                    export PATH=$HOME/.local/bin:$PATH
                    python3 -m pip install --user --upgrade bandit
                    bandit -r app.py -f txt
                '''
            }
        }

        stage('SonarQube Code Quality & Security Scan') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        sonar-scanner \
                          -Dsonar.host.url=http://localhost:9000 \
                          -Dsonar.token=$SONAR_TOKEN \
                          -Dsonar.projectKey=gcp-guestbook \
                          -Dsonar.sources=. \
                          -Dsonar.exclusions=venv/**,.github/**,jenkins-setup/**,terraform/**
                    '''
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        echo "Querying SonarQube Quality Gate Status for project 'gcp-guestbook'..."
                        STATUS=$(curl -s -u $SONAR_TOKEN: "http://localhost:9000/api/qualitygates/project_status?projectKey=gcp-guestbook" | python3 -c "import sys, json; print(json.load(sys.stdin)['projectStatus']['status'])")
                        
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

        stage('GCP Authentication & Docker Config') {
            steps {
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GCP_KEY_PATH')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GCP_KEY_PATH
                        gcloud config set project $PROJECT_ID
                        gcloud auth configure-docker ${GAR_LOCATION}-docker.pkg.dev --quiet
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build \
                        --platform linux/amd64 \
                        -t ${IMAGE_TAG} \
                        -t ${GAR_LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE}:latest \
                        .
                '''
            }
        }

        stage('Push Image to GCP Artifact Registry') {
            steps {
                sh '''
                    docker push ${IMAGE_TAG}
                    docker push ${GAR_LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE}:latest
                '''
            }
        }

        stage('Get GKE Credentials & Deploy') {
            steps {
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
