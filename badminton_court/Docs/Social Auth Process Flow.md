# Social Auth Process Flow

This document details the social media authentication process based on the `social-auth.feature` Cypress tests.

## 1. Social Media Sign Up Flow
```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant Django as Django Server
    participant Provider as Social Provider (Google/FB/Twitter)

    User->>Browser: Clicks Social Signup Button
    Browser->>Django: GET /social/signup/<provider>/
    Django-->>Browser: Redirect to Social Provider OAuth
    User->>Provider: Authorizes Application
    Provider-->>Django: Redirect with OAuth Code
    Django->>Provider: Exchange Code for Access Token
    Provider-->>Django: Return User Profile
    Django->>Django: Create/Link User
    Django-->>Browser: Redirect to Email Verification
```

## 2. Social Media Sign In Flow
```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant Django as Django Server
    participant Provider as Social Provider (Google/FB/Twitter)

    User->>Browser: Clicks Social Login Button
    Browser->>Django: GET /social/login/<provider>/
    Django-->>Browser: Redirect to Social Provider OAuth
    User->>Provider: Authenticates
    Provider-->>Django: Redirect with OAuth Code
    Django->>Django: Validate Existing Account
    Django->>Django: Create Session
    Django-->>Browser: Redirect to Dashboard
```
