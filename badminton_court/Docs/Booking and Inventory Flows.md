# Booking & Inventory Flows

This document details the court reservation, inventory management, and stock tracking processes based on the `booking-flow.feature` and `inventory.feature` Cypress tests.

## 1. Booking Management
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
```

## 2. Inventory Product Management
```mermaid
sequenceDiagram
    participant Admin
    participant Browser
    participant Django as Django Server
    participant DB as SQLite Database

    Admin->>Browser: Submit "Add Product" Form
    Browser->>Django: POST /admin/products/add/
    Django->>DB: Validate Data (Check Duplicates)
    DB-->>Django: Valid
    Django->>DB: Save Product Record
    DB-->>Django: Success
    Django-->>Browser: Show Success Message
```

## 3. Inventory Stock Transaction
```mermaid
sequenceDiagram
    participant Admin
    participant Browser
    participant Django as Django Server
    participant DB as SQLite Database

    Admin->>Browser: Submit "Add Transaction" Form
    Browser->>Django: POST /admin/transactions/add/
    Django->>DB: Update Product Quantity
    DB-->>Django: Quantity Updated
    Django->>DB: Save Transaction Record
    DB-->>Django: Success
    Django-->>Browser: Show Success Message
```

## 4. Low-Stock Alert System
```mermaid
sequenceDiagram
    participant Task as Scheduled Task
    participant Django as Django Server
    participant DB as SQLite Database
    participant Email as Mail Server

    Task->>Django: Runs low-stock check
    Django->>DB: Query for low-stock products
    DB-->>Django: List of Products
    Django->>Email: Send Alert Notifications
    Email-->>Task: Notification Queued
```
