# Memory Detail: Menu Exit and Pipeline Cancellation Issues

## Issue Summary
1.  **Exit Error (`ERR_USE_AFTER_CLOSE`):** Attempting to exit the GoCD menu (`option 0`) caused an `ERR_USE_AFTER_CLOSE` error in the `readline` interface. The root cause was calling `rl.close()` or attempting to read from a closed `readline` interface within the main menu loop.
2.  **Pipeline Cancellation (415 Unsupported Media Type):** The UI failed to cancel pipeline stages because it did not include the required `Content-Type: application/json` header in its POST requests.

## Resolution
1.  **Exit Logic:** Refactored `menu.js` to break the `showMenu` loop gracefully using `return` instead of `process.exit(0)`. Updated the `ask` function to check `rl.closed` to prevent errors after the interface is closed.
2.  **Pipeline Cancellation:** Implemented option `2.4` in the menu, which triggers a `curl` command with the correct headers (`Accept`, `Content-Type`, `X-GoCD-Confirm`) to bypass the GoCD UI/Proxy limitations.

## Status
- These fixes are currently **uncommitted** in the working directory.
- The system is functional but requires final verification by the user in the staging environment before a permanent commit of the `menu.js` and `Scripts/` changes is made.
