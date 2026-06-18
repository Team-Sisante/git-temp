# Memory Detail: Linux System Setup Automation

## Issue Summary
The user required an automated way to install OS-level dependencies (like `dos2unix`) on Linux within the `badminton_court` repository, and requested it be exposed via the menu system.

## Resolution
1.  **System Script:** Created `Scripts/setup-linux-system.sh` to handle `apt-get` system-level installations.
2.  **Menu Integration:** Updated `Scripts/menu.js` to:
    - Include the new system setup task as Option 4.1.
    - Reorder the "SYSTEM UTILITIES" menu section.
    - Support direct command-line dispatching (`node Scripts/menu.js 4.1`) for automation pipelines.
3.  **Cross-Platform Awareness:** The script checks `OSTYPE` to prevent accidental execution on non-Linux systems.
4.  **Persistence:** All setup tasks are now exposed via the unified menu and can be automated headlessly.
