# Process Flows: Badminton Court

This document serves as the visual reference for the core infrastructure and configuration processes of the `badminton_court` project.

---

## 1. CI/CD Deployment Flow (High-Level)
This diagram illustrates the progression from code change to active deployment.

```mermaid
graph TD
    Dev[Developer] -->|Push Code| GitHub[GitHub Repo]
    GitHub -->|Trigger| GoCDServer[GoCD Server]
    GoCDServer -->|Orchestrate| Agent[GoCD Agent Build VM]
    Agent -->|Build Binary & Docker| Image[Docker Image]
    Image -->|Push| GHCR[GHCR Registry]
    Agent -->|Deploy Command| TargetVM[Target VM: Staging/Prod]
    TargetVM -->|Pull Image| GHCR
    TargetVM -->|Start Container| Running[Application Running]
```

---

## 2. Configuration Loading Flow (High-Level)
This diagram illustrates how environment variables are injected into the Django application.

```mermaid
graph LR
    EnvFile[.env File] -->|Injected by Docker| DockerEnv[Docker Container Environment]
    DockerEnv -->|os.environ| DjangoSettings[Django settings/base.py]
    DjangoSettings -->|Strict Read| App[Django Application]
```

---

## 3. End-to-End Deployment Sequence
This diagram details the interaction between components during a deployment operation triggered by the developer.

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GoCD as GoCD Server
    participant Build as Build Agent (VM)
    participant Registry as GHCR
    participant Target as Target VM (Staging/Prod)

    Dev->>GoCD: Trigger Pipeline (Option 2.1)
    GoCD->>Build: Orchestrate Task
    Build->>Build: Clone/Fetch Repo
    Build->>Build: Build Binary & Docker Image
    Build->>Registry: docker push (Authentication via PAT)
    Build->>Target: Execute Deploy Command (SSH)
    Target->>Registry: docker pull
    Target->>Target: Restart Container
```

---

## 4. Configuration Initialization Sequence
This diagram details how the application environment is initialized upon container startup.

```mermaid
sequenceDiagram
    participant Docker as Docker Compose
    participant Container as Container OS
    participant Settings as Django (base.py)

    Docker->>Container: Start Container (env_file: .env)
    Docker->>Container: Launch Application
    Container->>Settings: Initialize Django Settings
    Settings->>Settings: Read os.environ (Strict Check)
    Settings->>Settings: Validate Configuration (Raises ImproperlyConfigured)
    Settings->>Container: Application initialized
```
