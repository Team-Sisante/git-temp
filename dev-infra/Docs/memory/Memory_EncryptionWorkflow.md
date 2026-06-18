# Memory Detail: Environment Encryption and Commit Workflow

## Issue Summary
To maintain repository security, the project enforces a strict policy for handling environment variables. Functional `.env` files contain secrets and MUST NOT be committed to git.

## Files and Version Control
- **`.env.<env>`**: Functional configuration (contains secrets). **NEVER COMMIT.**
- **`.env.<env>.enc`**: Encrypted version of the functional file. **COMMIT.**
- **`.env.<env>.safe`**: Sanitized version with secrets replaced by `<hidden>`. **COMMIT.**
- **`.env.<env>.template`**: Template structure using `<?var?>` and `<?secret?>`. **COMMIT.**

## Menu Utility Options
- **13.5 (Encrypt):** Encrypts the functional `.env` files into `.enc` files and updates `.safe` and `.template` versions.
- **13.6 (Decrypt):** Restores functional `.env` files from `.enc` files.
- **13.12 (Migration):** Migrates configuration/setup to GitHub staging/production environments.
- **13.13 (GCP Migration):** Migrates secrets to GCP Secret Manager.

## Workflow Rules for Commit
1. **Never Commit Secrets:** Do not commit any functional `.env` files.
2. **Always Encrypt First:** Before committing, you MUST run option 13.5 to ensure that the encrypted (`.enc`), safe (`.safe`), and template (`.template`) files are fully updated based on the current functional `.env` file.
3. **Validate:** Verify that `.env.*.safe` and `.env.*.template` are synchronized with `.env.*` before staging changes.
4. **Permissions:** Never stage or commit changes without explicit user permission.
