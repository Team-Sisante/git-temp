# Maintenance Page Implementation (badminton_court)

The `badminton_court` project includes a maintenance page implementation to be served by Nginx during 502, 503, or 504 errors.

## Components
- **Template:** `./templates/offline.html` - The static HTML content.
- **Nginx Configuration:** `./nginx-staging.conf.template` and `./nginx-production.conf.template` include the `proxy_intercept_errors on;` and `error_page 502 503 504 /offline.html;` directives, along with a dedicated `location /offline.html` block.
- **Docker Compose:** `./docker-compose.vm.yml` mounts the template via:
  `- ./templates/offline.html:/var/www/html/offline.html:ro`

## Verification & Maintenance
If the maintenance page is not appearing during downtime:
1. Verify the `docker-compose.vm.yml` volume mapping is correctly applied in the running container.
2. Ensure Nginx reloads the configuration after any changes to `nginx-*.conf.template`.
3. Check the Nginx logs for the container to confirm the `proxy_intercept_errors` is actively handling the backend status codes.
