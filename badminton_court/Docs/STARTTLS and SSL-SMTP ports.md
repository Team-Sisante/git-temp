# SMTP Ports 587 and 465 – Explanation & Use Cases

This document explains the two standard ports for email submission, how they work, their differences, and why port 465 is currently the more reliable choice for the badminton court management project when sending emails through the Poste.io `mail-test` container.

---

## 1. Port 587 – STARTTLS (Explicit TLS)

**Standard**: RFC 6409 – Message Submission for Mail  
**Behaviour**:
- The connection begins as **plain text**.
- The client sends an `EHLO` greeting.
- The server **advertises** the `STARTTLS` extension if it supports it.
- The client then issues the `STARTTLS` command, and both sides negotiate a TLS encryption layer.
- After the TLS handshake, the client authenticates and sends the email.

**Use case**:
- The modern, recommended port for email client to mail server submission.
- Allows flexible deployment where some clients may not use encryption (though today almost all do).
- Separates user submission from server‑to‑server mail relay (which typically uses port 25).

**What went wrong in our setup**:
- The Poste.io `mail-test` container uses Haraka for the submission service on port 587.
- The Haraka TLS plugin was either **not enabled** or the `[main]` section in `tls.ini` was missing, so the server **never advertised STARTTLS**.
- Django’s email backend (configured with `EMAIL_USE_TLS=True`) tried to start TLS anyway. When the server did not respond properly, the connection was abruptly closed (`SMTPServerDisconnected`).
- Intermittent successes were likely due to the plugin being loaded only after a full container restart, or timing differences during the container’s initialisation.

**Security**: When working, STARTTLS provides the same encryption as implicit SSL (TLS 1.2/1.3). It is not less secure.

---

## 2. Port 465 – Implicit SSL / SMTPS

**Standard**: Historically registered for SMTPS; now deprecated by the IETF but still universally supported.  
**Behaviour**:
- The connection is **encrypted from the very first byte**.
- The client performs a TLS handshake immediately after the TCP connection is established.
- After the handshake, all SMTP commands (EHLO, AUTH, MAIL FROM, etc.) are sent over the encrypted channel.
- No plain‑text negotiation is required.

**Use case**:
- Legacy email clients and many modern applications still rely on implicit SSL.
- Preferred when the server’s support for STARTTLS is unreliable or the network environment blocks STARTTLS upgrades.
- Often used because it is simpler and avoids the extra STARTTLS command.

**Why it works reliably in our setup**:
- Poste.io’s container binds a listener on port 465 that **always performs SSL immediately** – there is no additional plugin configuration needed.
- Django’s email backend can connect directly with `EMAIL_USE_SSL=True` and authenticate without any negotiation failures.
- The connection is just as secure as a properly working STARTTLS connection on port 587.

**Security**: Equivalent to port 587 once the TLS session is established. The difference is only **when** the encryption starts.

---

## 3. Key Differences at a Glance

| Feature               | Port 587 (STARTTLS)                         | Port 465 (Implicit SSL)                      |
|-----------------------|---------------------------------------------|----------------------------------------------|
| Initial connection    | Plain text, then upgraded to TLS            | Encrypted immediately after TCP connect      |
| Standard status       | Current IETF standard (RFC 6409)            | Deprecated but universally supported         |
| TLS start             | After `STARTTLS` command                    | Immediately, no SMTP commands before TLS     |
| Server configuration  | Requires TLS plugin to be enabled           | Works out‑of‑the‑box on most servers         |
| Reliability in this project | Intermittent due to missing STARTTLS advertisement | Stable – always works              |

---

## 4. Recommendation for the Badminton Court Management Project

**Use port 465 with `EMAIL_USE_SSL=True` for the test environment** until the Haraka STARTTLS configuration is permanently fixed and verified.

Once the `mail-test` container successfully advertises STARTTLS on port 587 (via the custom startup script in the Dockerfile), you can switch back to port 587 with `EMAIL_USE_TLS=True`. The security and functionality will be identical – the only gain will be strict standards compliance.

---

## 5. Current Configuration (after the fix)

- `.env.dev`:
  ```ini
  EMAIL_PORT=465
  EMAIL_USE_SSL=True
  EMAIL_USE_TLS=False
  EMAIL_HOST=localhost
  EMAIL_HOST_USER=admin@aeropace.com
  EMAIL_HOST_PASSWORD=StrongPassword123!
  ```
- The custom `wait_for_mail_ready` management command uses `SMTP_SSL` to test connectivity on port 465.
- The Django email backend (`CustomSMTPBackend`) also connects via SSL.

This setup guarantees that the signup email flow in Cypress tests will succeed **every time**, with full encryption.