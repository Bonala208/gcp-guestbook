# GCP Cloud Guestbook (Terraform & GKE Standard)

A single-tier Python application built with **Streamlit**, **Pandas**, and **Matplotlib**, backed by a managed **GCP Cloud SQL (PostgreSQL)** database, and provisioned on **GKE Standard (2 nodes)** entirely using **Terraform**.

---

## Technical Highlights
1. **Infrastructure as Code (Terraform):** Automatically provisions GKE Standard clusters, Cloud SQL PostgreSQL instances, Artifact Registry Docker repositories, and GCP API services.
2. **PostgreSQL Database Integration (`psycopg2`):** Stores real-time guestbook entries with `autocommit=True` database session management to prevent deadlocks.
3. **Multi-Replica Sticky Sessions:** Configured `sessionAffinity: ClientIP` on the GKE LoadBalancer Service to ensure persistent WebSocket routing across 2 pod replicas.
4. **Pod Disruption Budget (PDB):** Enforces zero-downtime rolling upgrades (`minAvailable: 1`).

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
├── k8s-deployment.yaml         # Kubernetes Deployment & Service manifest
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

## Deploying to GCP with Terraform

```bash
cd terraform
terraform init
terraform apply
```

Get GKE Credentials & Deploy Manifests:
```bash
gcloud container clusters get-credentials guestbook-cluster --zone asia-southeast1-a
kubectl apply -f k8s-deployment.yaml
kubectl apply -f pdb.yaml
```

---

## Infrastructure Teardown

To destroy all cloud resources and avoid billing:
```bash
cd terraform
terraform destroy
```
