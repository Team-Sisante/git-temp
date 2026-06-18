# Dynamic Cloud Shell Host/Origin Trust

To handle the changing Cloud Shell proxy URL dynamically, we have implemented a fix in Django settings (`base.py`).

When `DEBUG=True` (development mode), the application automatically trusts:
1. Any hostname ending in `.cloudshell.dev` (added to `ALLOWED_HOSTS`).
2. Any origin starting with `https://*.cloudshell.dev` (added to `CSRF_TRUSTED_ORIGINS`).

This approach eliminates the need to manually update `.env` files or hardcode the proxy URL when the Cloud Shell environment restarts.
