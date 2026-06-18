# GCP Hosting & Monetization Strategy

## Monetization Strategy
- **Decision:** **Managed Hosting Fee** + **Affiliate Links** + **Google AdSense**.
- **Reasoning:**
    1. Managed fee provides immediate "cash flow" for the developer.
    2. Affiliate links provide passive income without client overhead.
    3. AdSense provides scalability as traffic grows.
    4. Aligns with Philippine business registration paths (DTI/BIR).

*Detailed Monetization Plan:* See [Plan - AdSense, PPC & Affiliate Strategy](Plan%20-%20AdSense,%20PPC%20&%20Affiliate%20Strategy.md).
*Detailed Financial Projections:* See [Plan - Financial Projections & Budgeting](Plan%20-%20Financial%20Projections%20&%20Budgeting.md).

## ADR-005: Business Identity (Philippines)
- **Date:** 2026-05-10
- **Decision:** Start as **Individual**, transition to **Sole Proprietor**.
- **Reasoning:**
    1. Minimizes upfront costs while in development.
    2. Allows for legal monetization via personal TIN.
    3. IPOPHL copyright protection can be filed as an individual.

## ADR-006: Cost Management & Budgeting Framework
- **Date:** 2026-05-26
- **Decision:** Proactive Budget Alerting and Monitoring.
- **Reasoning:**
    1. Critical for maintaining the "Always Free" status of the e2-micro instance.
    2. Prevents accidental overages due to misconfiguration or resource leaks.
    3. Provides immediate feedback loops for infrastructure spending.

### Implementation Steps: Budget Alerts
1. Log in to the **Google Cloud Console**.
2. Navigate to **Billing** > **Budgets & alerts**.
3. Click **Create Budget**.
4. Set the **Scope** (select your specific project).
5. Set the **Budget amount**:
   - Determine a threshold based on your expected monthly spend. Since the goal is to remain in the "Always Free" tier, set the budget to a small amount above zero that you would consider an "unexpected cost" (e.g., $5.00 or $10.00, representing the cost of a single accidental resource leak, not your actual intended usage).
6. Set **Alert thresholds**:
   - Set multiple percentages (e.g., 25%, 50%, 75%, and 100% of your chosen budget amount) to get early warnings before significant costs accrue.
7. Configure **Actions** (select email notifications) and click **Finish**.

## Consolidated Monitoring Strategy
To monitor total costing for infrastructure, PPC spend, and monetization revenue, use this unified approach:

1.  **GCP Infrastructure:**
    *   **Billing Reports:** Use the "Billing" console to view cost breakdowns by service (Compute Engine, Persistent Disk, etc.).
    *   **Budgets & Alerts:** Set up proactive notifications (as defined in ADR-006).

2.  **Monetization Performance:**
    *   **AdSense Dashboard:** Track revenue generated from ad impressions/clicks.
    *   **Google Ads Dashboard:** Track daily/monthly PPC spending.

3.  **Unified Management (Recommended):**
    *   **Manual Tracking Spreadsheet:** Create a simple Google Sheet to manually record monthly totals for `(PPC Spend) - (AdSense Revenue + Affiliate Revenue) = Net Profit/Loss`.
    *   **Frequency:** Check monthly to identify if PPC/Affiliate strategies are yielding positive ROI.

*Detailed Upgrade Plan:* See [Steps - Workstation Upgrade & Migration Plan](Steps%20-%20Workstation%20Upgrade%20&%20Migration%20Plan.md).
