# Memory Detail: Security Hooks Workflow

## Issue
Git hooks are not version-controlled and are not present when cloning a new repository. This leaves repositories vulnerable if the pre-commit security hook is not installed.

## Automation Strategy
1. **Hook Installation Script:** A dedicated `Scripts/install-hooks.sh` script will be added to each repository. This script handles the linking of the security pre-commit hook to the `.git/hooks` directory.
2. **Bootstrap Integration:** The project's main bootstrap/setup files (`setup.sh`, `bootstrap.ps1`) will be updated to invoke `Scripts/install-hooks.sh` during the initial project setup.
3. **Enforcement:** By integrating this into the setup workflow, all developers/environments will have the security hooks installed automatically upon cloning and initializing the repository.

## Status
- **Plan:** Defined.
- **Implementation:** Pending creation of `install-hooks.sh` and update of `setup.sh`.
