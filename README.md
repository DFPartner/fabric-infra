# k3s-df: Argo CD App-of-Apps Setup

This repository contains the Infrastructure as Code (IaC) and Application definitions for a Kubernetes cluster managed by Argo CD.

## Documentation

We have prepared detailed documentation for different audiences:

*   **[Managerial Overview](docs/OVERVIEW.md)**: High-level explanation of the "App-of-Apps" pattern and its benefits.
*   **[Technical Architecture](docs/ARCHITECTURE.md)**: Detailed breakdown of the repository structure and how components interact.
*   **[Runbook](docs/RUNBOOK.md)**: Operational guides for updates, debugging, and maintenance.

## Quick Start

### Prerequisites
*   A Linux machine (or VM) to act as the node.
*   `sudo` access.

### Installation
The `00-bootstrap/` directory contains the scripts to install K3s and Argo CD from scratch.
```bash
# Initialize the cluster and install Argo CD
make init
```
*(Note: `make init` simply applies the manifests in `00-bootstrap/`. You may need to run `00-bootstrap/install-base.sh` manually first if you don't have K3s installed yet.)*

If installing the local version, install the sealed-secrets controller first with the monitoring disabled, and enable it later when Prometheus is installed:
```yaml
sealed-secrets:
  fullnameOverride: sealed-secrets-controller
  
  podSecurityContext:
    enabled: true
    fsGroup: 65534
  
  metrics:
    serviceMonitor:
      enabled: false  # <--- SET THIS TO FALSE
      namespace: monitoring
```

### Accessing Dashboards
To access the Grafana dashboard:
```bash
make monitoring
```
Then open `http://localhost:3000`.

To get the Grafana admin password:
```bash
make get-secret
```

## Repository Structure

*   `00-bootstrap`: Initial cluster setup.
*   `apps/templates`: Argo CD Application definitions.
*   `platform`: Helm charts and configuration for infrastructure components.
*   `root-app.yaml`: The main entry point for Argo CD.
