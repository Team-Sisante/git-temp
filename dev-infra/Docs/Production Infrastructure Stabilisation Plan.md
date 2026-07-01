# Production Infrastructure Stabilisation Plan

**Created:** July 1, 2026  
**Context:** All four web applications (Humrine staging/production, Badminton staging/production) are currently deployed on a single `e2-small` VM (1 GB RAM). The VM experiences frequent OOM kills, container crashes, SSH timeouts, and intermittent 502 errors.

**Credit status:** $155.14 free credits remaining, expiring August 7, 2026.

---

## 1. Immediate Actions (Today)

### 1.1 Upgrade the existing VM to `e2-medium`

**Why:** The current 1 GB RAM is insufficient for four Django applications, a PostgreSQL container, and other services. `e2-medium` provides 4 GB RAM, which will eliminate OOM crashes and SSH instability.

**How:**

```bash
gcloud compute instances stop gocd-deploy-target --zone asia-southeast1-b
gcloud compute instances set-machine-type gocd-deploy-target \
    --machine-type e2-medium \
    --zone asia-southeast1-b
gcloud compute instances start gocd-deploy-target --zone asia-southeast1-b
```

**Impact:**
- Production and staging containers will remain on the same VM (no architectural changes).
- RAM increases from 1 GB → 4 GB.
- CPU baseline improves; burst credits will no longer be exhausted under normal load.
- **Cost:** ~$24.90/month (covered by free credits).

**After upgrade:**
- Verify containers are running: `sudo docker ps`
- Check that `humrine.com` and all other sites are responsive.

---

## 2. Week 1 – Isolate the Database

### 2.1 Migrate PostgreSQL to Cloud SQL

**Why:** The in-container PostgreSQL database consumes 300–500 MB of RAM on the VM. Moving it to a managed service frees that memory for the web applications and eliminates the database as a source of crashes.

**Steps:**

1. **Create a Cloud SQL instance** (PostgreSQL 15, 1 vCPU, 3.75 GB, private IP):
   ```bash
   gcloud sql instances create humrine-postgres \
       --database-version POSTGRES_15 \
       --tier db-custom-1-3840 \
       --region asia-southeast1 \
       --network default \
       --no-assign-ip
   ```

2. **Create databases and users** for each environment (production, staging):
   ```bash
   gcloud sql databases create humrine_prod --instance humrine-postgres
   gcloud sql databases create humrine_staging --instance humrine-postgres
   gcloud sql databases create badminton_prod --instance humrine-postgres
   gcloud sql databases create badminton_staging --instance humrine-postgres
   ```

3. **Export current data** from the in-container database:
   ```bash
   sudo docker exec <db-container> pg_dump -U <user> humrine_prod > prod_backup.sql
   ```
   Repeat for other databases.

4. **Import data** into Cloud SQL:
   ```bash
   gcloud sql import sql humrine-postgres gs://your-bucket/prod_backup.sql --database humrine_prod
   ```

5. **Update environment variables** for each service:
   - Change `DATABASE_URL` to point to Cloud SQL private IP.
   - Update `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD` in GCP Secret Manager.
   - Restart containers.

**Cost:** ~$30/month (covered by free credits).

**After migration:**
- Remove the PostgreSQL container from the VM to reclaim RAM.
- Verify all sites work with the new database connection.

---

## 3. Optional – Isolate Staging (Budget Permitting)

### 3.1 Move staging apps to a separate VM

**Why:** Testing load or misbehaving staging code can affect production when all apps share one VM. Isolating staging provides a safer environment and allows staging to be stopped when not in use.

**How:**

1. Create a new `e2-small` VM (or `e2-medium` if needed):
   ```bash
   gcloud compute instances create staging-vm \
       --zone asia-southeast1-b \
       --machine-type e2-small \
       --network default \
       --tags gocd-deploy-target
   ```

2. Configure the same Docker Compose setup, but only with staging services.
3. Update the GoCD pipeline to deploy staging images to this new VM.
4. Use scheduled start/stop if the VM is only needed during business hours.

**Cost:** ~$12.45/month (if always on) – covered by credits until Aug 7.

---

## 4. Health‑Check & Monitoring Improvements

### 4.1 Add an application health endpoint

Create a Django view that returns 200 only if the database is reachable and essential services are working. Example:

```python
from django.http import HttpResponse
from django.db import connections

def health(request):
    try:
        connections['default'].cursor()
    except Exception:
        return HttpResponse('DB ERROR', status=500)
    return HttpResponse('OK')
```

### 4.2 Configure GCP Uptime Check

1. Go to **Monitoring → Uptime Checks**.
2. Create a check for `https://humrine.com/health/`.
3. Set alerting policy to email/SMS you when the site goes down.

### 4.3 Add `vm_unreachable` case to health‑check scripts

Update `case_solution.json` to detect when SSH entirely fails, so the system doesn’t misreport “container missing”. Treatment can then attempt `gcloud compute instances start`.

---

## 5. Cost Summary (Projected)

| Item | Monthly Cost | Covered by Credits? |
|------|--------------|---------------------|
| Production VM (e2‑medium) | $24.90 | Yes (until Aug 7) |
| Cloud SQL (1 vCPU, 3.75 GB) | $30.00 | Yes |
| Staging VM (optional, e2‑small) | $12.45 | Yes |
| **Total (with staging)** | **$67.35** | **~$134.70 over 2 months** |
| **Total (without staging)** | **$54.90** | **~$109.80 over 2 months** |

You have **$155.14** remaining – the entire professional setup is free for the next 2 months.

---

## 6. After Credits Expire (August 7, 2026)

Decide which services to keep or scale back:

- **Keep all** – $55–$67/month. This provides a stable, professional environment that saves you hours of debugging.
- **Keep only the upgraded VM** – $25/month. The database can be moved back inside the container, but memory pressure will return (less severe with 4 GB).
- **Downsize** – If budget is tight, you can stop the staging VM (or schedule it) and keep only production on the upgraded VM, with Cloud SQL shared between apps.

---

## 7. Timeline

| Date | Action |
|------|--------|
| **Today** | Upgrade VM to `e2‑medium` |
| **This week** | Create Cloud SQL instance, migrate database |
| **Next week** | Add health endpoint, uptime check, and `vm_unreachable` case |
| **Before Aug 7** | Evaluate costs and decide which services to keep |

---

## 8. Security & Best Practices (Already Partially Implemented)

- Continue using **GCP Secret Manager** for all credentials – no hard‑coded secrets.
- Use **IAP for SSH** if possible (eliminates public IP exposure).
- Enable **Cloud SQL automated backups** – already included in the instance price.
- Set up **Cloud Monitoring alerts** for high CPU, memory, or disk usage.

---

This plan will transform your current unstable setup into a reliable production infrastructure, entirely funded by your remaining free credits. Let me know when you’re ready to start, and I can walk you through each command in real time.