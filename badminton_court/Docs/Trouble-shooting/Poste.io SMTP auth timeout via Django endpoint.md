# Poste.io SMTP auth timeout via Django endpoint
## Source: Docs/Trouble-shooting/Poste.io SMTP auth timeout via Django endpoint.md

## Troubleshooting Poste.io SMTP auth timeouts via the Django check-smtp-auth endpoint

### Symptom
The Cypress test step `Given the mail server is ready` fails with:
```
Mail server SMTP login failed after 36 attempts. [SSL:465] Connection failed: Connection unexpectedly closed: The read operation timed out
```

But direct Python SMTP auth works:
```bash
$ python manage.py shell -c "import smtplib, ssl; ... server.login(...); print('SUCCESS')"
SMTP auth SUCCESS
```

The Django endpoint `/api/test/check-smtp-auth/` times out, but direct `smtplib` calls succeed.

### Root Cause
The `test_check_smtp_auth.py` view used `timeout=10` for the SMTP connection:
```python
with smtplib.SMTP_SSL(host, port, context=context, timeout=10) as server:
    server.login(user, password)
```

Poste.io's SSL handshake can take longer than 10 seconds, especially:
- Right after a container restart
- When the mail services are still initializing
- Under load (multiple tests hitting the endpoint simultaneously)

The direct Python test used `timeout=30` and succeeded. The endpoint's `timeout=10` was too short.

### Diagnostic Steps

1. **Test the endpoint directly:**
   ```bash
   curl -s http://localhost:8000/api/test/check-smtp-auth/
   # If it returns: {"status":"error","error":"[SSL:465] Connection failed: ... timed out"}
   # Then the endpoint timeout is too short
   ```

2. **Test direct SMTP auth (with longer timeout):**
   ```bash
   DJANGO_SETTINGS_MODULE=badminton_court.settings python manage.py shell -c "
   import smtplib, ssl
   from django.conf import settings
   context = ssl.create_default_context()
   context.check_hostname = False
   context.verify_mode = ssl.CERT_NONE
   try:
       server = smtplib.SMTP_SSL(settings.EMAIL_HOST, settings.EMAIL_PORT, context=context, timeout=30)
       server.login(settings.EMAIL_HOST_USER, settings.POSTE_ADMIN_PASSWORD)
       print('SMTP auth SUCCESS')
       server.quit()
   except Exception as e:
       print(f'SMTP FAILED: {e}')
   "
   ```
   If this succeeds with `timeout=30` but the endpoint fails with `timeout=10`, the fix is to increase the endpoint timeout.

3. **Check the view's timeout:**
   ```bash
   grep "timeout=" court_management/components/views/test_check_smtp_auth.py
   ```

### Fix

#### Step 1: Increase the timeout in `test_check_smtp_auth.py`

In `court_management/components/views/test_check_smtp_auth.py`, find all three `timeout=10`:

```python
# SSL:
with smtplib.SMTP_SSL(host, port, context=context, timeout=10) as server:
    server.login(user, password)

# STARTTLS:
with smtplib.SMTP(host, port, timeout=10) as server:
    # ...

# PLAIN:
with smtplib.SMTP(host, port, timeout=10) as server:
    server.login(user, password)
```

Change all three to `timeout=30`:

```python
# SSL:
with smtplib.SMTP_SSL(host, port, context=context, timeout=30) as server:
    server.login(user, password)

# STARTTLS:
with smtplib.SMTP(host, port, timeout=30) as server:
    # ...

# PLAIN:
with smtplib.SMTP(host, port, timeout=30) as server:
    server.login(user, password)
```

#### Step 2: Restart the Django dev server

The dev server auto-reloads when files change. If it doesn't, restart it:
```bash
# Ctrl+C the current server, then:
DJANGO_SETTINGS_MODULE=badminton_court.settings ENVIRONMENT=development python manage.py runserver 0.0.0.0:8000
```

#### Step 3: For staging — rebuild and redeploy

```bash
# Commit & push
git add court_management/components/views/test_check_smtp_auth.py
git commit -m "Fix: increase SMTP auth timeout from 10s to 30s"
git push

# Trigger pipelines
# 1. badminton_court-artifacts
# 2. badminton_court-staging
```

### Why the Direct Test Worked but the Endpoint Didn't

| Test | Timeout | Result |
|------|---------|--------|
| Direct `smtplib.SMTP_SSL(..., timeout=30)` | 30s | ✅ SUCCESS |
| Django endpoint `smtplib.SMTP_SSL(..., timeout=10)` | 10s | ❌ Timed out |

The SSL handshake to Poste.io takes 15-25 seconds in some conditions. The 10-second timeout was too short.

### If SMTP Auth Still Fails After Increasing Timeout

If the endpoint still returns 503 after increasing the timeout, the issue is likely Poste.io's SMTP service itself. See:
- [Poste.io SMTP auth fails after fresh volume reset](Poste.io%20SMTP%20auth%20fails%20after%20fresh%20volume%20reset.md)

Common fixes:
1. Restart the Poste.io container: `docker-compose restart mail-test`
2. Wait 45-60 seconds for all services to start
3. Verify SMTP auth works directly before re-running the test

### Verification

```bash
# Endpoint should return success
curl -s http://localhost:8000/api/test/check-smtp-auth/
# Expected: {"status":"ok","protocol":"SSL:465","host":"localhost"}
```

### Related Files
- `badminton_court/court_management/components/views/test_check_smtp_auth.py` — the view with the timeout
- See also: [Poste.io SMTP auth fails after fresh volume reset](Poste.io%20SMTP%20auth%20fails%20after%20fresh%20volume%20reset.md)
