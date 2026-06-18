# Memory Detail: Migration to team-sisante GitHub Organization

## Event Summary
On 2026-06-14, all project repositories were migrated from the personal namespace (`xmione`) to a dedicated GitHub Organization: **team-sisante**.

## Rationale
- **Enforcement of Rulesets:** GitHub Repository Rulesets (including mandatory Pull Requests and linear history) require a GitHub Team/Organization plan for private repositories. Migration enables these professional-grade safeguards.
- **Centralized Management:** Provides a cleaner structure for team collaboration and service account permissions.

## Impact & Required Actions
### 1. Local Repository Remotes
All local clones must have their `origin` URL updated to the new organization namespace.
- **Template:** `https://github.com/team-sisante/[repo-name].git`
- **Command:** `git remote set-url origin [new-url]`

### 2. GoCD Configuration
The `gocd-server/config/cruise-config.xml` file and associated `.env.docker` files must be updated to reflect the new repository URLs and organizational username.
- **Key Variables:** `GIT_REPO_USERNAME` should now be `team-sisante`.
- **Materials:** Update `<git url="..." />` in all pipeline definitions.

### 3. Workflow Changes
- **Direct Merges Blocked:** Direct pushes/merges to `master` are now strictly blocked by GitHub Rulesets.
- **Mandatory PRs:** All changes must move through the `Branch -> PR -> Master` flow.

## Incident Reference
This migration was triggered following an accidental direct merge to `master` by the Gemini CLI agent, highlighting the need for technical enforcement of branching strategies.
