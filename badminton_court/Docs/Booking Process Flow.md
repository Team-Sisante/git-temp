# Booking Process Flow

This document details the court reservation and management process based on the `booking-flow.feature` Cypress tests.

## 1. Create and View Booking
```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant Django as Django Server
    participant DB as SQLite Database

    User->>Browser: Select Slot & Clicks "Book"
    Browser->>Django: POST /bookings/create/
    Django->>DB: Check Availability
    DB-->>Django: Available
    Django->>DB: Create Booking Record
    DB-->>Django: Success
    Django-->>Browser: Redirect to Details Page
    User->>Browser: Requests Booking Details
    Browser->>Django: GET /bookings/<id>/
    Django->>DB: Fetch Booking
    DB-->>Django: Data
    Django-->>Browser: Render Details
```

## 2. Process Payment
```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant Django as Django Server
    participant DB as SQLite Database

    User->>Browser: Clicks "Pay"
    Browser->>Django: POST /bookings/pay/<id>/
    Django->>DB: Update Booking Status (Paid)
    DB-->>Django: Success
    Django-->>Browser: Confirm Payment
```
