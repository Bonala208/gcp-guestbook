# GCP Cloud Guestbook (Terraform & GKE Standard)

A production-ready Python application built with **Streamlit** and **psycopg2**, backed by a managed **GCP Cloud SQL (PostgreSQL)** database, and provisioned on **GKE Standard (2 nodes)** using **Terraform**. 

This repository implements the **Cloud SQL Auth Proxy sidecar pattern** and **Kubernetes Secrets** for secure database connections without exposing public firewall rules.

---

## Technical Highlights
1. **Secure Database Connectivity (Sidecar Pattern):** Integrates the Google `cloud-sql-proxy` container alongside the Streamlit app to establish local loopback (`127.0.0.1:5432`) TLS tunnels, closing all public database firewalls.
2. **Kubernetes Secret Management:** Avoids plain-text credentials in code repositories by injecting database passwords dynamically via Kubernetes `Secret` resources.
3. **Infrastructure as Code (Terraform):** Declares and provisions the GKE Standard cluster (zone `asia-southeast1-b`), Cloud SQL PostgreSQL database, and GCP Artifact Registry repositories.
4. **Resiliency and Performance:** Features sticky sessions (`sessionAffinity: ClientIP`) on the LoadBalancer and a Pod Disruption Budget (`pdb.yaml`) to ensure seamless rolling updates.
5. **SIGSEGV Crash Avoidance:** Removed Pandas and Matplotlib dependencies to shrink the container footprint (~50MB compressed) and avoid emulation segfaults on Apple Silicon (M1/M2/M3) cross-compilations.

---

## Directory Structure
```text
gcp-guestbook/
├── terraform/                  # Infrastructure as Code (GCP Provider)
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── app.py                      # Streamlit Guestbook UI & Database connection
├── Dockerfile                  # Container build config
├── requirements.txt            # Python dependencies
├── k8s-deployment.yaml         # Kubernetes Deployment, Service, and Sidecar manifest
├── pdb.yaml                    # PodDisruptionBudget manifest
└── README.md
```

---

## Quick Start & Local Development

### 1. Run PostgreSQL locally via Docker
```bash
docker run --name guestbook-postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres
```

### 2. Set Local Environment Variables & Run
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

export DB_HOST="localhost"
export DB_NAME="postgres"
export DB_USER="postgres"
export DB_PASSWORD="password"
export DB_PORT="5432"

streamlit run app.py
```

---

## Deploying to GCP

### 1. Initialize & Apply Terraform IaC
```bash
cd terraform
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/gcp-key.json"
terraform init
terraform apply
```

### 2. Connect `kubectl` to GKE Zonal Cluster
```bash
gcloud container clusters get-credentials guestbook-cluster --zone asia-southeast1-b
```

### 3. Setup Namespace & Kubernetes Secrets
```bash
# Create the application namespace
kubectl create namespace guestbook-app

# Set guestbook-app as the default namespace for context
kubectl config set-context --current --namespace=guestbook-app

# Create the password secret dynamically (keeps secrets out of git!)
kubectl create secret generic db-secret --from-literal=db-password="YOUR_SECURE_PASSWORD"
```

### 4. Build, Tag, and Push Docker Image
```bash
cd ..
gcloud auth configure-docker asia-southeast1-docker.pkg.dev
docker build --platform linux/amd64 -t asia-southeast1-docker.pkg.dev/pythonproject-502117/guestbook-repo/gcp-guestbook:v2 .
docker push asia-southeast1-docker.pkg.dev/pythonproject-502117/guestbook-repo/gcp-guestbook:v2
```

### 5. Deploy Manifests to GKE
```bash
kubectl apply -f k8s-deployment.yaml
kubectl apply -f pdb.yaml
```

---

## Infrastructure Teardown

To destroy all cloud resources cleanly and avoid GCP billing:

```bash
cd terraform

# Decouple the postgres user from state tracking to bypass role drop checks
terraform state rm google_sql_user.root_user

# Run destruction plan
terraform destroy
```
