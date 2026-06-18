# Memory Detail: Posteio External Email Delivery Failure

## Issue Summary
The `posteio` container was unable to successfully send external emails, causing failures in authentication and password reset flows.

## Investigation Notes
- **API Failure:** Poste.io's internal REST API returned a `500 Internal Server Error` during login due to a `TypeError` in the internal Symfony `FormAuthenticator.php` (`UserBadge::__construct(): Argument #1 ($userIdentifier) must be of type string, null given`).
- **Configuration Storage:** Relay settings (`smtp_routes`) are not stored in the SQLite database but in `/data/server.ini`.
- **Initialization:** Changes to `server.ini` require invoking `/etc/cont-init.d/20-apply-server-config` to propagate settings to the Haraka SMTP service.

## Resolution
1. **Manual Injection:** Directly updated `/data/server.ini` using `sed` to inject the SMTP relay credentials:
   ```bash
   sed -i 's/smtp_routes = \".*\"/smtp_routes = \":smtp.gmail.com;587|your_user|your_password\"/' /data/server.ini
   ```
2. **Reload Configuration:** Triggered the container's configuration applicator script:
   ```bash
   /etc/cont-init.d/20-apply-server-config
   ```
3. **Automated Future Setup:** This manual process must be converted into a persistent script added to `/etc/cont-init.d/` or the container entrypoint to ensure it persists across container restarts or VM recreation.
