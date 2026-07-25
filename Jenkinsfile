pipeline {
    agent any

    environment {
        PROJECT_ID    = 'pythonproject-502117'
        GAR_LOCATION  = 'asia-southeast1'
        GKE_CLUSTER   = 'guestbook-cluster'
        GKE_ZONE      = 'asia-southeast1-b'
        REPOSITORY    = 'guestbook-repo'
        IMAGE         = 'gcp-guestbook'
        IMAGE_TAG     = "${GAR_LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE}:${BUILD_NUMBER}"
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
                    python3 -m pip install --upgrade pip || true
                    pip install bandit || true
                    bandit -r app.py -f txt || true
                '''
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
