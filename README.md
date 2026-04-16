# Moonshot — GKE Deployment with Ansible

![Ansible](https://img.shields.io/badge/IaC-Ansible-red?logo=ansible)
![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?logo=kubernetes)
![GKE](https://img.shields.io/badge/Cloud-Google_Kubernetes_Engine-4285F4?logo=google-cloud)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791?logo=postgresql)
![JMeter](https://img.shields.io/badge/Load_Testing-JMeter-D22128?logo=apachejmeter)
![License](https://img.shields.io/badge/License-MIT-green)

This project automates the provisioning, deployment, and testing of the **Moonshot** application on **Google Kubernetes Engine (GKE)** using **Ansible** playbooks and roles. It covers the full lifecycle: cluster creation, application deployment with persistent PostgreSQL storage, Horizontal Pod Autoscaling (HPA), load testing with JMeter, and Google Cloud Monitoring dashboards.

---

## Goal

To provide a fully automated Infrastructure-as-Code (IaC) solution that:
- Provisions a GKE cluster on Google Cloud Platform;
- Deploys the Moonshot application and its PostgreSQL database on Kubernetes;
- Configures persistent storage and HPA for scalability;
- Validates the deployment through a suite of automated Ansible tests;
- Supports load testing via Apache JMeter;
- Provisions a Google Cloud Monitoring dashboard for observability.

---

## Tech Stack

**Infrastructure & Orchestration:**
- Google Kubernetes Engine (GKE)
- Kubernetes (Deployments, Services, PVCs, HPA)
- Ansible (playbooks + roles)

**Application & Database:**
- Moonshot (containerised via Docker — `hvaz18/ascn:latest`)
- PostgreSQL

**Load Testing:**
- Apache JMeter 5.6.3

**Local Development:**
- Docker & Docker Compose

**Observability:**
- Google Cloud Monitoring (custom dashboard via `dashboard.json`)

---

## Prerequisites

- `ansible` installed locally with the `kubernetes.core` and `google.cloud` collections
- `gcloud` CLI authenticated with a service account JSON key
- `kubectl` configured (updated automatically during cluster creation)
- Python packages: `kubernetes`, `packaging` (installed by the `install-k8s` role)
- A GCP project with GKE API enabled

---

## Configuration

Edit [`inventory/gcp.yml`](inventory/gcp.yml) to match your GCP environment:

```yaml
gcp_project: <your-gcp-project-id>
gcp_cred_file: ~/your-service-account.json
gcp_zone: us-central1-a
gcp_machine_type: e2-medium
gcp_disk_size_gb: 100
gcp_initial_node_count: 2
```

Sensitive variables (database credentials, etc.) are stored in [`group_vars/all.yml`](group_vars/all.yml) and encrypted with **Ansible Vault**.

---

## Deployment Instructions

### 1. Create the GKE cluster

```bash
ansible-playbook gke-cluster-create.yml
```

### 2. Deploy Moonshot and all components

```bash
# With database seeding
ansible-playbook moonshot-deploy.yml -e seed_database=true

# Without database seeding (preserves existing data)
ansible-playbook moonshot-deploy.yml -e seed_database=false

# Skip HPA deployment
ansible-playbook moonshot-deploy.yml -e skip_hpa=true
```

### 3. Undeploy

```bash
# Undeploy without deleting data
ansible-playbook moonshot-undeploy.yml -e delete_data=false

# Undeploy and delete all persistent data
ansible-playbook moonshot-undeploy.yml -e delete_data=true
```

### 4. Destroy the GKE cluster

```bash
ansible-playbook gke-cluster-destroy.yml
```

---

## Testing

Run the full test suite (5 tests covering deployment, DGC creation/access, undeploy, and clean restart):

```bash
ansible-playbook test-all.yml
```

Individual tests can be run using tags:

```bash
ansible-playbook test-all.yml --tags test1   # Deploy + accessibility check
ansible-playbook test-all.yml --tags test2   # Digital Green Certificate creation/access
ansible-playbook test-all.yml --tags test3   # Undeploy + confirm inaccessibility
ansible-playbook test-all.yml --tags test4   # Redeploy with preserved data
ansible-playbook test-all.yml --tags test5   # Clean redeploy cycle
```

---

## Load Testing (JMeter)

### 1. Install JMeter

```bash
ansible-playbook installJmeter.yml
```

### 2. Run a load test

```bash
./runJmeter.sh -i <APP_IP> -t <NUM_THREADS>
```

Example:
```bash
./runJmeter.sh -i 35.222.208.250 -t 50
```

Results are saved to `/opt/jmeter/.../results.txt`. The JMeter test plan ([`MoonshotTesSimpl.jmx`](MoonshotTesSimpl.jmx)) is automatically updated with the provided IP and thread count.

---

## Monitoring

Create the Google Cloud Monitoring dashboard:

```bash
ansible-playbook createDashboard.yml
```

The dashboard definition is in [`dashboard.json`](dashboard.json).

---

## Local Development (Docker)

To run Moonshot locally without Kubernetes:

```bash
# Create network
docker network create ascn_tp

# Start PostgreSQL
docker run --name my_postgres \
  -e POSTGRES_DB=mydatabase \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  --network ascn_tp \
  -p 5432:5432 \
  -d postgres

# Build and start Moonshot
docker build -t moonshot ./docker
docker run --network ascn_tp -p 8000:8000 -it moonshot
```

---

## Directory Structure

```
.
├── gke-cluster-create.yml      # Playbook: create GKE cluster
├── gke-cluster-destroy.yml     # Playbook: destroy GKE cluster
├── moonshot-deploy.yml         # Playbook: deploy all components
├── moonshot-undeploy.yml       # Playbook: undeploy all components
├── test-all.yml                # Playbook: run full test suite
├── installJmeter.yml           # Playbook: install JMeter + OpenJDK 19
├── createDashboard.yml         # Playbook: provision GCloud dashboard
├── runJmeter.sh                # Script: run JMeter load tests
├── MoonshotTesSimpl.jmx        # JMeter test plan
├── dashboard.json              # Google Cloud Monitoring dashboard config
├── inventory/
│   └── gcp.yml                 # Inventory + cluster/app variables
├── group_vars/
│   └── all.yml                 # Global variables (Vault-encrypted)
├── docker/
│   ├── Dockerfile              # Moonshot Docker image
│   └── moonshot-main/          # Moonshot application source
└── roles/
    ├── gke_cluster_create/     # GKE cluster provisioning
    ├── gke_cluster_destroy/    # GKE cluster teardown
    ├── install-k8s/            # Python/k8s dependencies
    ├── create-node-dir/        # Node directory setup
    ├── k8s-storage/            # Persistent Volumes provisioning
    ├── postgres-deployment/    # PostgreSQL Deployment
    ├── postgres-pvc/           # PostgreSQL PersistentVolumeClaim
    ├── postgres-service/       # PostgreSQL Service
    ├── moonshot-service/       # Moonshot LoadBalancer Service
    ├── run_moonshot/           # Moonshot Deployment
    ├── deploy_hpa/             # Horizontal Pod Autoscaler
    ├── test_moonshot/          # Test roles (service, DGC)
    └── undeploy-all/           # Teardown all resources
```

---

## Contributors

This project was developed by students from the University of Minho as part of the curricular unit **Cloud and Network Applications (ASCN)**, under the **Application Engineering** track.

| Name | Univ. Id |
|------|----------|
| [Gonçalo Marinho](https://github.com/gmarinhog165) | PG55945 |
| [Henrique Vaz](https://github.com/Vaz7) | PG55947 |
| [Mike Pinto](https://github.com/mrmikept) | PG55987 |

---

## License

This project is licensed under the **MIT License**.
