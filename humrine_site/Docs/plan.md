# Plan: Create humrine.com Django Application

This plan outlines the creation of a new Django-based web application for the main humrine.com website.

## Objective
Create a professional, modern, and "alive" Django application for the main humrine.com site, serving as the landing page and hub for other applications like Badminton Court and PaySol.

## Key Files & Context
- **Project Name:** `humrine_site`
- **Location:** `/home/solomiosisante/humrine_site`
- **Dependencies:** Django 6.x, django-bootstrap5 (consistent with other projects).
- **Architecture:** Unified environment-driven settings.

## Implementation Steps

### 1. Project Initialization
- (Already implemented)

### 2. Unified Environment-Driven Configuration
- Implement a unified settings structure in `humrine_site/settings/`:
    - `base.py`: Core Django settings that reads all environment-specific configurations directly from `os.environ` using `python-dotenv`.
    - Delete `dev.py` and remove modular settings modules to prevent split-brain configuration.
- Update entry points (`manage.py`, `wsgi.py`, `asgi.py`) and `docker-compose` files to point to `humrine_site.settings.base` as the single source of truth for settings.

### 3. Core Application Development
- (Already implemented)

### 4. Aesthetics & Design
- (Already implemented)

### 5. Integration
- (Already implemented)

## Verification & Testing
- Run `python manage.py check` to verify settings.
- Run migrations.
- Start the development server and verify the homepage renders correctly with local .env.
- Verify production container starts with production .env.

## Migration & Rollback
- Rollback involves reverting settings to modular structure if needed.
