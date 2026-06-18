# Detailed Technical Plan: Workstation/Server Upgrade & Migration

This document details the proactive migration path from `e2-micro` to higher-performance GCP instances when triggered by performance metrics, and the procedure for emergency disk expansion.

## 1. Monitoring & Upgrade Triggers
Do not upgrade based on intuition. Set up **Cloud Monitoring** alerts for:
- **Memory (RAM) Usage:** 
    - Trigger: Consistently >85% for 30 minutes. 
    - Action: `e2-micro` is swapping. Plan migration to `e2-small`.
- **CPU Utilization:** 
    - Trigger: Sustained 80%+ load for 60 minutes.
    - Action: Migrate to `e2-medium` or higher.
- **Disk Capacity:**
    - Trigger: Usage > 90%.
    - Action: Perform emergency persistent disk expansion.

## 2. Proactive Memory Monitoring Strategy
To ensure your 1GB RAM environment is sufficient for production traffic:
1. **Real-time Assessment:** Run `free -h` regularly. If `available` memory is consistently < 100MB, the system is at high risk of swapping.
2. **Production Traffic Simulation:** Before a full launch, perform stress testing (e.g., using `ab` or `locust`) to simulate 5-10 concurrent booking requests. 
3. **Log Monitoring:** Check `/var/log/syslog` or dmesg for "Out of Memory" (OOM) killer events. If the system kills your Python/Docker process, an upgrade to `e2-small` (2GB RAM) is mandatory for professional operation.
4. **Cloud Monitoring Dashboard:** Create a dashboard in GCP to track Memory Usage percentage over 7 days. If the "peak" memory consistently hits > 85%, upgrade immediately to avoid production downtime.

## 3. Infrastructure & Cost Comparison
| Instance/Disk | Target Spec | Est. Monthly Cost (US Central) |
| :--- | :--- | :--- |
| **Disk** | 100GB Standard | ~$4.00 |
| **Instance** | `e2-small` | ~$15.00 - $17.00 |
| **Instance** | `e2-medium` | ~$27.00 - $30.00 |

*Note: Enabling these will terminate Always Free eligibility.*

## 4. Emergency Persistent Disk Expansion
If disk usage is > 90%:
1. **GCP Console:** Go to **Compute Engine > Disks**, select your disk, click **Edit**, set Size to `100` GB, and **Save**.
2. **SSH into VM:**
    - Run `sudo lsblk` to see the new disk size.
    - Run `sudo resize2fs /dev/sda1` (adjust device name if needed).
3. **Verify:** Run `df -h` to confirm the new total capacity.

## 5. Workstation Migration Workflow (VM Upgrade)
### Phase 1: Preparation
1. **Snapshot:** Run `gcloud compute disks snapshot [DISK_NAME] --zone=[ZONE]`
2. **Database Backup:** Export SQLite file: `cp /path/to/db.sqlite /path/to/backup/db_$(date +%F).sqlite`

### Phase 2: Execution
1. **Stop VM:** `gcloud compute instances stop [INSTANCE_NAME]`
2. **Modify Machine Type:** `gcloud compute instances set-machine-type [INSTANCE_NAME] --machine-type=[TARGET_TYPE]`
3. **Start VM:** `gcloud compute instances start [INSTANCE_NAME]`

### Phase 3: Post-Upgrade
- **Validation:** Check Docker logs and accessibility.
- **Adjust Budget:** Increase GCP Billing Budget alert to cover the new projected cost.
