# Day 15 — Working with Multiple Providers (Part 2)

**Terraform 30-Day Challenge** · Chapter 7 (Complete) · Modules · Docker · EKS · Kubernetes

---

## Overview

This project completes Chapter 7 and covers the most advanced provider scenarios in Terraform:

- **Modules that accept provider configurations** from their callers using `configuration_aliases`
- **Multi-cloud / multi-provider deployments** using the Docker and Kubernetes providers alongside AWS
- **Containerised workloads on EKS** — a full VPC + EKS cluster + nginx Kubernetes deployment managed entirely with Terraform

---

## Repository Structure

```
terraform-challenge-day15/
├── modules/
│   └── multi-region-app/       # Reusable module — no provider blocks inside
│       ├── versions.tf          # configuration_aliases declaration
│       ├── main.tf              # S3 buckets using aws.primary and aws.replica
│       ├── variables.tf
│       └── outputs.tf
│
├── live/                        # Root config — defines providers, calls module
│   ├── versions.tf
│   ├── main.tf                  # Provider definitions + providers map in module call
│   ├── variables.tf
│   └── outputs.tf
│
├── docker/                      # Docker provider — nginx container on localhost
│   ├── versions.tf
│   ├── main.tf
│   └── outputs.tf
│
├── eks/                         # AWS EKS cluster + Kubernetes nginx deployment
│   ├── versions.tf
│   ├── main.tf                  # VPC, EKS, kubernetes_deployment, kubernetes_service
│   ├── variables.tf
│   └── outputs.tf
│
└── .gitignore
```

---

## Part 1 — Modules That Work with Multiple Providers

### The Pattern

A module **must not** define its own provider blocks. The calling root module owns all providers and passes them into the module via the `providers` map.

**Inside the module** (`modules/multi-region-app/versions.tf`):
```hcl
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}
```

`configuration_aliases` declares which provider aliases the module expects to receive. Resources inside the module reference them with `provider = aws.primary` and `provider = aws.replica`.

**In the root module** (`live/main.tf`):
```hcl
provider "aws" { alias = "primary"; region = "us-east-1" }
provider "aws" { alias = "replica"; region = "us-west-2"  }

module "multi_region_app" {
  source   = "../modules/multi-region-app"
  app_name = var.app_name

  providers = {
    aws.primary = aws.primary
    aws.replica = aws.replica
  }
}
```

The `providers` map keys must exactly match the aliases declared in `configuration_aliases`.

### Deploy

```bash
cd live/
terraform init
terraform apply
```

### Resources Deployed

| Resource | Region |
|---|---|
| `aws_s3_bucket.primary` (`day15-app-primary-bucket`) | us-east-1 |
| `aws_s3_bucket_versioning.primary` | us-east-1 |
| `aws_s3_bucket_public_access_block.primary` | us-east-1 |
| `aws_s3_bucket.replica` (`day15-app-replica-bucket`) | us-west-2 |
| `aws_s3_bucket_versioning.replica` | us-west-2 |
| `aws_s3_bucket_public_access_block.replica` | us-west-2 |

---

## Part 2 — Docker Provider

Deploy an nginx container to the local Docker daemon using the `kreuzwerker/docker` provider.

### Deploy

```bash
cd docker/
terraform init
terraform apply
```

Verify nginx is running:

```bash
# PowerShell
(Invoke-WebRequest -Uri http://localhost:8090 -UseBasicParsing).StatusCode
# Expected: 200

# Or check directly in browser
http://localhost:8090
```

Destroy the container when done:

```bash
terraform destroy
```

### Resources Deployed

| Resource | Details |
|---|---|
| `docker_image.nginx` | Pulls `nginx:latest` from Docker Hub |
| `docker_container.nginx` | Runs container named `terraform-nginx` on port `8090` |

### How the Docker Provider Differs from AWS

The AWS provider makes HTTP calls to remote AWS API endpoints. The Docker provider communicates with the local Docker daemon socket (`/var/run/docker.sock` on Linux, named pipe on Windows). It translates Terraform resource declarations into Docker Engine API calls — pull image, create container, start container — all locally.

---

## Part 3 — EKS Cluster + Kubernetes Deployment

Deploy a production-grade EKS cluster, a supporting VPC, and an nginx workload on Kubernetes — all from Terraform.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS  us-east-1                           │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │                    VPC  10.0.0.0/16                 │    │
│  │                                                     │    │
│  │  Private Subnets (EKS nodes)                        │    │
│  │  ┌──────────────────────────────────────────────┐   │    │
│  │  │            EKS Cluster  (k8s 1.29)           │   │    │
│  │  │                                              │   │    │
│  │  │  Managed Node Group — t3.small x2            │   │    │
│  │  │  ┌────────────────────────────────────────┐  │   │    │
│  │  │  │  kubernetes_deployment.nginx  (2 pods)  │  │   │    │
│  │  │  │  kubernetes_service.nginx (ClusterIP)   │  │   │    │
│  │  │  └────────────────────────────────────────┘  │   │    │
│  │  └──────────────────────────────────────────────┘   │    │
│  │                                                     │    │
│  │  Public Subnets (NAT Gateway, Load Balancers)       │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Deploy

> **Cost warning:** EKS clusters incur AWS charges (~$0.10/hr for the control plane + EC2 costs for nodes). Destroy after verifying.

```bash
cd eks/
terraform init
terraform apply
# Takes 15-20 minutes
```

### Configure kubectl after deploy

```bash
aws eks update-kubeconfig --region us-east-1 --name terraform-challenge-cluster
kubectl get nodes
kubectl get pods -n default
kubectl get svc -n default
```

### Destroy

```bash
terraform destroy
# Takes 10-15 minutes
```

### Resources Deployed

| Resource | Details |
|---|---|
| VPC | `terraform-challenge-cluster-vpc`, CIDR `10.0.0.0/16` |
| Subnets | 3 private + 3 public across 3 AZs |
| NAT Gateway | Single NAT for private subnet egress |
| EKS Cluster | `terraform-challenge-cluster`, Kubernetes 1.29 |
| Managed Node Group | `t3.small`, min 1, max 3, desired 2 |
| `kubernetes_deployment` | `nginx-deployment`, 2 replicas, `nginx:latest` |
| `kubernetes_service` | `nginx-service`, ClusterIP, port 80 |

### How the Kubernetes Provider Works

After the EKS cluster is created, the Kubernetes provider authenticates using a dynamic `exec` block:

```hcl
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
```

The `exec` block runs `aws eks get-token` at apply time to obtain a short-lived bearer token. This token is passed in the `Authorization` header of every Kubernetes API request — creating pods, services, configmaps etc. — without embedding long-lived credentials anywhere.

---

## Prerequisites

| Tool | Version |
|---|---|
| Terraform | >= 1.0.0 |
| AWS CLI | any recent version |
| Docker Desktop | v29+ |
| kubectl | any recent version (for verifying EKS) |

---

## Key Concepts Demonstrated

| Concept | Where |
|---|---|
| `configuration_aliases` in modules | `modules/multi-region-app/versions.tf` |
| `providers` map in module calls | `live/main.tf` |
| Docker provider (non-AWS) | `docker/` |
| Multi-provider in one config (AWS + Kubernetes) | `eks/` |
| `exec` block for dynamic token auth | `eks/main.tf` |
| EKS managed node groups via module | `eks/main.tf` |

---

## Challenge

**30-Day Terraform Challenge** — Day 15  
**Topic:** Working with Multiple Providers — Part 2  
**Source:** *Terraform: Up & Running* by Yevgeniy Brikman — Chapter 7
