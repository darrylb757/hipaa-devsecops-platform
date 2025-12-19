🏥 HIPAA-Aligned DevSecOps Platform on AWS EKS

A production-grade, security-first DevSecOps platform built on AWS using Terraform, Kubernetes (EKS), GitHub Actions, Jenkins, and cloud-native security patterns.

This project mirrors how regulated environments (healthcare / finance / enterprise) actually design, deploy, and operate cloud platforms — prioritizing security, auditability, least privilege, and reproducibility over shortcuts.

🚀 Project Overview

This repository contains a full DevSecOps platform, not a demo or tutorial stack.

It demonstrates how to:

Build private-by-default AWS infrastructure

Run secure Kubernetes workloads on EKS

Separate CI and CD responsibilities

Enforce DevSecOps security gates

Manage secrets without storing them in Git

Design for observability, incident response, and disaster recovery

Operate in a HIPAA-aligned, audit-friendly manner

⚠️ No real PHI is processed.
This project demonstrates HIPAA-aligned architectural controls without making compliance claims.

🧱 Architecture Summary

Core design principles

🔐 Private-by-default networking

🧠 Least-privilege IAM everywhere

📜 Everything auditable

♻️ Fully reproducible via Infrastructure-as-Code

🧪 Security enforced before deployment

High-level flow

## 🧱 Platform Architecture (AWS)

The diagram below illustrates the end-to-end DevSecOps platform, including
network segmentation, private EKS access, CI/CD flow, secrets management,
observability, and the HIPAA-aligned data layer.

![HIPAA DevSecOps Platform Architecture](docs/diagrams/platform-architecture.png)


🧩 Phased Build (Real-World Order)

This platform was built incrementally, the same way real teams do it — validating security and operability at every step.

✅ Phase 0 — Local Prerequisites

Local tooling verified before any cloud changes (Terraform, kubectl, Helm, Trivy, etc.)

This phase establishes a standardized local tooling baseline using Terraform, AWS CLI, kubectl, Helm, and security scanners. Ensuring consistent tooling reduces operator error and environment drift. In regulated environments, consistency is critical to prevent misconfigurations caused by mismatched tool versions. This phase supports reproducibility and auditability from the very beginning.

✅ Phase 1 — Secure Terraform Bootstrap

-Remote Terraform state in S3
-State locking via DynamoDB
-KMS encryption enabled
-No local state files

🔍 Why this matters: prevents drift, supports recovery, enables audits

Terraform remote state is configured using an encrypted S3 bucket with DynamoDB state locking and KMS protection. This prevents state corruption, concurrent modification issues, and accidental exposure of infrastructure metadata. Remote state also enables recovery and collaboration without relying on local files. For HIPAA-aligned environments, infrastructure state must be protected as sensitive operational data.

✅ Phase 2–4 — Networking + EKS (Private-by-Default)

-VPC with public, private, and isolated subnets
-No public EKS API endpoint
-Managed node groups in private subnets
-Control plane audit logs enabled
-IRSA (OIDC) enabled from day one

A segmented VPC is created with public, private, and isolated subnets across multiple availability zones. NAT gateways provide controlled outbound access while preventing direct inbound exposure. VPC Flow Logs are enabled to support forensic analysis and auditing. Network segmentation is a foundational HIPAA expectation to reduce lateral movement and isolate sensitive workloads.
Amazon EKS is deployed with a private-only API endpoint and no public access. Control plane audit logs are enabled to capture authentication, authorization, and API activity. Kubernetes access is intentionally restricted to clients inside the VPC via a bastion and SSM. This design eliminates unnecessary attack surface and ensures all cluster activity is auditable.


🧠 kubectl access is only possible from inside the VPC (via bastion + SSM).
This is intentional and mirrors real HIPAA / enterprise clusters.



✅ Phase 3.3–3.5 — Observability & Alerting

-Prometheus + Grafana (Helm-managed)
-CloudWatch dashboards for EKS SRE signals
-Alertmanager → Slack (CRD-based, not Helm churn)
-Observability was staged intentionally to reduce blast radius and allow controlled rollout. 

IAM Roles for Service Accounts (IRSA) are implemented to give Kubernetes workloads fine-grained AWS permissions. No static AWS credentials are stored in pods, nodes, or repositories. Each workload receives only the permissions it requires. This aligns with zero-trust principles and HIPAA’s least-privilege access expectations.

✅ Phase 5 — Secure Data Layer

-RDS (encrypted, private, backups, deletion protection)
-DynamoDB (KMS + PITR)
-S3 (KMS, versioning, lifecycle rules)

Access pattern:

❌ No credentials in Git

❌ No credentials in pods

✅ IAM Roles for Service Accounts (IRSA)

✅ Secrets Manager + KMS

The data layer consists of encrypted Amazon RDS, DynamoDB with point-in-time recovery, and versioned S3 buckets protected by KMS. All data services are private and inaccessible from the public internet. Applications authenticate using IRSA and retrieve secrets securely at runtime. Encryption, isolation, and recoverability are core HIPAA safeguards for data protection.

✅ Phase 6 — Centralized Logging (Audit & Forensics)

-CloudWatch Logs for EKS control plane and workloads
-Fluent Bit log forwarding using IRSA
-Structured log groups with retention controls
-No node-level or embedded credentials

Access pattern:

❌ No static AWS credentials in logging agents

❌ No direct log access from developer laptops

✅ IRSA-scoped IAM role for log delivery

✅ Centralized, immutable audit trail

✅ HIPAA-aligned retention and visibility

