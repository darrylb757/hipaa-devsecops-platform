# CI/CD Strategy (HIPAA DevSecOps Platform)

This platform follows a split CI/CD model aligned with real-world
enterprise DevSecOps practices.

## CI — GitHub Actions

GitHub Actions is responsible for Continuous Integration (CI).

### Responsibilities
- Terraform formatting and validation
- Terraform plan (non-destructive)
- IaC security scanning (Checkov / tfsec)
- Container image build
- Container image vulnerability scanning (Trivy)

### Why GitHub Actions
- Native GitHub integration
- Fast feedback on pull requests
- No access to production infrastructure
- Easy parallel security scanning

## CD — Jenkins on EKS

Jenkins is responsible for Continuous Delivery (CD).

### Responsibilities
- Deploy Kubernetes manifests or Helm charts
- Interact with EKS using IAM Roles for Service Accounts (IRSA)
- Run post-deployment smoke tests
- Manage environment promotions:
  - dev → stage → prod
  - Manual approvals between environments

### Security Model
- Jenkins uses IRSA (no static AWS credentials)
- Short-lived AWS credentials via OIDC
- Environment isolation enforced via namespaces

## Environment Flow

GitHub Actions (CI)
|
v
Container Registry (ECR)
|
v
Jenkins (CD)
→ dev
→ stage (approval)
→ prod (approval)


## Key Principles
- Least privilege
- Separation of duties
- Immutable artifacts
- Audit-friendly pipeline design
