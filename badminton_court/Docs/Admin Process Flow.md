# Admin Process Flow

This document details the administrative management process based on the `admin-flow.feature` Cypress tests.

## 1. Admin Login Process
```mermaid
sequenceDiagram
    participant Admin
    participant Browser
    participant Django as Django Server
    participant DB as SQLite Database

    Admin->>Browser: Enters Credentials on Admin Panel
    Browser->>Django: POST /admin/login/
    Django->>DB: Verify Admin Credentials
    DB-->>Django: Admin Verified
    Django->>Django: Set Admin Session
    Django-->>Browser: Redirect to Admin Dashboard
```

## 2. Group Management (User Assignment)
```mermaid
sequenceDiagram
    participant Admin
    participant Browser
    participant Django as Django Server
    participant DB as SQLite Database

    Admin->>Browser: Navigates to User Management
    Admin->>Browser: Selects User & Group
    Browser->>Django: POST /admin/groups/add-user/
    Django->>DB: Update User Group Association
    DB-->>Django: Success
    Django-->>Browser: Show Confirmation Message
```
