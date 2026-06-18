# Financial Projections & Budgeting

This document provides estimated monthly costs for scaling the infrastructure and running marketing campaigns.

## 1. Monthly Cost Projection Table

| Category | Item | Est. Monthly Cost (USD) | Notes |
| :--- | :--- | :--- | :--- |
| **Infrastructure** | `e2-micro` | $0.00 | Always Free Tier |
| **Infrastructure** | `e2-small` | ~$15.00 - $17.00 | Includes VM + Storage/IP |
| **Infrastructure** | `e2-medium` | ~$27.00 - $30.00 | Includes VM + Storage/IP |
| **Marketing** | PPC (Ads) | $10.00 | Rigid daily limit recommended |
| **Total (Plan B)** | `e2-small` + PPC | **~$25.00 - $27.00** | Target for early production |

*Note: Costs are estimates for sustained 24/7 uptime in `us-central1`. Actual billing depends on usage and regional pricing.*

## 2. Budget Management Rules
- **Rule 1:** Only upgrade infrastructure if revenue (AdSense + Affiliates) covers the projected monthly cost.
- **Rule 2:** Set rigid daily budget caps in Google Ads to prevent overspending.
- **Rule 3:** Configure GCP Billing Budget alerts to 120% of the target monthly cost to receive email notifications before a surprise bill occurs.

## 3. Monitoring ROI
Use a manual tracking spreadsheet to monitor profitability:
> **Net Monthly Return = (AdSense Revenue + Affiliate Revenue) - (PPC Spend + GCP Hosting Costs)**

If this formula consistently results in a negative value, re-evaluate the PPC campaign or infrastructure tier.
