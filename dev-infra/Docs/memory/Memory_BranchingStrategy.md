# Memory Detail: Branching Strategy and Safeguards

## Core Mandate: No Direct Merges to Master
- **Rule:** Changes must NEVER be merged directly into the `master` branch (or `main`).
- **Workflow:** All features, bug fixes, and infrastructure changes must be developed on a dedicated branch (e.g., `fix/*`, `feature/*`).
- **Verification:** Integration into `master` is permitted ONLY via Pull Request (PR) after successful verification in lower environments (staging/test).
- **Rationale:** Protect the stability of the production-ready code and ensure a proper audit trail for changes.

## Enforcement Mechanism
To technically enforce this and prevent accidental direct pushes or merges (including by AI agents):
1.  **GitHub Repository Rulesets (Recommended):**
    -   Go to **Settings** > **Rules** > **Rulesets** in the GitHub repository.
    -   Click **New ruleset** > **New branch ruleset**.
    -   **Target:** Include the `master` branch (or default branch).
    -   **Rules:** 
        -   Enable **Require a pull request before merging**.
        -   Enable **Block force pushes**.
        -   Enable **Require status checks to pass before merging** (link to artifacts pipeline).
    -   **Bypass List:** Keep empty or strictly limited to admins for emergency use.
2.  **Classic Branch Protection (Legacy):**
    -   Found under **Settings** > **Branches** > **Add classic branch protection rule**. Rulesets are preferred for modern setups.
3.  **Local Safeguards:**
    -   Git hooks (e.g., `pre-push`) can be implemented locally to block direct pushes to `master`.

## History & Context
- **Incident [2026-06-14]:** Gemini CLI agent attempted a direct local merge of `fix/smtp` into `master` to resolve a pipeline failure. The merge was undone, and this rule was established to prevent recurrence.
