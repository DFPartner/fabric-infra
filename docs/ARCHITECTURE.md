# Technical Architecture

This document describes the technical structure of the repository and how the components interact.

## Directory Structure

```
├── 00-bootstrap/       # Initial cluster setup scripts and manifests
├── apps/
│   └── templates/      # Argo CD Application manifests (The "Child" apps)
├── charts/             # Local Helm charts (shared libraries)
├── platform/           # Infrastructure components (Helm values and charts)
│   ├── data/           # Databases (Postgres, Redis, SeaweedFS, etc.)
│   ├── middleware/     # Message queues and integration (NATS, etc.)
│   └── monitoring/     # Observability stack (Loki, Tempo, Grafana Alloy)
├── root-app.yaml       # The Entry Point (App-of-Apps parent)
└── makefile            # Helper commands
```

## detailed Component Breakdown

### 1. Bootstrap (`00-bootstrap/`)
This directory contains the scripts and manifests required to bring up a fresh cluster to the point where Argo CD takes over.
-   `install-base.sh`: A shell script that:
    -   Installs system dependencies and K3s.
    -   Configures `kubectl` and `helm`.
    -   Installs Argo CD.
    -   Configures Git repository credentials (`infra-repo-creds`).
    -   Applies the initial Projects and the Root App.
-   `01-namespaces.yaml`: Defines the core namespaces (e.g., `argocd`, `data`, `monitoring`).
-   `02-projects.yaml`: Defines Argo CD Projects (e.g., `platform-ops`) to group applications and set access policies.

### 2. The Root Application (`root-app.yaml`)
This is the "App of Apps". It is an Argo CD Application resource that monitors the `apps/templates/` directory of this repository.
-   **Recursive Sync:** It is configured with `recurse: true`, meaning it will find all `.yaml` files inside `apps/templates/` and its subdirectories.
-   **Self-Management:** It manages the lifecycle of the child applications.

### 3. Application Templates (`apps/templates/`)
This directory contains the definitions for the actual applications. Each file here is an `Application` CRD.
-   **Example:** `apps/templates/data/data-weed.yaml`
    -   This file tells Argo CD: "Look in `platform/data/seaweed` and deploy whatever is defined there into the `data` namespace."
-   **Decoupling:** The *definition* of the app (where to find it, where to deploy it) is here. The *implementation* (the actual Helm chart or values) is in `platform/`.

### 4. Platform Implementation (`platform/`)
This directory contains the actual Helm charts or Values files for the infrastructure components.
-   **Structure:** Organized by category (`data`, `monitoring`, `middleware`).
-   **Content:**
    -   `Chart.yaml` / `values.yaml`: Standard Helm structure.
    -   `install.sh`: (Optional) Local helper scripts for manual testing (not used by Argo CD).

### 5. Shared Charts (`charts/`)
Contains reusable local Helm charts.
-   `microservice-chart/`: A generic chart used to deploy standard microservices. This prevents code duplication by allowing multiple services to use the same template, only varying their `values.yaml`.

## Data Flow

1.  **Commit:** A user changes a value in `platform/monitoring/alloy/values.yaml` and commits to `main`.
2.  **Detection:** Argo CD (via the `mon-alloy` Application defined in `apps/templates/monitoring/mon-alloy.yaml`) detects that the source path `platform/monitoring/alloy` has changed.
3.  **Sync:** Argo CD applies the new Helm values to the cluster.
4.  **Feedback:** The status in the Argo CD UI updates to "Synced" or "Degraded" (if the update fails).
