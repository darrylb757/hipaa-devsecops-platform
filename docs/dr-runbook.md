Disaster Recovery Runbook

Project: HIPAA DevSecOps Platform
Scope: Non-PHI demo workloads
Last Updated: Phase 12

1. Recovery Objectives
Component	RTO	RPO
EKS workloads	< 30 minutes	0 (stateless)
Jenkins (config + jobs)	< 1 hour	< 15 minutes
RDS (if enabled)	< 1 hour	< 5 minutes
DynamoDB	< 15 minutes	Point-in-Time
S3 artifacts	Immediate	Versioned

RTO — Recovery Time Objective
RPO — Recovery Point Objective

2. Built-In High Availability (Prevention)

Most outages are avoided entirely due to AWS managed services:

Compute & Networking

EKS worker nodes distributed across multiple AZs

AWS ALB spans multiple AZs automatically

Kubernetes self-healing (replicas, rescheduling)

Data Layer

RDS Multi-AZ

DynamoDB regional + PITR

S3 multi-AZ by default + versioning

These protections handle:

AZ failure

instance failure

pod/node crashes

3. Backup & Recovery Mechanisms
3.1 Terraform (Infrastructure)

Recovery method: Re-provision

Terraform state stored remotely

Infrastructure fully reproducible

No manual configuration required

terraform init
terraform apply

3.2 Amazon RDS

Protection

Automated backups enabled

Daily snapshots retained

Restore procedure

Restore snapshot to new RDS instance

Update application secrets / endpoints

Restart dependent workloads

3.3 DynamoDB

Protection

Point-in-Time Recovery (PITR) enabled

Restore procedure

Restore table to a new table at timestamp

Update application configuration

Validate data consistency

3.4 Amazon S3

Protection

Versioning enabled

Bucket access restricted

Encryption at rest

Restore procedure

Roll back object version

Restore deleted artifacts instantly

4. Kubernetes Workload Recovery
Stateless Services

Pods automatically rescheduled

No data loss

Zero manual intervention

Stateful Components (Jenkins)

Persistent Volumes backed by EBS

EBS CSI driver manages volume attachment

Pod reschedule restores state automatically

5. Security Incident Recovery (Non-PHI)

In case of:

compromised credentials

malicious deployment

configuration drift

Response

Revoke IAM roles / tokens

Re-deploy workloads from known-good Git commit

Rebuild infrastructure if required via Terraform

Validate with CI security gates

6. Optional Multi-Region “Pilot Light” (Future)

Not implemented by default (cost-aware), but supported by design:

Replicate S3 artifacts to secondary region

Copy RDS snapshots cross-region

Minimal standby VPC

Route53 failover records

Activation time: hours (acceptable for non-critical workloads)

7. Testing & Validation

Recommended DR testing cadence:

Terraform rebuild test (quarterly)

RDS restore test (quarterly)

DynamoDB PITR restore (quarterly)

CI pipeline redeploy from scratch (monthly)

8. Summary

This DR strategy prioritizes:

Simplicity

Auditability

Cost awareness

Fast recovery from real-world failure modes

The platform favors rebuild + restore over fragile manual recovery.