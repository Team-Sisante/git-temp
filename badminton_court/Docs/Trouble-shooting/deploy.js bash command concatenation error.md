# deploy.js bash command concatenation error
## Source: Docs/Trouble-shooting/deploy.js bash command concatenation error.md

## Troubleshooting the deploy.js `trueecho: command not found` error

### Symptom
The staging/production deployment fails with:
```
bash: line 1: trueecho: command not found
```

The deployment completes (containers start), but the last step (Poste.io relay configuration) fails because bash concatenated two commands into one invalid command.

### Root Cause
In `gocd-server/Scripts/deploy.js`, the `deployCmd` string is built by concatenating multiple bash commands. The diagnostic block ends with `|| true` and the `mailSetupCmd` block starts with `echo "..."` — but there's no ` && ` separator between them:

```javascript
const deployCmd =
  `cd ${deployDir} && ` +
  `flock ${remoteLockFile} bash -c '` +
    `${envExportString} && ` +
    `IMAGE_TAG=${imageTag} sudo -E docker compose ... up -d ...` +
    (mailContainerName ? 
    ` && echo "Diagnostic: Network bindings in container:" && ` +
    `sudo docker exec -i ${mailContainerName} netstat -tulpn || echo "netstat not available..." && sudo docker exec -i ${mailContainerName} ss -tulpn || true` : '') +
    (mailContainerName ? mailSetupCmd : '') + `'`;
    //                              ^^^ No separator! mailSetupCmd starts with "echo ..."
```

Bash sees:
```bash
... || trueecho "Syncing Poste.io admin password..." && ...
```

It tries to execute a command named `trueecho`, which doesn't exist.

### Why It Sometimes Worked
When `sudo docker exec -i ${mailContainerName} ss -tulpn` succeeded, bash short-circuited past `|| trueecho` (because `||` only evaluates the right side if the left side fails). The bug only manifested when `ss` failed — which happened when the mail container didn't exist or wasn't ready.

### Diagnostic Steps

1. **Search for the `trueecho` error in deploy logs:**
   ```
   bash: line 1: trueecho: command not found
   Deployment attempt 1 failed: Command failed: ssh ...
   ```

2. **Inspect the `deployCmd` construction in `deploy.js`:**
   ```bash
   grep -n "mailSetupCmd\|deployCmd\|trueecho" gocd-server/Scripts/deploy.js
   ```

3. **Look for the missing separator** — the line that concatenates `mailSetupCmd` should have ` && ` before it.

### Fix

#### Step 1: Add the missing ` && ` separator

In `gocd-server/Scripts/deploy.js`, find this block (near the end of the `deployCmd` construction):

```javascript
    (mailContainerName ? 
    ` && echo "Diagnostic: Network bindings in container:" && ` +
    `sudo docker exec -i ${mailContainerName} netstat -tulpn || echo "netstat not available, trying ss..." && sudo docker exec -i ${mailContainerName} ss -tulpn || true` : '') +
    (mailContainerName ? mailSetupCmd : '') + `'`;
```

Change the last line to add ` && ` before `mailSetupCmd`:

```javascript
    (mailContainerName ? 
    ` && echo "Diagnostic: Network bindings in container:" && ` +
    `sudo docker exec -i ${mailContainerName} netstat -tulpn || echo "netstat not available, trying ss..." && sudo docker exec -i ${mailContainerName} ss -tulpn || true` : '') +
    (mailContainerName ? ` && ${mailSetupCmd}` : '') + `'`;
    //                              ^^^^^^^ Add " && " here
```

The only change is:
```javascript
// Before:
(mailContainerName ? mailSetupCmd : '') + `'`;

// After:
(mailContainerName ? ` && ${mailSetupCmd}` : '') + `'`;
```

#### Step 2: Also make the relay config non-fatal (recommended)

While you're fixing this, also wrap the `node configure-poste-relay.js` call in `|| true` so a relay config failure doesn't roll back the entire deployment. In the `mailSetupCmd` definition:

```javascript
const mailSetupCmd = mailContainerName ? 
  `echo "Syncing Poste.io admin password..." && ` +
  `( sudo -E docker exec --user 8 ${mailContainerName} /opt/admin/bin/console domain:create ${process.env.POSTE_DOMAIN || 'aeropace.com'} || true ) && ` +
  `( sudo -E docker exec --user 8 ${mailContainerName} /opt/admin/bin/console email:create ${process.env.EMAIL_HOST_USER} "${process.env.POSTE_ADMIN_PASSWORD}" Admin || true ) && ` +
  `( sudo -E docker exec --user 8 ${mailContainerName} /opt/admin/bin/console email:admin ${process.env.EMAIL_HOST_USER} || true ) && ` +
  `echo "Configuring SMTP relay..." && ` +
  `( node ${deployDir}/Scripts/configure-poste-relay.js ${mailContainerName} "${process.env.POSTE_RELAY_HOST}" "${process.env.POSTE_RELAY_USER}" "${process.env.POSTE_RELAY_PASS}" "${process.env.POSTE_API_USER}" "${process.env.POSTE_ADMIN_PASSWORD}" || echo "WARNING: SMTP relay config failed, but deployment completed." )` : '';
```

#### Step 3: No rebuild needed

The `deploy.js` script is mounted read-only into the agent containers:
```yaml
- .:/gocd-server:ro
```

So changes to `deploy.js` are picked up immediately on the next pipeline run — no container rebuild required.

### Verification

After the fix, trigger the staging pipeline. The deploy logs should show:
```
Container badminton_court-nginx-staging Started
Diagnostic: Network bindings in container:
... (netstat/ss output) ...
Syncing Poste.io admin password...     ← No more "trueecho: command not found"
... (Poste.io setup output) ...
Configuring SMTP relay...
[SETUP] Login to Poste.io API attempt 1/12...
✓ Deployment completed successfully.
```

### Related Files
- `gocd-server/Scripts/deploy.js` — the `deployCmd` and `mailSetupCmd` construction
- `gocd-server/Scripts/configure-poste-relay.js` — the relay config script (may need retry logic)