EKS control plane and application logs are centralized in CloudWatch Logs using IRSA-authenticated Fluent Bit agents. Logs are immutable, centrally stored, and configured with retention controls. No credentials are embedded in logging components or nodes. Centralized logging is required for audit evidence, incident response, and security investigations in regulated environments.

✅ Phase 7 — Observability & Alerting (SRE-Grade)

-Prometheus for cluster and workload metrics
-Grafana dashboards (private access only)
-Alertmanager for rule-based alerting
-Slack integration for incident notifications

Access pattern:

❌ No public dashboards

❌ No hardcoded webhook secrets

✅ Metrics scraped internally within the cluster

✅ Alert routing defined via CRDs (not Helm churn)

✅ Secure access via SSM tunneling

🧠 Why Phases 6–7 Matter for HIPAA & Security

Centralized logging and controlled observability are non-negotiable in regulated environments:

-Logs provide evidence during audits and incidents
-Metrics enable early detection of failures before PHI is impacted
-Restricted visibility prevents overexposure of sensitive operational data
-Alerting enforces accountability and response discipline
-These phases ensure the platform is observable without being exposed.

Prometheus collects cluster and workload metrics while Grafana provides dashboards accessible only through secure tunneling. Alertmanager routes alerts to Slack using Kubernetes-native CRDs rather than hardcoded configuration. No dashboards or metrics endpoints are publicly exposed. Controlled observability enables rapid detection of failures without increasing exposure risk.

✅ Phase 8 — Secrets Management (HIPAA-Aware)

-AWS Secrets Manager as system of record
-External Secrets Operator (ESO)
-IRSA-based authentication
-Kubernetes Secrets treated as ephemeral cache
-Rotation-ready by design

🔐 Apps never talk to AWS.
They only read Kubernetes Secrets injected securely at runtime.

AWS Secrets Manager is used as the system of record for all sensitive values, encrypted with customer-managed KMS keys. External Secrets Operator synchronizes secrets into Kubernetes as ephemeral resources using IRSA. Applications never talk directly to AWS or store secrets in code. This design supports secret rotation, auditing, and strict confidentiality requirements.

✅ Phase 9 — CI/CD Split (Senior-Level Pattern)

Capability	GitHub Actions (CI)	Jenkins (CD)

Terraform fmt/validate	✅	❌

IaC scanning	✅	❌

Image build & scan	✅	❌

Deploy to EKS	❌	✅

Environment promotion	❌	✅

Approvals & audit	❌	✅


🧠 This separation prevents Jenkins from becoming a security liability and aligns with regulated change-management workflows.

Jenkins is deployed inside the cluster using persistent storage provisioned via the EBS CSI driver. Jenkins handles controlled deployments, environment promotions, and post-deploy validation. AWS access is granted via IRSA rather than static credentials. Separating deployment from CI reduces blast radius and enforces approval-based change management.

✅ Phase 10 — Secure Microservice Deployment

-A safe demo service (patient-service) proving:
-ALB ingress
-Autoscaling (HPA)
-Namespace isolation (dev/stage/prod)
-Hardened containers (non-root, read-only FS)
-Artifact-based deployment

No PHI. Fake data only.

A demonstration microservice is deployed using hardened container images, namespace isolation, autoscaling, and ALB ingress. The service exposes only non-sensitive endpoints and processes no real PHI. This phase validates real-world deployment patterns without compliance risk. It proves the platform can safely host regulated workloads.

✅ Phase 11 — DevSecOps Security Gates

-Terraform scanning (Checkov, tfsec)
-Container scanning (Trivy)
-Kubernetes manifest validation
-GitHub OIDC → AWS (no static credentials)
-Unsafe changes never reach production.

GitHub Actions enforces security gates including Terraform validation, IaC scanning, container vulnerability scanning, and Kubernetes manifest checks. Authentication to AWS uses OIDC, eliminating long-lived credentials. Builds fail automatically on high-risk findings. This phase shifts security left and prevents unsafe changes from reaching production.

✅ Phase 12 — Disaster Recovery Design

-In-region HA (multi-AZ)
-Backup + restore procedures
-IaC rebuild strategy

Optional “pilot-light” multi-region design

Documented in:
📄 docs/dr-runbook.md

🔍 Real Troubleshooting (What This Project Proves)

-This repo intentionally documents real failures and fixes, including:
-Private EKS API access issues (expected, secure behavior)
-IRSA misconfiguration and trust-policy debugging
-Fluent Bit + CloudWatch IAM edge cases
-Helm implicit defaults causing hidden outputs
-DynamoDB encryption idempotency traps
-Runtime package installs failing in private subnets

These are real production issues that senior engineers solve — not lab exercises.

🧠 Key Design Decisions (Why This Looks “Enterprise”)

-Private EKS API → reduced attack surface
-IRSA everywhere → zero static credentials
-Artifact-based delivery → auditability & immutability
-CI/CD separation → controlled promotions
-Security gates first-class → shift-left security
-Rebuild + restore DR → reliable recovery strategy

The platform is designed for high availability using multi-AZ infrastructure and managed services. Backup, restore, and rebuild procedures are documented and testable via Infrastructure as Code. An optional pilot-light multi-region strategy is defined without incurring unnecessary cost. HIPAA requires availability, and this phase ensures recovery is predictable and auditable.

🏁 Final Status

✔ Production-grade AWS infrastructure

✔ Secure EKS platform

✔ CI + CD separation

✔ DevSecOps security gates

✔ Artifact-based delivery

✔ Observability & alerting

✔ Disaster recovery design

This is a full DevSecOps platform — not a demo.