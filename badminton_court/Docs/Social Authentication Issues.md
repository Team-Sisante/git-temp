# Approaches Attempted and Outcomes
# Source: git-temp/badminton_court/Docs/Social Authentication Issues.md

The following is a record of all approaches we tried to make the Google OAuth account chooser appear and allow the demo test to click an account, along with their outcomes. None of these approaches succeeded in producing a stable, working flow.

## 1. Persistent Chrome profile alone
- **What we did**: Pointed Cypress at `C:\cypress-chrome-profile` via `--user-data-dir` and `--profile-directory=Default`, seeded the profile with a Google login using menu option 16.3.
- **Outcome**: The account chooser never appeared. Google returned either a blank page or an `authuser=unknown` loop. The `SID` cookie is `Secure`, and Chrome would not send it over `http://localhost`.

## 2. Adding SameSite‑related Chrome flags
- **What we did**: Added `--disable-features=SameSiteByDefaultCookies,CookiesWithoutSameSiteMustBeSecure` to both the seeding Chrome and Cypress's Chrome launch.
- **Outcome**: Did not resolve the missing account list; the `Secure` cookie issue persisted.

## 3. Injecting the SID cookie via `cy.setCookie` in `e2e.js`
- **What we did**: Extracted the `SID` value from the Chrome profile (later manually) and called `cy.setCookie` before clearing localhost cookies.
- **Outcome**: The cookie value was often corrupted (binary garbage, multiple lines). Even when a seemingly clean value was used, the test still received a 403 from Google.

## 4. Automatic cookie extraction with PowerShell + SQLite
- **What we did**: Created `extract-google-cookie.ps1` that downloaded `sqlite3.exe` and attempted to decrypt the `Cookies` database.
- **Outcome**: The script failed due to missing types (`ProtectedData`), download issues, and decryption producing non‑UTF‑8 data.

## 5. Automatic cookie extraction with Python + `pywin32` + `cryptography`
- **What we did**: Replaced the PowerShell script with a Python script that used the built‑in `sqlite3` module, `win32crypt`, and AES‑GCM decryption.
- **Outcome**: The script decrypted the value but produced a binary blob with leading metadata. The extracted token was correct, but writing it to the `.env` files introduced multi‑line corruption, and later runs left behind remnant garbage lines (e.g., `"7s`).

## 6. Manual cookie copy from Chrome DevTools
- **What we did**: Manually copied the `SID` value from Chrome DevTools into `.env.dev`.
- **Outcome**: The test still received a 403 when navigating to Google.

## 7. Using `cy.origin` to click the first account and handle consent
- **What we did**: Inside `cy.origin('https://accounts.google.com', ...)`, attempted to click `div[data-email]` and then a "Continue" button on the consent page.
- **Outcome**: The account chooser page either did not load or displayed a 403. The consent step timed out or caused a blank AUT frame.

## 8. Using `cy.origin` to sign in with demo credentials
- **What we did**: Created a step that typed a Google email and password inside `cy.origin`.
- **Outcome**: The sign‑in page was never reached (403 / blank), so the step timed out.

## 9. Removing `experimentalModifyObstructiveThirdPartyCode` / `modifyObstructiveCode`
- **What we did**: Removed or commented out these flags in `cypress.config.js`.
- **Outcome**: The account chooser still showed a blank page or 403.

## 10. Multiple iterations of the profile seeding script (`option_16_3.js`)
- **What we did**: Enhanced the script to delete the old profile, add `--profile-directory=Default`, include SameSite flags, automatically kill Chrome, and call the extraction script.
- **Outcome**: The seeding process itself worked, but the test run never successfully used the session.

## 11. Updating `.env` file categories (runtime, safe, template)
- **What we did**: Modified the extraction script to write the real `SID` to runtime/test files, `<hidden>` to safe files, and `<?secret?>` to templates.
- **Outcome**: File management logic became tangled with lingering corrupted lines, requiring manual cleanup. The underlying 403/blank‑page problem remained.

---

All attempts were ultimately unsuccessful in making the Google account chooser appear and function correctly within the Cypress test. The original working state (before the series of changes) was lost and not restored.