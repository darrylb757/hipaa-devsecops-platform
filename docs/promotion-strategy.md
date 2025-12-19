# Environment Promotion Strategy

- Artifacts are built once
- The same artifact is promoted across environments
- No rebuilding between stages
- Configuration differences handled via overlays/values

This ensures reproducibility and auditability.
