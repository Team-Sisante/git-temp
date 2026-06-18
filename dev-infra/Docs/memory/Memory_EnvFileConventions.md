# Memory Detail: Environment File Conventions

## Issue Summary
The project maintains environment configurations using three distinct types of files for each environment (e.g., `docker`, `staging`, `production`, `test.docker`):
1. `.env.<env>`: Functional configuration file (contains sensitive values). **Must not be committed.**
2. `.env.<env>.safe`: Sanitized version of the configuration file. Sensitive values are replaced with `<hidden>`. **Committed to repo.**
3. `.env.<env>.template`: Template file used by `Scripts/generate-env.js` to build the functional `.env` file. Sensitive values use `<?secret?>`, public values use `<?var?>`. **Committed to repo.**

## Automation and Maintenance Rules
1.  **Strict Synchronization:** Any change to the structure, ordering, or commenting of variables in `.env.<env>` (including `.env.test.docker`) must be mirrored in `.env.<env>.safe` and `.env.<env>.template`.
2.  **Secret Masking:**
    -   `.env.<env>.safe` must use `<hidden>` for all sensitive values.
    -   `.env.<env>.template` must use `<?secret?>` for all sensitive values and `<?var?>` for public variables.
3.  **Naming Convention:** All memory files must be prefixed with `Memory_` (e.g., `Memory_EnvFileConventions.md`).
4.  **No Duplication:** Do not duplicate variables between `.env.common` and `.env.<env>` files. Shared variables go in `common`.
5.  **Environment Loading:** Always use explicit environment file loading in `docker compose` commands: 
    `docker compose --env-file .env.common --env-file .env.<env> ...`
