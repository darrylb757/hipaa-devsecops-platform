Status:
- Terraform backend created (S3 + DynamoDB + KMS)
- VPC module implemented
- Dev environment applied once and destroyed intentionally
- Next step: Re-apply dev VPC, then build EKS cluster

📌 HIPAA DevSecOps Project — Progress Note

Date: Dec 16, 2025
Phase: 3.4 — Centralized Logging (STOP POINT)

✅ Completed
Private EKS cluster (Terraform)
Managed node groups
Bastion host via SSM (no SSH)
Prometheus + Grafana via Helm
Secure access via SSM port forwarding
Fluent Bit deployed as DaemonSet
IRSA configured for Fluent Bit
Kubernetes logs successfully streaming to CloudWatch Logs
Retention policy applied
No public endpoints exposed

🔒 Security Highlights
IAM Roles for Service Accounts (IRSA)
Least privilege policies
Encrypted CloudWatch log storage
Private EKS endpoint only
Bastion access via AWS SSM
HIPAA-aligned logging posture

⏸ Paused At
Splunk output temporarily disabled (placeholder HEC)
Ready to proceed to Phase 3.5 — Alerting (Prometheus + Slack)

🗓 Next Session Plan
Disable Splunk output cleanly
Configure Alertmanager
Integrate Slack alerts
Test node failure & pod crash alerts
Document alerting + incident response