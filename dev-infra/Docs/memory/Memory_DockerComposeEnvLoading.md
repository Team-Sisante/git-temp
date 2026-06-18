# Memory Detail: Docker Compose Environment Variable Loading

## Issue Summary
When running `docker compose` with the `--env-file` flag, it does not automatically merge or load multiple environment files (e.g., both `.env.common` and `.env.docker`). This causes "variable not set" warnings in the terminal and potential container startup failures when the `docker-compose.yml` file references variables across multiple files.

## Resolution Pattern
To ensure all required environment variables are loaded and merged, you must explicitly pass all necessary environment files to the `docker compose` command:

### Command Pattern
```bash
docker compose --env-file .env.common --env-file .env.docker up -d
```

### Key Automation Principles
- **Explicit Loading:** Never rely on implicit environment loading for multi-file configurations.
- **Order Matters:** The order of `--env-file` arguments matters, as variables in later files will override those in earlier files. Always list shared/common files before environment-specific ones.
