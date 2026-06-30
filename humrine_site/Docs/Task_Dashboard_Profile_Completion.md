# Task: Registered-User Dashboard & Profile Completion for humrine_site

Modeled on `badminton_court`'s actual implementation (verified by reading its
real code, not assumed): `Customer` model + `profile_complete` flag,
`@require_completed_profile` decorator gating the one core action (booking),
a dashboard with role-based content, and Cucumber `.feature` E2E tests.

## Design Mapping (badminton_court → humrine_site)

| badminton_court | humrine_site |
|---|---|
| `Customer` model (name, phone, address, `profile_complete`) | `Profile` model (display_name, avatar, bio, `profile_complete`) |
| `@require_completed_profile` gates **creating a booking** | Same decorator pattern gates **posting a comment / leaving a reaction** |
| Dashboard shows today's bookings, role-based stats | Dashboard shows "My Activity" — your own comments/reactions, links back to each post/toon |
| Auto-`Customer` on social signup via `user_signed_up` signal | Auto-`Profile` on **any** signup (regular or social) via same signal pattern |
| New app: `court_management` | New app: `profiles` (avoids name clash with allauth's own `account` app) |

**Key deviation from badminton_court, stated explicitly:** badminton_court
only auto-flags *social* signups as incomplete (regular signups have no
auto-Customer-creation path in the signal at all — looks like a gap in their
own implementation). For humrine_site, `profile_complete` is computed simply
from whether `display_name` is set, for every user regardless of signup
method. Simpler, no special-casing, no extra group/permission machinery
needed since humrine_site doesn't have badminton_court's staff/permissions
model to grant.

## Recommended Registered-User Perks

**Core (this build):**
- Comment on blog posts / toon stories (already built in `engagement` —
  now properly gated behind profile completion, not just login)
- React/like (same)
- "My Activity" dashboard — your own comments + reactions, linked back to
  source content
- Profile: display name + avatar (this *is* the completion requirement)
- Edit / delete your own comments (new — doesn't exist in `engagement` yet,
  near-free addition since the model's already there)

**Deferred (flagged, not in this build — no existing infra to lean on):**
- Bookmarks / reading list
- Reply notifications
- Follow a toon series for updates

## Tasks

### Phase 1 — Django: `profiles` app — ✅ DONE
- [x] Done — Create `profiles` app (`apps.py`, `__init__.py`, `admin.py`, `models.py`, `views.py`, `urls.py`, `tests.py`)
- [x] Done — `Profile` model: `user` (OneToOne), `display_name`, `avatar` (ImageField, reuses `humrine_site/image_utils.py` resize, downscales to 400px), `bio` (optional). `profile_complete` implemented as a **computed property** (`bool(display_name.strip())`), not a stored bool — see README for reasoning.
- [x] Done — Migration for `Profile` (`profiles/migrations/0001_initial.py`) — confirmed applies cleanly via `migrate`
- [x] Done — Signal: auto-create `Profile` on `user_signed_up` (allauth) — covers both regular and social signup (deliberate deviation from badminton_court's social-only behavior; see task doc design section)
- [x] Done — `require_completed_profile` decorator in `profiles/decorators.py` — uses `get_or_create`, not a bare `.get()`, so it's safe for superusers/pre-existing users too
- [x] Done — Dashboard view (`profiles/views.py`): "My Activity" — own comments + reactions from `engagement` via `related_name`s, profile-incomplete nudge banner, defensively filters out comments/reactions on since-deleted content (GenericForeignKey doesn't cascade)
- [x] Done — Dashboard template (`profiles/templates/profiles/dashboard.html`)
- [x] Done — Complete-profile view (GET form / POST save) with `session['profile_next']` redirect-back pattern, falls back to dashboard if nothing stashed
- [x] Done — Complete-profile template (`profiles/templates/profiles/complete_profile.html`)
- [x] Done — Wire `profiles.urls` into `humrine_site/urls.py` (`/dashboard/`, `/profile/complete/`) — confirmed no collision with `home.urls`'s own `''` registration
- [x] Done — Add `profiles` to `INSTALLED_APPS`

**Bonus fixes found and resolved while implementing Phase 1 (not originally scoped, but directly adjacent):**
- `core/management/adapters.py` had a real, pre-existing bug: `CustomSocialAccountAdapter.get_login_redirect_url` called `CustomEmailAdapter._check_profile_completion(...)`, a method that didn't exist anywhere — every social login would have hit `AttributeError`. Implemented it. Someone had clearly started this exact feature before and left the hook dangling.
- `toons.ToonStory` had no `get_absolute_url()` (unlike `blog.Post`, which already had one) — added it so the dashboard template can link back to either content type uniformly.

**Verification:** 16 new committed tests in `profiles/tests.py`, all passing. Full repo-wide suite (`blog`+`toons`+`engagement`+`profiles`) = 34/34 passing. `makemigrations`/`migrate`/`check` all clean in an isolated sandbox. Manual end-to-end pass via Django's test client covering the full signup → incomplete → nudge → complete → redirect-back flow, plus the decorator and adapter fix in isolation. **Not verified against the real Windows/Docker environment or an actual deploy.**

Delivered as `phase1_dashboard_profile.zip` with a `README.md` covering exactly what's new vs. modified.

### Phase 2 — Gate engagement actions behind profile completion — ✅ DONE
- [x] Done — Apply `@require_completed_profile` to `engagement.views.add_comment`
- [x] Done — Apply `@require_completed_profile` to `engagement.views.toggle_reaction`
- [x] Done — Update `engagement` AJAX JS to handle the redirect-to-profile-completion response sensibly (not just silently fail)

**Found at the start of this phase: Phase 1 was never actually committed to the real repo.** Re-applied it from the saved zip before building Phase 2 on top, so this round's delivery is Phase 1 + Phase 2 combined in one zip.

**Also found: `engagement/static/` (the AJAX JS/CSS) was missing from the real repo entirely** — only the Python side of the original comments/reactions feature had landed. The template's `{% static %}` tags were 404ing; recreated both files, with this phase's `profile_incomplete` handling built in from the start.

**`profiles/decorators.py` needed real changes, not just an `@apply`:** the gated views (`add_comment`, `toggle_reaction`) are POST-only AJAX/API endpoints, not page views — badminton_court's original decorator pattern (built only for gating a real page view) would have broken in two ways here: (1) stashing the API endpoint's own URL as the redirect-back target, which 405s on retry since it's POST-only — fixed by preferring `HTTP_REFERER` for non-GET requests; (2) a blind 302 redirect on an AJAX request gets silently followed by `fetch()`, handing the caller HTML where it expected JSON — fixed with a JSON `profile_incomplete` response instead.

**Found and fixed a real regression:** applying the gating broke 7 of the 11 existing `engagement` tests (confirmed by running the suite before fixing — 4 failures + 3 errors), since none of them gave their test users a completed profile. Fixed `setUp()` to create completed profiles for the existing users, and added 8 new tests specifically for the gating behavior (`EngagementProfileGatingTestCase`).

**Verification:** full repo-wide suite now 42/42 passing (was 34 after Phase 1; +8 net from engagement's growth). Manual end-to-end via test client covering AJAX blocking, the Referer-based redirect-back fix, non-AJAX redirects, and the complete blocked→complete-profile→retry→succeed loop landing back on the exact originating page. **JS itself not run in an actual browser** — reasoned through and mirrors the existing success-path code exactly, but only the Python side was exercised.

Delivered as `phase1_and_2_dashboard_profile_gating.zip` (combined, since Phase 1 wasn't separately committed) with a `README.md` covering both phases in detail.

### Phase 3 — Comment edit/delete (new perk)
- [ ] Pending — Add `edit_comment` / `delete_comment` views, author-only check
- [ ] Pending — Wire into comment template (edit/delete controls, own comments only)
- [ ] Pending — Tests for edit/delete (author-only enforcement, anonymous/other-user rejection)

### Phase 4 — Nav / UX
- [ ] Pending — Add Dashboard / Profile / Logout links to `templates/base.html` nav (currently has no auth-aware nav items at all)

### Phase 5 — Cypress E2E (mirrors badminton_court's real file layout)
- [ ] Pending — `cypress/e2e/authentication/auth-flow.feature` (register, login, logout, invalid creds, duplicate email, mismatched passwords)
- [ ] Pending — `cypress/e2e/authentication/social-auth-flow.feature` (social buttons present; **key scenario:** social signup → dashboard with limited rights → attempt to comment → redirected to profile completion → complete profile → granted access → redirected back to the comment action)
- [ ] Pending — `cypress/e2e/forget-password-flow.feature`
- [ ] Pending — `cypress/e2e/posteio/posteio-flow.feature`
- [ ] Pending — `cypress/e2e/admin/admin-flow.feature`
- [ ] Pending — `cypress/e2e/connectivity.cy.js`
- [ ] Pending — Supporting step definitions / `cypress/support/commands/*.cy.js` as needed for the above

### Phase 6 — Tests (Django)
- [ ] Pending — `profiles/tests.py`: Profile auto-creation, `profile_complete` computation, decorator behavior (redirect when incomplete, pass-through when complete, `profile_next` redirect-back)
- [ ] Pending — Update `engagement/tests.py` for the new gating (existing tests may need adjusting if they assume login alone is sufficient)

## Status Legend
Mark each item **Done** or **Pending** as it's completed. Nothing above is implemented yet — this file is the reference/checklist only.
