# Resolving SSH Access to GCP VM from Windows Host Machine

## Initial Problem
- Cloud Shell displayed: "You have temporarily exceeded a Cloud Shell limit."
- Gemini AI inside Cloud Shell had automatically created a resource, consuming the weekly 50‑hour quota, locking out Cloud Shell.
- Attempts to connect to the VM (`gocd-deploy-target`) from Windows using `gcloud compute ssh` and PuTTY failed with "Permission denied (publickey)".

## Root Cause
- The VM had **OS Login enabled** (`enable-oslogin=TRUE`), but the required guest package (`google-guest-oslogin`) was **not installed**.
- The necessary IAM role `roles/compute.osLogin` was initially missing for the user `solomiosisante@gmail.com`.
- Cloud Shell quota was a separate issue; it blocked only the web‑based shell, not the `gcloud` CLI on Windows.

---

## Step‑by‑Step Resolution

### 1. Regain access to Cloud Shell (optional, for easier management)
- Wait for the 7‑day rolling quota to reset (or use the appeal form).
- Once back in Cloud Shell, set the project:
  ```bash
  gcloud config set project project-39c0ea08-238b-47b5-915
  ```

### 2. Identify the VM and its Network Reachability
- Verified VM details from Windows:
  ```powershell
  gcloud compute instances list
  ```
  Output: `gocd-deploy-target` in `us-west1-b` with external IP `35.230.13.215`.
- Network connectivity tests showed the VM was reachable on port 22.

### 3. Discover OS Login was Enabled
- Checked instance metadata:
  ```powershell
  gcloud compute instances describe gocd-deploy-target --zone=us-west1-b --format="value(metadata.items.enable-oslogin)"
  ```
  Result: `TRUE` → OS Login was active, therefore instance‑level SSH keys were ignored.

### 4. Add Missing IAM Role for OS Login
- Verified user’s IAM roles; the `roles/compute.osLogin` role was missing.
- Granted the role from Cloud Shell (or Windows with owner permissions):
  ```bash
  gcloud projects add-iam-policy-binding project-39c0ea08-238b-47b5-915 \
    --member=user:solomiosisante@gmail.com \
    --role=roles/compute.osLogin
  ```
- Confirmed the role appeared in IAM policy.

### 5. Upload SSH Public Key to OS Login Profile
- On Windows, uploaded the public key associated with the private key `google_compute_engine`:
  ```powershell
  gcloud compute os-login ssh-keys add --key-file=$env:USERPROFILE\.ssh\google_compute_engine.pub
  ```
- On Cloud Shell, a similar key upload was done for its own environment.
- Despite this, OS Login still rejected connections because the VM lacked the guest package.

### 6. Attempt Ephemeral Browser SSH (as diagnostic)
- “Open in browser window” (ephemeral) from Cloud Console worked *temporarily*, as it injects a key directly into instance metadata, bypassing OS Login.
- This confirmed the network and VM were healthy, and the root problem lay within OS Login configuration.

### 7. Disable OS Login on the VM
- Because the OS Login guest package was missing and the serial console was unavailable, the simplest fix was to turn off OS Login:
  ```powershell
  gcloud compute instances add-metadata gocd-deploy-target --zone=us-west1-b --metadata enable-oslogin=FALSE
  ```
- This forces the VM to use instance‑metadata SSH keys.

### 8. Restart the VM (force guest agent refresh)
- Stopping and starting the VM ensures all services re‑read metadata:
  ```powershell
  gcloud compute instances stop gocd-deploy-target --zone=us-west1-b
  gcloud compute instances start gocd-deploy-target --zone=us-west1-b
  ```
- Wait 2‑3 minutes for boot.

### 9. Add a Valid Instance‑Metadata SSH Key
- On Windows, read the public key and inject it with a username prefix (or let `gcloud` do it automatically):
  ```powershell
  gcloud compute instances add-metadata gocd-deploy-target --zone=us-west1-b --metadata ssh-keys="sol-i:$(Get-Content $env:USERPROFILE\.ssh\google_compute_engine.pub -Raw)"
  ```
  (Replace `sol-i` with your preferred username; the key was already present from earlier attempts, but a fresh addition resolves parsing issues.)

### 10. Connect Successfully from Windows
- Using `gcloud compute ssh`:
  ```powershell
  gcloud compute ssh gocd-deploy-target --zone=us-west1-b
  ```
  Or directly with OpenSSH:
  ```powershell
  ssh -i $env:USERPROFILE\.ssh\google_compute_engine sol-i@35.230.13.215
  ```
- Authentication succeeded: “Authenticating with public key `LAPTOP-DADDY\sol-i@LAPTOP-DADDY`”.

---

## Final State
- **OS Login** is **disabled** on the VM (`enable-oslogin=FALSE`).
- **Instance‑metadata SSH key** for user `sol-i` is in place and accepted.
- **IAM roles** are correctly set (though not used while OS Login is off).
- **Windows host** connects reliably using the private key `google_compute_engine`.

## Optional: Re‑enabling OS Login (Future Steps)
If you later require OS Login for centralized access management:
1. Install the missing guest package inside the VM:
   ```bash
   sudo apt-get update && sudo apt-get install -y google-guest-oslogin
   sudo systemctl restart google-oslogin-cache.timer
   ```
2. Re‑enable OS Login on the instance:
   ```powershell
   gcloud compute instances add-metadata gocd-deploy-target --zone=us-west1-b --metadata enable-oslogin=TRUE
   ```
3. Verify your OS Login IAM role (`roles/compute.osLogin`) and that your public keys are uploaded to your OS Login profile.
4. Test the connection using `gcloud compute ssh` (which will then use OS Login).

## Notes
- The Cloud Shell quota is separate; it does not affect direct `gcloud` commands from a local machine.
- The serial console was misconfigured (`serial-port-enable` metadata had a malformed value) but was not needed after fixing OS Login.
- Always backup important files from Cloud Shell (`$HOME`) to avoid data loss during quota lockouts.