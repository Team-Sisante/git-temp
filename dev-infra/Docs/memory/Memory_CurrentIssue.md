# Memory Detail: Current Issue - Pipeline Image Tag Failure

## Issue Description
The `humrine_site-production` pipeline failed because the `IMAGE_TAG` environment variable was resolved as `sha-` (missing the Git commit hash). This caused the Docker pull command to fail as the image `ghcr.io/xmione/humrine_site-web:sha-` does not exist.

## Root Cause
The `humrine_site-artifacts` pipeline (upstream) does not have a `labelTemplate` configured to use the Git material's revision. Consequently, GoCD uses a default incrementing counter for the pipeline label. When `humrine_site-production` references `GO_REVISION_HUMRINE_SITE_ARTIFACTS`, it receives this counter (or an empty value if not properly mapped) instead of the required Git SHA.

## Proposed Solution
1. Modify `gocd-server/config/cruise-config.xml`.
2. Add `name="repo"` to the Git material in the `humrine_site-artifacts` pipeline.
3. Add `labelTemplate="${repo}"` to the `humrine_site-artifacts` pipeline definition.
4. This ensures the pipeline label is the Git SHA, which will then be correctly passed to downstream pipelines as `GO_REVISION_HUMRINE_SITE_ARTIFACTS`.

## Status
- **Diagnosed:** 2026-06-15
- **Pending:** Implementation of `cruise-config.xml` update.
