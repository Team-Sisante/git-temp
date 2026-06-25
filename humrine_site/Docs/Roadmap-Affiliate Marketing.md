<!-- AI ASSISTANT NOTE: Always refer to this document and update it as tasks are completed or architecture changes. Do not remove this note! Also do not remove the history of modifications. [HARD RULE] When editing, ALWAYS preserve ALL existing content. Only ADD new entries or UPDATE existing ones. NEVER delete or shorten the history.
[RULE] Every roadmap document MUST be updated by the engineer after any significant decision, finding, code fix, or task completion to ensure project state transparency.
[RULE] You should always update these roadmap documents on our decisions, findings, fixes and next tasks after doing the updates/changes/modifications.
[RULE] This roadmap document tracks architectural plans and high‑level progress. Detailed problem/solution write‑ups belong in the corresponding `Docs/Trouble-shooting/` documents. Keep entries concise; link to the relevant trouble‑shooting file for full context.
-->

# Roadmap: Affiliate Marketing Integration (Lazada & Shopee)
# Source: Docs/Roadmap-Affiliate Marketing.md

This document outlines the plan to integrate affiliate marketing into the Django web app, with initial focus on Lazada, Shopee, and (optionally) Involve Asia, using a clean link‑tracking layer.  
For step‑by‑step guides and resolved issues, see the `Docs/Trouble-shooting/` directory.

---

## Phase 1: Core Affiliate Link Tracking System

- [x] **1.1 – Model for Tracked Links**  
  Create `TrackedAffiliateLink` model (`original_url`, `slug`, `title`, `merchant`, `created_at`).  
  Add `AffiliateClick` model for click analytics (`link`, `ip`, `user_agent`, `referer`, `clicked_at`).

- [x] **1.2 – Redirect View & URL**  
  Implement `affiliate_redirect(request, slug)` that logs a click and redirects to `original_url`.  
  Wire it to `/out/<slug>/`.

- [x] **1.3 – Template Tag**  
  Build `{% affiliate_url slug %}` template tag to output the cloaked URL (e.g., `/out/best-mouse/`).

- [x] **1.4 – Admin Registration**  
  Register both models in Django admin for quick link management and click log inspection.

- [x] **1.5 – Manual Link Generation Flow**  
  Document how to obtain Lazada/Shopee affiliate links and create corresponding `TrackedAffiliateLink` entries (either via admin or a management command).  
  *Added CSV import management command (`import_affiliate_links`).*

---

## Phase 2: Lazada & Shopee Direct Affiliate Programs (Manual Links)

- [ ] **2.1 – Affiliate Account Sign‑up**  
  - Shopee: application submitted, under review (15–30 working days).  
  - Lazada: portal returned 502 error; retry later.  
  *Involve Asia publisher account approved and used as immediate alternative.*

- [ ] **2.2 – First Product Links**  
  - Several real Shopee links created via Involve Asia (sacred‑heart‑shirt, chick‑cordless‑fan, etc.).  
  - Still need to build up to 10 links from each platform.

- [x] **2.3 – Disclosure & Compliance**  
  Added FTC‑style disclosure notice on deals page. All affiliate links use `rel="nofollow sponsored"`.

- [x] **2.4 – Cookie & Policy Considerations**  
  IP anonymization implemented (store only first 3 octets). Cookie consent banner added. Privacy policy updated to describe affiliate tracking.

- [x] **SEO**  
  Sitemap and robots.txt created and submitted. Google Search Console verified.

---

## Phase 3: Involve Asia Integration (Optional, Multi‑Merchant API)

- [x] **3.1 – Involve Asia Publisher Account**  
  Account created, property Humrine.com approved.  
  Shopee PH and Lazada Talent (PH) campaigns applied; Shopee auto‑approved, Lazada pending.

- [x] **3.2 – API Client in Django**  
  Service module `involve_api.py` written (with caching).  
  API key received and configured.

- [x] **3.3 – Dynamic Product Catalogue (Optional)**  
  Built a view that pulls live products from Involve Asia and renders them, each wrapped with our cloaked redirect.

- [x] **3.4 – Fallback & Error Handling**  
  Dynamic deals view now falls back to curated database links when the API is unavailable.

---

## Phase 4: Analytics Dashboard & Reporting

- [x] **4.1 – Basic Click Stats**  
  Created `/stats/` view with per‑link and daily click breakdowns.

- [x] **4.2 – Export & Filtering**  
  Added date range filters and CSV export to the stats dashboard.

- [ ] **4.3 – Conversion Attribution (Future)**  
  (Stretch) Integrate conversion pixels or server‑side postbacks if the networks support it.

---

## Phase 5: Own Affiliate Program (Inbound) – Future Scope

- [ ] **5.1 – Affiliate User Model**  
  `Affiliate` model linked to `User`, with `referral_code`, `commission_rate`, `total_earnings`.

- [ ] **5.2 – Referral Tracking**  
  Landing page `/ref/<code>/` that sets a cookie and logs a `ReferralClick`.  
  Attribute sign‑ups/purchases to the referring affiliate.

- [ ] **5.3 – Affiliate Dashboard**  
  Let affiliates view their clicks, conversions, and earnings.  
  Admin tools to mark payouts.

---

## Phase 6: Google AdSense Integration

- [x] **6.1 – AdSense Account & Approval**  
  Signed up for Google AdSense, added humrine.com, publisher ID received.

- [x] **6.2 – Add Ad Code to Base Template**  
  Auto Ads script inserted in `<head>` of `base.html`.

- [x] **6.3 – Verify Ads Display Correctly**  
  ads.txt file created and deployed. AdSense re‑review requested.  
  *(Awaiting final approval; content improvements planned to meet policy.)*

---

## Phase 7: Data Persistence & Backup (Affiliate Database)

- [x] **7.1 – Backup & Restore Commands**  
  Created `backup_db` and `restore_db` Django management commands.

- [x] **7.2 – Menu Integration**  
  Added backup/restore options (12.9, 12.10) to `Scripts/menu.js`.

- [x] **7.3 – Persistent Volume for SQLite**  
  Named volume `db_data` mounted at `/app/data`. Startup command ensures correct ownership.  
  Database now survives container recreations and deployments.

---

## Key Decisions & Architecture Notes

- **Link ownership:** All outbound affiliate links go through our own redirect (`/out/<slug>/`). This gives us full click analytics independent of the networks.
- **Merchant flexibility:** The `TrackedAffiliateLink` model supports any merchant (Lazada, Shopee, or Involve). We can add more later without code changes.
- **Cookie vs. IP tracking:** Clicks are logged with IP and user‑agent for spam filtering, but privacy‑first approach should be documented.
- **Involve Asia priority:** If we later need dynamic product feeds, Involve Asia’s unified API is the preferred route over scraping or per‑merchant APIs.

---
*Last Updated: 2026-06-25*