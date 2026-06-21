# Memory Detail: Humrine Site Staging Security Fix (Proxy & DEBUG)
## Event Summary
The `humrine_site` staging environment (`staging.humrine.com`) was suffering from CSRF failures and insecure session cookies. Django did not recognize proxied HTTPS requests, and `DEBUG=true` was exposed in staging.

## Investigation Notes
*   **Root Cause 1:** `SECURE_PROXY_SSL_HEADER` was commented out in `base.py`. The GCP LB -> Nginx -> Django path requires this header to trust the `X-Forwarded-Proto` flag.
*   **Root Cause 2:** `DEBUG=true` was explicitly set in the environment variables, violating security best practices and triggering `security.W018`.
*   **Tooling Note:** Diagnostics were successfully run against the VM using `sudo docker exec <container_name> <cmd>` via SSH, bypassing the need for `docker compose --env-file` which fails on the VM due to the security rule prohibiting `.env` files on the host.

## Resolution & Architectural Decision
1.  Uncommented `SECURE_PROXY_SSL_HEADER` in `base.py`.
2.  Added conditional security settings (HSTS, SECURE_SSL_REDIRECT, SESSION_COOKIE_SECURE, CSRF_COOKIE_SECURE) to `base.py` to satisfy `check --deploy`.
3.  **Decision:** `DEBUG` must never be set in static `.env` files. It has been removed from environment files. The code in `base.py` safely defaults to `DEBUG=False`. If `DEBUG=True` is needed for staging, it must be injected at runtime by the GoCD pipeline, never committed to a file.