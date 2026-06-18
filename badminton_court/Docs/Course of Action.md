# Project Roadmap: Badminton Court Management System

## Phase 1: Infrastructure & Deployment (Current)
- [x] **GCP Setup:** Created e2-micro VM in `us-central1-a` (Always Free Tier).
- [x] **Static IP:** Reserved and assigned static IP to the VM.
- [x] **Docker Installation:** Successfully installed Docker and Docker Compose on the GCP VM.
- [ ] **GoCD Connection:** Finalize the SSH handshake between the local GoCD agent and the GCP VM.
- [ ] **First Deploy:** Deploy the `badminton_court` app using the remote Docker context to ensure SQLite persistence is working on the 30GB disk.

## Phase 2: Professionalization & Monetization
- [ ] **Environment Segregation:** Create `.env.staging` and `.env.production` to manage local vs. cloud settings.
- [ ] **Privacy Policy:** Add a Data Privacy Act (DPA 2012) compliant Privacy Policy to the web app (required for AdSense).
- [ ] **Affiliate Integration:** Create a "Partner Resources" page in the Python app to host affiliate links.
- [ ] **AdSense Application:** Apply for Google AdSense once the site is live and populated with content.

## Phase 3: Legal & Business Setup (Philippines Context)
- [ ] **IP Protection:** File for Copyright Recordation at **IPOPHL** for the original source code of the Badminton System.
- [ ] **Business Identity:** Register a Business Name with **DTI** (Department of Trade and Industry) as a Sole Proprietor.
- [ ] **Tax Compliance:** Register with the **BIR** using the personal TIN to enable legal issuance of Official Receipts (OR) to clients.
- [ ] **Contract Execution:** Use the drafted "Web Development and Hosting Service Agreement" for all future clients.

## Phase 4: Scaling & Expansion
- [ ] **Domain Integration:** Purchase a `.com` or `.ph` domain and point it to the GCP Static IP.
- [ ] **Backups:** Implement a daily cron job to back up the SQLite database file from the VM to a Google Cloud Storage (GCS) bucket.
- [ ] **Monitoring:** Use GCP Cloud Monitoring to stay alerted on the e2-micro RAM usage (1GB limit).
