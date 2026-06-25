# Social Media App Configuration Menu
## Source: Docs/Trouble-shooting/Social Media App Configuration Menu.md

**Status:** Completed (June 25, 2026)

### Problem
Social login buttons (Google, Facebook, Twitter) disappeared from the badminton_court login/signup pages because the `SocialApp` database records were missing. Environment variables were correct, but the database entries hadn't been created after container recreations.

### Solution
- Added menu option 16.2 ("Setup Social Media DB Records") to the badminton_court menu.
- The option uses `inquirer` to prompt for the environment (staging/production), then SSHes into the VM and runs the `setup_social_apps` management command inside the appropriate container.
- The command is idempotent – it creates or updates the `SocialApp` entries for Google, Facebook, and Twitter from the environment variables already present in the container.

### Related Files
- `badminton_court/Scripts/options/option_16_2.js`
- `badminton_court/court_management/management/commands/setup_social_apps.py`