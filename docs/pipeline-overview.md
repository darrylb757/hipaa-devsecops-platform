# Jenkins Pipeline Overview

The Jenkins pipeline implements a controlled deployment flow:

1. Deploy to dev
2. Run smoke tests
3. Manual approval gate
4. Promote to stage
5. Manual approval gate
6. Promote to prod

This mirrors enterprise change-control processes.
