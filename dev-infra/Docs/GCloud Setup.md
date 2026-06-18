# Google Cloud CLI: Local Windows Setup Guide
*A guide for transitioning from Cloud Shell to a Local Environment*

## 1. Installation
1. **Download:** Obtain the Google Cloud CLI Windows Installer.
2. **Install Path:** Install to `C:\google-cloud-sdk` to prevent path-length or space-related errors.
3. **Components:** Ensure "Bundled Python" is selected during installation.

## 2. Troubleshooting: SSL Certificate Errors
If you see the error: `OSError: ... /etc/ssl/certs/ca-certificates.crt`, a Linux-style environment variable is conflicting with your Windows installation.

### Permanent Fix (Node.js)
Run the following script as an **Administrator** to remove the conflicting Registry entries:

```javascript
// fix-certs.js
const { exec } = require('child_process');
const varsToClear = ['REQUESTS_CA_BUNDLE', 'CURL_CA_BUNDLE'];

varsToClear.forEach(v => {
    exec(`reg delete HKCU\\Environment /F /V ${v}`, (err) => {
        console.log(err ? `Variable ${v} not found or skipped.` : `Deleted ${v} successfully.`);
    });
});
```

### Active Session Fix (PowerShell)
To fix the error immediately in your current terminal session:
```powershell
$env:REQUESTS_CA_BUNDLE = ""
$env:CURL_CA_BUNDLE = ""
```

## 3. Environment Configuration (PATH)
If `gcloud` is not recognized, manually add the binary folder to your Windows Path:
1. Search for **"Edit the system environment variables"**.
2. Go to **Environment Variables** > **Path** > **Edit**.
3. Add: `C:\google-cloud-sdk\bin`
4. **Restart your terminal.**

## 4. Initialization
Link your local CLI to your Google Cloud account and project:

1. **Start Init:**
   ```powershell
   & "C:\google-cloud-sdk\bin\gcloud.cmd" init
   ```
2. **Login:** Authenticate via the browser window that opens.
3. **Select Project:** Choose your active project ID from the list.
4. **Default Zone:** Select a zone (e.g., `us-central1-a`). 
   *Setting a default zone is a local CLI preference and does not incur costs.*

## 5. Summary of Useful Commands
| Command | Purpose |
| :--- | :--- |
| `gcloud version` | Verify installed components and versions. |
| `gcloud auth list` | Show active accounts. |
| `gcloud config list` | Show current project, zone, and account settings. |
| `gcloud info --run-diagnostics` | Check for network and configuration issues. |

---
**Status:** Local environment fully operational. Weekly Cloud Shell limits no longer apply.
