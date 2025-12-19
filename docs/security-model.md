# Jenkins Security Model

- No secrets stored in Jenkins UI
- No AWS access keys configured
- IAM access provided via IRSA
- Jenkins permissions scoped to deployment tasks only

This limits blast radius and supports compliance requirements.
