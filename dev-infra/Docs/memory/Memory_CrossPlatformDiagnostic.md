# Memory Detail: Cross-Platform Diagnostic Wrapper

## Issue
Pipeline tasks in `cruise-config.xml` directly executed `Scripts/diagnose-network.sh`, which failed on Windows host machines.

## Solution
Implemented a cross-platform Node.js wrapper (`Scripts/diagnose-network.js`) that detects the platform and executes the appropriate script (`.sh` on Linux, `.ps1` on Windows).

## Status
- **Resolved:** Yes.
- **Verification:** Pipeline configuration updated to use the wrapper.
