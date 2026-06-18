# Memory Detail: Cross-Platform Automated Certificate Setup

## Issue Summary
The user needed to automate the GoCD local development setup, specifically running option 4.12 (SSL certificate generation) headlessly on both Windows and Linux.

## Resolution Pattern: Unified Provider Architecture
The solution involved refactoring the setup into a single, maintainable Node.js architecture:

### 1. Unified AdminProvider (`Scripts/adminProvider.js`)
Abstracted platform-specific administrative tasks (hosts file manipulation, CA trust, OS SSL cache) into a Provider Pattern.

### 2. Consolidated Entry Point (`Scripts/generate-certs.js`)
Refactored `generate-certs.js` to handle both phases:
- **Phase 1 (User-Space):** Generates `server.crt`, `server.key`, and `ca.pem` in the `certs/` folder, ensuring filenames match GoCD's expectations.
- **Phase 2 (Privileged):** Self-escalates using `process.execPath` (fixing path issues in `sudo` or PowerShell environments).

### 3. Streamlined Menu (`Scripts/menu.js`)
Updated the menu dispatcher to call `node Scripts/generate-certs.js` directly. 

## Commit Status
The automation logic (including the provider architecture and headless support) has been validated, tested, and successfully committed to the `fix/smtp` branch of the `badminton_court` repository.
