# Concurrent pipeline deploys clobber firewall rules
## Source: Docs/Trouble-shooting/Concurrent pipeline deploys clobber firewall rules.md

## Troubleshooting concurrent staging deployments overwriting each other's firewall rules

### Symptom
When running `badminton_court-staging` and `humrine_site-staging` pipelines simultaneously, one deployment breaks the other's firewall rule. Symptoms include:

- One app's staging URL becomes unreachable mid-deploy
- The GCP load balancer health check fails for one app
- Firewall rule `allow-web-https-staging` keeps getting recreated with different ports
- Error: `Invalid value for field 'resource.name': 'allow-web-https-humrine_site-staging'. Must be a match of regex '(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)'`

### Root Cause
Two distinct bugs:

#### Bug 1: Shared firewall rule name
In `deploy.js`, the firewall rule name was:
```javascript
const ruleName = `allow-web-https-${target}`;
```

Both apps used the same rule name (`allow-web-https-staging`). When both pipelines ran simultaneously:
1. App A checks the rule → sees App B's port → "port mismatch – recreating" → deletes & recreates with its own port
2. App B's traffic is now blocked
3. App B does the same thing back
4. Whichever finished last "won" the rule, the other's port stayed closed

#### Bug 2: Underscores in GCP resource names
The initial fix used `allow-web-https-${appName}-${target}`, but `humrine_site` contains an underscore. GCP firewall rule names must match `[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?` — no underscores allowed.

### Diagnostic Steps

1. **List existing firewall rules:**
   ```bash
   gcloud compute firewall-rules list --project=project-39c0ea08-238b-47b5-915 \
     --filter="name:allow-web-https" \
     --format="table(name,allowed[0].ports,targetTags)"
   ```

2. **Check if both apps use the same rule name:**
   ```bash
   grep -n "ruleName\|allow-web-https" gocd-server/Scripts/deploy.js
   ```

3. **Verify the rule name regex compliance:**
   ```bash
   # Should match: [a-z](?:[-a-z0-9]{0,61}[a-z0-9])?
   echo "allow-web-https-humrine_site-staging" | grep -qE '^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$' && echo "VALID" || echo "INVALID (has underscore)"
   ```

### Fix

#### Step 1: Use app-scoped, GCP-safe firewall rule names

In `gocd-server/Scripts/deploy.js`, find the firewall rule block (inside the nginx setup section):

```javascript
if (GCP_PROJECT_ID) {
  const ruleName = `allow-web-https-${target}`;
  // ...
}
```

Replace with:

```javascript
if (GCP_PROJECT_ID) {
  // Firewall rule name is app-scoped so concurrent deploys of different apps
  // don't collide on a shared rule name and clobber each other's port.
  // GCP resource names must match [a-z](?:[-a-z0-9]{0,61}[a-z0-9])? — no underscores,
  // so replace any underscores in the app name with hyphens (e.g. "humrine_site" → "humrine-site").
  const gcpSafeAppName = appName.replace(/_/g, '-');
  const ruleName = `allow-web-https-${gcpSafeAppName}-${target}`;
  // ...
}
```

The key changes:
1. **`gcpSafeAppName = appName.replace(/_/g, '-')`** — converts `humrine_site` → `humrine-site`
2. **`ruleName` includes the app name** — each app gets its own rule

#### Step 2: Clean up old orphaned firewall rules (one-time)

After the first deploy with the new naming, delete the old shared rules:
```bash
gcloud compute firewall-rules delete allow-web-https-staging allow-web-https-production \
  --project=project-39c0ea08-238b-47b5-915
```

### Resulting Firewall Rule Names

| App | Target | Rule Name | Port |
|-----|--------|-----------|------|
| `badminton_court` | staging | `allow-web-https-badminton-court-staging` | 8003 |
| `badminton_court` | production | `allow-web-https-badminton-court-production` | 8004 |
| `humrine_site` | staging | `allow-web-https-humrine-site-staging` | 8005 |
| `humrine_site` | production | `allow-web-https-humrine-site-production` | 8008 |

All match the GCP regex `[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?` — lowercase letters, digits, and hyphens only.

### Verification

1. **Trigger both staging pipelines simultaneously** — they should not interfere with each other.

2. **Verify both apps' firewall rules exist:**
   ```bash
   gcloud compute firewall-rules list --project=project-39c0ea08-238b-47b5-915 \
     --filter="name:allow-web-https" \
     --format="table(name,allowed[0].ports)"
   ```
   Should show 4 rules (2 apps × 2 environments), each with its own port.

3. **Verify both staging URLs are reachable:**
   ```bash
   curl -sk -o /dev/null -w "%{http_code}\n" https://humrine.com/court-staging/
   curl -sk -o /dev/null -w "%{http_code}\n" https://humrine.com/
   ```

### Related Files
- `gocd-server/Scripts/deploy.js` — the firewall rule creation logic
- `gocd-server/.env.docker` — `WEB_HOST_PORT_BADMINTON_STAGING=8003`, `WEB_HOST_PORT` (humrine staging)=8005
