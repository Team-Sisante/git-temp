# 502 on Staging After Deployment – Missing Template Tag Library
## Source: Docs/Trouble-shooting/502-Missing-Template-Tag.md

**Status:** Resolved (June 26, 2026)

### Problem
After deploying humrine_site staging, the site returned a 502 error. The health check was correctly configured, and the web container was running, but the backend remained UNHEALTHY.

### Root Cause
The home page template loaded `{% load blog_tags %}`, but the compiled binary did not include the `blog/templatetags/` directory. Django raised a `TemplateSyntaxError`, causing a 500 response for every request, including the health check probe. The load balancer then marked the backend as UNHEALTHY, resulting in a 502 for all traffic.

### Solution
Added `blog/templatetags` to the list of directories collected as data in `Dockerfile.compile`:

```dockerfile
    && for dir in \
        ...
        blog/templatetags \
    ; do \
        ...
```

After rebuilding the binary and redeploying, the template tag was found, the home page loaded correctly, and the health check passed.

### Related Files
- `Dockerfile.compile` – data collection loop
- `blog/templatetags/blog_tags.py` – the template tag library
- `templates/home/home.html` – the home page that uses `{% load blog_tags %}`