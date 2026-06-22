# Memory_MenuSyncStatus.md

## ⚠️ Menu Refactor Synchronization Status

The management menus for `badminton_court` and `humrine_site` were refactored from a monolithic `oldmenu.js` into a modular JSON-driven system (`menu_sections.json`, `menu_options.json`, and individual `options/option_*.js` files). 

During the automated refactoring process (`Scripts/refactor_oldmenu.js`), several options were missing from the original `oldmenu.js` files. These must be manually created and synced across both applications to ensure feature parity.

### 1. Missing in `badminton_court`
These options did not exist in Badminton Court's original menu and need to be ported over from Humrine Site or created from scratch:
*   **3.4** (Old 12.9): Backup database (dumpdata)
*   **3.5** (Old 12.10): Restore database from backup
*   **9.1 - 9.6** (Old 16.1 - 16.6): Staging Containers (Web, DB, Redis, Mail, Nginx, Start All)
*   **11.1** (Old 20.2): Fix staging DB permissions
*   **11.2** (Old 20.4): Run staging migrations
*   **12.1 - 12.6** (Old 17.1 - 17.6): Production Containers (Web, DB, Redis, Mail, Nginx, Start All)
*   **14.1** (Old 20.3): Fix production DB permissions
*   **14.2** (Old 20.5): Run production migrations

### 2. Missing in `humrine_site`
These options did not exist in Humrine Site's original menu and need to be ported over from Badminton Court:
*   **4.8** (Old 2.8): Wipe and recreate mail-test volume (DESTRUCTIVE)
*   **4.9** (Old 13.0): Setup Linux System (Install dependencies)
*   **4.34** (Old 13.29): Authorise PAT for SAML SSO (org)
*   **9.7** (Old 16.7): Wipe and recreate mail-staging volume (DESTRUCTIVE)
*   **12.7** (Old 17.7): Wipe and recreate mail-production volume (DESTRUCTIVE)

## Next Steps to Resolve
1. Copy the missing `option_*.js` scripts from the app that has them into the app that is missing them.
2. Manually add the corresponding entries to `menu_options.json` in the app that is missing them.
3. Test the menu in both apps to ensure all 15 sections render correctly and all options execute.