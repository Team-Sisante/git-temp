# Memory Detail: GoCD API Migration Plan

## Issue
Legacy JSON API endpoints (e.g., `/go/api/pipelines/active`, `/go/api/pipelines/.../history`) used in the GoCD menu automation are returning 404 in GoCD v25.4.0 due to deprecation and removal.

## Migration Strategy (Permanent Resolution)
To ensure long-term stability given GoCD v25.4.0+ API limitations:

1. **Automated Discovery (CCTray):** Utilize the `GET /go/cctray.xml` endpoint to identify all active ("Building") pipeline stages.
2. **Automated Extraction:** Parse the `webUrl` field from the CCTray response using URL structure analysis to automatically extract the `pipelineName`, `pipelineCounter`, `stageName`, and `stageCounter`.
3. **Modernized Cancellation:** The POST request utilizes the standard, modern API path structure (`/go/api/stages/.../cancel`), ensuring compatibility with the current GoCD API standards, now fully automated.

## Status
- **Plan:** Implemented and Verified.
- **Implementation:** `Scripts/menu/cancelPipeline.js` refactored to fully automate discovery.
- **Verification:** User verified automated cancellation successfully.
