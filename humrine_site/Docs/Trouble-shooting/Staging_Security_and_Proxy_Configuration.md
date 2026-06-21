# Staging Security & Proxy Configuration Fix
## Source: Docs/Trouble-shooting/Staging_Security_and_Proxy_Configuration.md
## Troubleshooting the Humrine application

### Objective
Diagnose and resolve CSRF failures and incorrect secure-flag behavior on `staging.humrine.com` when served behind a GCP Load Balancer and Nginx reverse proxy.

### Symptoms
*   Django's `request.is_secure()` returns `False` even when the user connects via `https://staging.humrine.com`.
*   CSRF validation fails on POST requests (e.g., login forms) over HTTPS.
*   `python manage.py check --deploy` outputs `security.W018` (DEBUG is True) and missing secure cookie warnings.

### Root Causes
1.  **Missing Proxy Header:** `SECURE_PROXY_SSL_HEADER` was commented out in `humrine_site/settings/base.py`. Nginx was correctly sending `X-Forwarded-Proto: https`, but Django was ignoring it, perceiving all traffic as HTTP.
2.  **Hardcoded DEBUG:** `DEBUG=true` was explicitly set in the staging environment variables, overriding the fail-safe default in code.

### Resolution
1.  **Code Change:** Uncommented `SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')` in `base.py`.
2.  **Code Change:** Added conditional production security settings (HSTS, secure cookies, SSL redirect) that activate when `DEBUG=False`.
3.  **Architectural Decision:** Removed `DEBUG` entirely from static `.env.staging` and `.env.production` files. `DEBUG` must now be set at runtime via the deployment pipeline (GoCD) or omitted entirely so the code defaults to `False`. 

### Verification
To verify this fix on the VM without needing local `.env` files, use `docker exec` directly via SSH:

```bash
# 1. Verify the app sees the request as secure
ssh -i "../gocd-server/secrets/agent-key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null xmione@35.198.231.9 \
  "sudo docker exec humrine-web-staging python manage.py shell -c \"from django.test import RequestFactory; r=RequestFactory().get('/', HTTP_X_FORWARDED_PROTO='https'); print('is_secure=', r.is_secure())\""

# 2. Verify deployment checks pass
ssh -i "../gocd-server/secrets/agent-key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null xmione@35.198.231.9 \
  "sudo docker exec humrine-web-staging python manage.py check --deploy"
```

### Result
*   `is_secure()` returns `True`.
*   `check --deploy` no longer reports W018 or W012/W016 warnings.
*   CSRF tokens validate correctly over HTTPS.