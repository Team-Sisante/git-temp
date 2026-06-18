# Memory Detail: Humrine Site Maintenance & Error Handling Strategy

## Issue Summary
- **Deployment Pipeline:** Currently failing due to invalid `IMAGE_TAG` (`sha-`), preventing web/nginx containers from starting.
- **Maintenance Page Missing:** The `nginx-production` container in `humrine_site/docker-compose.vm.yml` lacks the volume mapping for `./templates/offline.html`, meaning it cannot serve the custom maintenance page even if running.
- **Generic Error Source:** The "Server Error" seen by users is served by the GCP Load Balancer (not the Nginx container), as the production Nginx container is not running.

## Load Balancer Behavior
- The current generic error message is the default GCP Load Balancer error response when the backend (Nginx) is completely down or unresponsive.
- **Customization Capability:** GCP global external Application Load Balancers **do** support custom error responses for 5xx errors (including 502, 503, 504).
- **Implementation:** We can define policies at the load balancer level to serve a static, custom HTML page when the backend is unreachable.

## Strategy for "Under Maintenance" Page
1. **Immediate UX Fix (LB Level):** Configure the GCP Load Balancer to serve a custom error response page (e.g., `offline.html`) for 5xx errors. This provides an immediate, user-friendly "Under Maintenance" page.
2. **Infrastructure Goal:** Bring the Nginx container back online. Once the Nginx container is healthy, it will intercept 502/503/504 errors from the web application and serve our custom `offline.html`.
3. **Implementation:** 
    - Update `humrine_site/docker-compose.vm.yml` to include the volume mapping for `./templates/offline.html`.
    - Fix the deployment pipeline to allow the Nginx container to start.
4. **User Experience:** With the Nginx container healthy, users will be redirected to the custom `offline.html` instead of the default Load Balancer "Server Error" message.
