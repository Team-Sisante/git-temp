# Google Cloud Secret Manager Commands

## Troubleshooting TLS CA Certificate Errors (Git Bash Windows)
If `gcloud` crashes with an `OSError: Could not find a suitable TLS CA certificate bundle` when running inside Git Bash, fix your local environment and certificate configurations using the steps below.

```bash
# 1. Clear any broken custom bundle variables causing path conflicts
unset REQUESTS_CA_BUNDLE
unset CURL_CA_BUNDLE

# 2. Tell gcloud's configuration engine exactly where a valid bundle is located
gcloud config set core/custom_ca_certs_file "C:\Program Files\Git\usr\ssl\certs\ca-bundle.crt"
```

---

## Listing Secrets
To list all available secret entries within your active Google Cloud project:

```bash
gcloud secrets list
```

---

## Accessing Secret Values
To view or download the actual plaintext string value contained inside a specific secret version, target its payload version (`latest` or a specific index like `1`).

### 1. Print the plaintext value directly to the terminal
```bash
gcloud secrets versions access latest --secret="humrine_site_ADMIN_PASSWORD"
```

### 2. Export a secret value directly to a local file
```bash
gcloud secrets versions access latest --secret="humrine_site_ADMIN_PASSWORD" > admin_password.txt
```