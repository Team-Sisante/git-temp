# gh Commands
## How to use the GitHub API to list Environment variables
```bash
# set the target repository
targetRepo=repos/team-sisante/badminton_court/environments/staging
# unset the current GITHUB_TOKEN
unset GITHUB_TOKEN

# Export the env vars from .env.common file to the current terminal
while read -r line; do export "$line"; done < <(grep -E '^[A-Za-z0-9_]+=' .env.common)

# Export the env vars from .env.staging file to the current terminal
while read -r line; do export "$line"; done < <(grep -E '^[A-Za-z0-9_]+=' .env.staging)


# Display the staging environment properties
GITHUB_TOKEN=$GITHUB_TOKEN gh api $targetRepo

# Display the staging environment variables per page
GITHUB_TOKEN=$GITHUB_TOKEN gh api "$targetRepo/variables"

# Display the staging environment secrets per page
GITHUB_TOKEN=$GITHUB_TOKEN gh api "$targetRepo/secrets"

# Display the staging environment - all pages
GITHUB_TOKEN=$GITHUB_TOKEN gh api --paginate "$targetRepo/variables" --jq '.variables'

# Display a single env var value
GITHUB_TOKEN=$GITHUB_TOKEN gh api "$targetRepo/variables/ADMIN_EMAIL" --jq '.value'
```