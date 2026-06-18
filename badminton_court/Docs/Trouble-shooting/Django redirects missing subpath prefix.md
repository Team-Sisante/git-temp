# Django redirects missing subpath prefix
## Source: Docs/Trouble-shooting/Django redirects missing subpath prefix.md

## Troubleshooting Django redirects missing the subpath prefix behind a reverse proxy

### Symptom
After deploying badminton_court to staging at `https://humrine.com/court-staging/`, login redirects go to the wrong URL:

```
Expected: https://humrine.com/court-staging/dashboard/
Actual:   https://humrine.com/court/dashboard/  →  404 (hits humrine app, not badminton)
```

The redirect URL is missing the `/court-staging` prefix, causing the request to hit the wrong vhost on the reverse proxy.

### Root Cause
Two issues:

#### Issue 1: `FORCE_SCRIPT_NAME` not always defined
In `badminton_court/settings/base.py`:
```python
DOMAIN_PREFIX = require_env('DOMAIN_PREFIX', default='')
if DOMAIN_PREFIX:
    FORCE_SCRIPT_NAME = DOMAIN_PREFIX
```

`FORCE_SCRIPT_NAME` was only defined when `DOMAIN_PREFIX` was non-empty. Other settings modules trying to import it would fail with `AttributeError` when in dev (no prefix).

#### Issue 2: Hardcoded redirect URLs without prefix
In `badminton_court/settings/social_auth.py`:
```python
LOGIN_REDIRECT_URL = '/court/dashboard/'           # ← missing /court-staging
LOGOUT_REDIRECT_URL = '/accounts/login/'           # ← missing /court-staging
```

When `FORCE_SCRIPT_NAME` is set, Django's `reverse()` automatically prepends it. But **hardcoded strings used as redirect targets are NOT prefixed automatically** — Django uses them verbatim.

### Diagnostic Steps

1. **Check what URL Django redirects to:**
   ```bash
   curl -sk -I https://humrine.com/court-staging/dashboard/ | grep -i location
   ```
   - ❌ `Location: /accounts/login/?next=/court/dashboard/` (missing prefix)
   - ✅ `Location: /court-staging/accounts/login/?next=/court-staging/dashboard/` (correct)

2. **Check the Django settings:**
   ```bash
   DJANGO_SETTINGS_MODULE=badminton_court.settings ENVIRONMENT=staging python manage.py shell -c "
   from django.conf import settings
   print('FORCE_SCRIPT_NAME:', getattr(settings, 'FORCE_SCRIPT_NAME', 'NOT SET'))
   print('LOGIN_REDIRECT_URL:', getattr(settings, 'LOGIN_REDIRECT_URL', 'NOT SET'))
   print('LOGIN_URL:', getattr(settings, 'LOGIN_URL', 'NOT SET'))
   "
   ```

3. **Check the URL patterns** — confirm the dashboard route name:
   ```bash
   grep "dashboard" badminton_court/urls.py court_management/urls.py
   ```
   If the route is `path('dashboard/', ...)` (not `path('court/dashboard/', ...)`), then `LOGIN_REDIRECT_URL` should be `/dashboard/`, not `/court/dashboard/`.

### Fix

#### Step 1: Always define `FORCE_SCRIPT_NAME` in `base.py`

In `badminton_court/settings/base.py`, find:
```python
DOMAIN_PREFIX = require_env('DOMAIN_PREFIX', default='')
if DOMAIN_PREFIX:
    FORCE_SCRIPT_NAME = DOMAIN_PREFIX
```

Replace with:
```python
DOMAIN_PREFIX = require_env('DOMAIN_PREFIX', default='')
FORCE_SCRIPT_NAME = DOMAIN_PREFIX  # '' in dev, '/court-staging' in staging

# Trust reverse proxy headers
USE_X_FORWARDED_HOST = True
USE_X_FORWARDED_PORT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```

#### Step 2: Prefix all auth URLs in `social_auth.py`

In `badminton_court/settings/social_auth.py`, find the hardcoded URLs:
```python
LOGIN_REDIRECT_URL = '/court/dashboard/'
LOGOUT_REDIRECT_URL = '/accounts/login/'
```

Replace with:
```python
from .base import FORCE_SCRIPT_NAME
SCRIPT_NAME = FORCE_SCRIPT_NAME or ''

LOGIN_REDIRECT_URL = f'{SCRIPT_NAME}/dashboard/'          # ← Removed /court, added prefix
LOGOUT_REDIRECT_URL = f'{SCRIPT_NAME}/accounts/login/'
LOGIN_URL = f'{SCRIPT_NAME}/accounts/login/'
ACCOUNT_EMAIL_CONFIRMATION_ANONYMOUS_REDIRECT_URL = f'{SCRIPT_NAME}/accounts/login/'
ACCOUNT_EMAIL_CONFIRMATION_AUTHENTICATED_REDIRECT_URL = f'{SCRIPT_NAME}/'
```

**Key changes:**
1. `SCRIPT_NAME` is `''` in dev (no prefix) or `'/court-staging'` in staging
2. All URLs use `f'{SCRIPT_NAME}/...'` so they're prefixed correctly
3. Removed the leftover `/court` segment from `LOGIN_REDIRECT_URL` (the route is `dashboard/`, not `court/dashboard/`)

#### Step 3: Rebuild and redeploy

1. Commit & push the settings changes
2. Trigger `badminton_court-artifacts` pipeline
3. Trigger `badminton_court-staging` pipeline

### Why `FORCE_SCRIPT_NAME` Matters

When Django is mounted behind a path-based reverse proxy (e.g., `humrine.com/court-staging/` → `web-staging:8000/`), it needs to know its base path so:
- `reverse()` generates URLs with the prefix
- Redirects include the prefix
- `LOGIN_URL` (used by `@login_required`) includes the prefix

Without `FORCE_SCRIPT_NAME`, Django thinks it's running at the root, so redirects go to `/dashboard/` instead of `/court-staging/dashboard/`.

### The `USE_X_FORWARDED_HOST` Setting

This tells Django to trust the `X-Forwarded-Host` header from the reverse proxy. Without it, `request.get_host()` returns the internal hostname (`web-staging`), not the public hostname (`humrine.com`), which breaks absolute URL generation.

### Verification

After redeployment:
```bash
# Should return a 302 with prefixed Location
curl -sk -I https://humrine.com/court-staging/dashboard/ | grep -i location
# Expected: Location: /court-staging/accounts/login/?next=/court-staging/dashboard/
```

### Related Files
- `badminton_court/settings/base.py` — `FORCE_SCRIPT_NAME` definition
- `badminton_court/settings/social_auth.py` — `LOGIN_REDIRECT_URL`, `LOGOUT_REDIRECT_URL`, `LOGIN_URL`
- `badminton_court/badminton_court/urls.py` — URL patterns (confirm route names)
- See also: [NoReverseMatch for 'index' or 'profile' URL names](NoReverseMatch%20for%20URL%20names.md)
