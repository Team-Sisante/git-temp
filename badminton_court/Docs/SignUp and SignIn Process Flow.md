# SignUp and SignIn Process Flow

This document details the authentication process for the Badminton Court application based on the `auth-flow.feature` Cypress tests.

## 1. Registration Process
```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant Django as Django Server
    participant DB as SQLite Database

    User->>Browser: Enters Registration Details
    Browser->>Django: POST /register/
    Django->>Django: Validate Input
    Django->>DB: Check for duplicate email
    DB-->>Django: Email Available
    Django->>DB: Create User Record
    DB-->>Django: Success
    Django-->>Browser: Redirect to Login/Dashboard
```

## 2. Login Process
```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant Django as Django Server
    participant DB as SQLite Database

    User->>Browser: Enters Credentials
    Browser->>Django: POST /login/
    Django->>DB: Authenticate User
    DB-->>Django: User Verified
    Django->>Django: Create Session
    Django-->>Browser: Redirect to Home/Dashboard
```
