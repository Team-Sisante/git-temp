# GCP Load Balancer Troubleshooting Commands – Reference Guide

## Source: Docs/GCP-LoadBalancer-Commands.md

A comprehensive reference for managing and troubleshooting GCP External Application Load Balancers, health checks, and related components.

---

## 1. Health Checks

| Command | Purpose |
|---------|---------|
| `gcloud compute health-checks describe <name> --global --project=<project-id>` | View full health check configuration |
| `gcloud compute health-checks describe <name> --global --project=<project-id> --format="value(httpHealthCheck.port)"` | Get just the port |
| `gcloud compute health-checks describe <name> --global --project=<project-id> --format="value(httpHealthCheck.host)"` | Get just the host header |
| `gcloud compute health-checks describe <name> --global --project=<project-id> --format="value(httpHealthCheck.requestPath)"` | Get just the request path |
| `gcloud compute health-checks update http <name> --port=<port> --global --project=<project-id>` | Update the port |
| `gcloud compute health-checks update http <name> --host=<hostname> --global --project=<project-id>` | Update the host header |
| `gcloud compute health-checks update http <name> --port=<port> --host=<hostname> --request-path=/path/ --global --project=<project-id>` | Update multiple fields at once |

---

## 2. Backend Services

| Command | Purpose |
|---------|---------|
| `gcloud compute backend-services list --global --project=<project-id>` | List all backend services |
| `gcloud compute backend-services describe <name> --global --project=<project-id>` | View backend configuration |
| `gcloud compute backend-services describe <name> --global --project=<project-id> --format="value(protocol,portName)"` | Get protocol and named port |
| `gcloud compute backend-services get-health <name> --global --project=<project-id>` | Check backend health status |
| `gcloud compute backend-services update <name> --global --project=<project-id> --protocol=HTTP --port-name=<name>` | Fix protocol or port |

---

## 3. Firewall Rules

| Command | Purpose |
|---------|---------|
| `gcloud compute firewall-rules list --project=<project-id>` | List all firewall rules |
| `gcloud compute firewall-rules describe <name> --project=<project-id> --format="value(allowed[].ports)"` | Get allowed ports |
| `gcloud compute firewall-rules update <name> --project=<project-id> --rules=tcp:<port1>,tcp:<port2>` | Update allowed ports |
| `gcloud compute firewall-rules delete <name> --project=<project-id> --quiet` | Delete a rule |
| `gcloud compute firewall-rules create <name> --project=<project-id> --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:<port> --source-ranges=35.191.0.0/16,130.211.0.0/22 --target-tags=<tag>` | Create health-check rule |
| `gcloud compute firewall-rules create <name> --project=<project-id> --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:<port> --source-ranges=0.0.0.0/0 --target-tags=<tag>` | Create traffic rule (all sources) |

---

## 4. Instance Groups

| Command | Purpose |
|---------|---------|
| `gcloud compute instance-groups unmanaged describe <name> --zone=<zone> --project=<project-id>` | View group details |
| `gcloud compute instance-groups unmanaged list-instances <name> --zone=<zone> --project=<project-id>` | List members (empty = no targets) |
| `gcloud compute instance-groups unmanaged add-instances <name> --zone=<zone> --project=<project-id> --instances=<vm-name>` | Add VM to group |
| `gcloud compute instance-groups unmanaged set-named-ports <name> --zone=<zone> --project=<project-id> --named-ports=<name1>:<port1>,<name2>:<port2>` | Update named ports |

---

## 5. Instances (VMs)

| Command | Purpose |
|---------|---------|
| `gcloud compute instances describe <name> --zone=<zone> --project=<project-id> --format="value(tags.items)"` | Get VM network tags |

---

## 6. SSL Certificates

| Command | Purpose |
|---------|---------|
| `gcloud compute ssl-certificates list --global --project=<project-id>` | List all certs |
| `gcloud compute ssl-certificates describe <name> --global --project=<project-id> --format="value(managed.status)"` | Check provisioning status |
| `gcloud compute ssl-certificates delete <name> --global --project=<project-id> --quiet` | Delete a cert |

---

## 7. URL Maps & Forwarding Rules

| Command | Purpose |
|---------|---------|
| `gcloud compute url-maps describe <name> --global --project=<project-id>` | View URL map configuration |
| `gcloud compute forwarding-rules describe <name> --global --project=<project-id>` | View forwarding rule |
| `gcloud compute target-https-proxies describe <name> --global --project=<project-id> --format="value(sslCertificates)"` | See attached certs |

---

## 8. Common Troubleshooting Sequences

### "Site is down (502)"

1. **Check container health** – option 6.26 (menu), or SSH to VM and check `docker ps`
2. **Check backend health** – `gcloud compute backend-services get-health <backend> --global --project=<project-id>`
3. If UNHEALTHY or empty:
   - Check health check port/host – `gcloud compute health-checks describe <name> --global`
   - Check instance group membership – `gcloud compute instance-groups unmanaged list-instances <name> --zone=<zone>`
   - Check firewall allowed ports – `gcloud compute firewall-rules describe <name> --format="value(allowed[].ports)"`
   - Test locally from VM – `curl -s -o /dev/null -w '%{http_code}' http://<ip>:<port>/`
4. Fix as needed (add host to health check, add VM to group, update firewall)
5. Wait 60 seconds, re-check health

### "Unknown/invalid Host header"

- Update health check host: `gcloud compute health-checks update http <name> --host=<domain> --global --project=<project-id>`
- Or add IP to `ALLOWED_HOSTS` in Django settings (only for debugging, not production)

---

## 9. Pro Tips

- Always use `--global` for load balancer resources (health checks, backends, URL maps, proxies, forwarding rules)
- Always specify `--project=<id>` to avoid targeting the wrong project
- Use `--format="value(field.subfield)"` for clean, scriptable output
- Use `--quiet` to skip confirmation prompts in scripts
- Use `sleep 60 && gcloud ...` to wait for changes to propagate
- For firewall rules with multiple ports, separate them with commas: `tcp:8007,tcp:8008`

---

## 10. Our Specific Setup

| Component | Staging | Production |
|-----------|---------|------------|
| Health Check | `staging-health-check` (port 8007, host staging.humrine.com) | `production-health-check` (port 8008, host humrine.com) |
| Backend Service | `humrine-staging-backend` | `humrine-backend` |
| Instance Group | `humrine-apps-group` (zone asia-southeast1-b) | `humrine-apps-group` |
| Firewall Rule | `allow-lb-health-checks` (ports 8003,8004,8007,8008) | `allow-lb-health-checks` |
| VM Tag | `gocd-deploy-target` | `gocd-deploy-target` |
| Project ID | `project-39c0ea08-238b-47b5-915` | `project-39c0ea08-238b-47b5-915` |

---
*Last Updated: 2026-06-24*