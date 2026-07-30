# Kubernetes Deployment

This directory contains all Kubernetes resources and automation scripts required to deploy the **Job Application Tracker** on a local Kubernetes cluster using **Kind (Kubernetes IN Docker)**.

The deployment is fully automated and supports:

- Automatic cluster creation
- Docker image building
- Persistent storage
- Ingress routing
- Health monitoring
- Application lifecycle management
- Automated cleanup

---

# Architecture

```
                        +----------------+
                        |     Browser    |
                        +--------+-------+
                                 |
                           http://localhost
                                 |
                           NGINX Ingress
                                 |
                     +-----------+-----------+
                     |                       |
             Frontend Service         Backend Service
                     |                       |
             Frontend Pods             Backend Pod
                                             |
                                      SQLite Database
                                             |
                                      Persistent Volume
```

---

# Components

## Namespace

Creates an isolated namespace for all application resources.

```
job-tracker
```

---

## Backend

Contains:

- Deployment
- Service

Responsibilities:

- Runs Spring Boot application
- Exposes REST APIs
- Connects to SQLite persistent storage

Current replicas:

```
1
```

---

## Frontend

Contains:

- Deployment
- Service

Responsibilities:

- Runs NGINX container
- Serves React application
- Communicates with backend through Ingress

Current replicas:

```
2
```

Multiple frontend replicas provide:

- High availability
- Automatic failover
- Load balancing

---

## Storage

Creates:

- Persistent Volume
- Persistent Volume Claim

Purpose:

Persist SQLite database between pod restarts.

Without persistent storage:

```
Delete Pod
    ↓
Database Lost
```

With persistent storage:

```
Delete Pod
      ↓
Create New Pod
      ↓
Existing Database Mounted
```

---

## Ingress

Installs:

- ingress-nginx controller
- Ingress resource

Provides a single entry point:

```
http://localhost
```

Routes:

```
/                 → Frontend

/api              → Backend

/swagger-ui       → Backend

/v3/api-docs      → Backend
```

---

# Deployment Scripts

## build-cluster.sh

Creates a Kind cluster.

Responsibilities:

- Create control plane
- Create worker node
- Configure local registry access

---

## build.sh

Builds Docker images.

Builds:

- Backend image
- Frontend image

Loads images into Kind cluster.

---

## deploy.sh

Deploys application resources.

Order:

1. Namespace
2. Persistent Storage
3. Backend
4. Frontend
5. Ingress

---

## stop.sh

Stops the application.

Removes:

- Backend
- Frontend
- Ingress

Preserves:

- Namespace
- Persistent Volume
- Persistent Volume Claim
- SQLite database

Use this when you want to stop the application while keeping data.

---

## delete.sh

Deletes all Kubernetes resources.

Removes:

- Backend
- Frontend
- Ingress
- PVC
- PV
- Namespace

Leaves:

- Kind cluster

Use this when you want a fresh deployment.

---

## destroy-cluster.sh

Deletes the Kind cluster.

Removes:

- Kubernetes cluster
- Containers
- Networks

---

# Application Lifecycle

## Launch

```
Create Cluster
        ↓
Build Images
        ↓
Load Images
        ↓
Deploy Storage
        ↓
Deploy Backend
        ↓
Deploy Frontend
        ↓
Deploy Ingress
```

---

## Stop

```
Remove Ingress
        ↓
Remove Frontend
        ↓
Remove Backend
```

Database remains available.

---

## Delete

```
Stop Application
        ↓
Delete PVC
        ↓
Delete PV
        ↓
Delete Namespace
```

---

## Destroy Cluster

```
Delete Kind Cluster
```

---

# Orchestrator

The repository root contains:

```
orchestrator-kubernetes.sh
```

Supported commands:

```
launch
update
stop
health
logs
clean
help
```

Example:

```bash
./orchestrator-kubernetes.sh launch
```

---

# Persistence

SQLite uses a Persistent Volume.

Therefore:

```
Application Restart
        ↓
Data Preserved
```

Deleting only the backend pod does **not** delete the database.

Deleting the Persistent Volume **does** remove all stored data.

---

# Replica Strategy

## Backend

Current replicas:

```
1
```

Reason:

Backend uses SQLite with a ReadWriteOnce Persistent Volume.

Running multiple backend replicas could result in concurrent writes to the same database, which SQLite is not designed to handle reliably in this setup.

Future database engines such as PostgreSQL or MySQL would support scaling the backend horizontally.

---

## Frontend

Current replicas:

```
2
```

Benefits:

- High availability
- Automatic recovery
- Zero-downtime pod replacement
- Load balancing

---

# Self-Healing

Deployments continuously ensure the desired number of replicas.

Example:

```
Desired Replicas = 2

Running Pods = 2
```

If one frontend pod is deleted:

```
Delete Pod
      ↓
Deployment detects only one running pod
      ↓
Creates replacement pod
      ↓
Service automatically routes traffic
```

Users continue accessing the application while Kubernetes restores the desired state.

---

# Scaling

Increase frontend replicas by modifying:

```
frontend/deployment.yaml
```

Example:

```yaml
spec:
  replicas: 2
```

Or dynamically:

```bash
kubectl scale deployment frontend \
    --replicas=3 \
    -n job-tracker
```

---

# Verification

View pods:

```bash
kubectl get pods -n job-tracker
```

View services:

```bash
kubectl get svc -n job-tracker
```

View ingress:

```bash
kubectl get ingress -n job-tracker
```

View persistent storage:

```bash
kubectl get pv

kubectl get pvc -n job-tracker
```

View cluster:

```bash
kubectl get nodes
```

---

# Testing Resilience

Delete a frontend pod:

```bash
kubectl delete pod <frontend-pod-name> -n job-tracker
```

Watch Kubernetes recreate it:

```bash
kubectl get pods -w -n job-tracker
```

The application remains available throughout the recovery process.

---

# Technologies

- Kubernetes
- Kind
- Docker
- NGINX Ingress Controller
- Spring Boot
- React
- SQLite
- Persistent Volumes
- Kubernetes Deployments
- Kubernetes Services
- Kubernetes Ingress