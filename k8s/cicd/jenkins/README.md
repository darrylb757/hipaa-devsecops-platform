# Jenkins (CD)

This Jenkins instance is deployed inside Amazon EKS and is responsible for
**continuous delivery (CD)** and **environment promotion**.

CI responsibilities are intentionally handled by GitHub Actions.

## Responsibilities
- Deploy Kubernetes manifests and Helm charts
- Execute post-deployment smoke tests
- Promote releases from dev → stage → prod
- Require manual approval for higher environments

## Authentication
- Jenkins runs with a Kubernetes service account
- AWS access provided via IRSA (no static credentials)

## Why Jenkins
Jenkins is used here to demonstrate:
- Stateful CI/CD tooling on Kubernetes
- Secure IAM integration via IRSA
- Real-world CD workflows common in regulated environments


