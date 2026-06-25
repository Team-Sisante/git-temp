# User Profile Completion Notice
## Source: Docs/Trouble-shooting/User Profile Completion Notice.md

**Status:** Completed (June 25, 2026)

### Problem
After signing up via social media, users were silently redirected to the profile completion page when attempting to book, with no explanation. This was confusing during demos and for real users.

### Solution
- Added a Django messages notification on the booking creation page (or the profile completion redirect) that informs the user:  
  *"Please complete your profile before making a booking."*
- The notification includes a link to the profile completion page.

### Related Files
- `badminton_court/court_management/views.py` (booking create view or profile completion redirect)
- `badminton_court/templates/` (relevant booking template)