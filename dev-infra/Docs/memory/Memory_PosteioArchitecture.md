# Memory Detail: Poste.io Architecture

## Overview
Poste.io is designed to be a self-contained, low-maintenance mail server. Its architecture prioritizes simplicity, self-containment, and ease of backup.

## Core Architecture
- **Database Backend:** Poste.io uses **SQLite** as its primary database backend. All user data, domain settings, and configurations are stored in a single SQLite file, usually located in the data directory (typically mounted as `/data` in the container).
- **Self-Contained:** There is no requirement for an external database server (like MariaDB, MySQL, or PostgreSQL). This simplifies deployment and makes backups straightforward—backing up the `/data` directory is sufficient.
- **Optional Services:** While SQLite is the core, Poste.io can optionally utilize external services like **Elasticsearch** if full-text search capabilities for high-volume logs or mail are needed.

## Configuration & SMTP Relay
- **Persistence:** All configuration files and data are persisted in the directory mounted to `/data` in the container.
- **Relay Configuration:** The SMTP relay settings are not stored in an external database, but are likely managed via the internal Poste.io administration console, which stores them in the SQLite database or internal configuration files within the data directory.
- **Known Issue:** The REST API for configuration management has been observed to be unstable/broken in some versions, often leading to internal server errors (500) during authentication or API calls.
- **Recommended Strategy:** When the API fails, direct manipulation of the configuration (or investigating the internal application logs/source code to find the configuration generation script) is necessary.
