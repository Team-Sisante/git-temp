# Memory_MenuSyncStatus.md

## ⚠️ Menu Refactor & Modular Architecture

The management menus for `badminton_court` and `humrine_site` have been completely refactored from a monolithic `oldmenu.js` into a modular, JSON-driven system. Both applications now share the **exact same** 15-section layout and command options to ensure infrastructure parity and muscle memory.

### 1. Modular File Structure
*   **`Scripts/menu.js`**: The lightweight engine. Reads the JSON files, displays the menu, and dynamically loads the selected option script.
*   **`Scripts/menu_sections.json`**: Defines the 15 standard sections.
*   **`Scripts/menu_options.json`**: Maps every menu ID (e.g., `1.1`) to a specific script file (e.g., `option_1_1.js`).
*   **`Scripts/options/option_X_Y.js`**: Individual files containing the executable code for each menu option. There is a strict **1-to-1 mapping** (Option `1.7` always points to `option_1_7.js`).

### 2. Strict Uniformity Standards
To make navigation predictable blind, the sections follow strict standards. If an environment doesn't have a specific option, the slot is kept but marked as `(not applicable)`.

**Container Sections (1, 5, 9, 12):**
*   `X.1`: Web
*   `X.2`: Database
*   `X.3`: Redis
*   `X.4`: Mail
*   `X.5`: Nginx
*   `X.6`: Start/Restart all containers
*   `X.7`: Wipe and recreate mail volume (DESTRUCTIVE)
*   `X.8`: Stop environment
*   `X.9+`: Other environment-specific commands pushed to the bottom.

**Image Management Sections (2, 6, 10, 13):**
*   `X.1` to `X.5`: Delete specific images (Web, DB, Redis, Mail, Nginx)
*   `X.6`: FULL CLEAN (delete all containers, images, volumes, cache)
*   `X.7+`: Build, Backup, and Restore commands pushed to the bottom.

**Database Management Sections (3, 7, 11, 14):**
*   `X.1`: Fix DB permissions
*   `X.2`: Run migrations
*   `X.3`: Load/Reset data
*   `X.4+`: Backup/Restore data

### 3. The 15 Standard Sections
1-4: DEVELOPMENT (Containers, Images, Database, Utilities)
5-8: DOCKER (Containers, Images, Database, Utilities)
9-11: STAGING (Containers, Images, Database)
12-14: PRODUCTION (Containers, Images, Database)
15: GCP VM MANAGEMENT

### 4. Refactoring & Synchronization
*   The script `Scripts/refactor_oldmenu.js` was used to parse the legacy `oldmenu.js` files, extract the `case` blocks, replace `break;` with `return;`, and save them as individual `option_X_Y.js` files.
*   **Cross-Pollination:** Because some options existed in `badminton_court` but not `humrine_site` (and vice versa), the missing `option_*.js` files were manually copied between the repositories to achieve 100% parity.
*   Both apps now use identical `menu_sections.json` and `menu_options.json` files.