# Task: Comments & Reactions for the Blog and Toons Modules (humrine_site)

## Goal
Enhance the `blog` and `toons` apps in `humrine_site` so subscribed readers can:
- Comment on a blog post or a toon story
- Like / heart a post, story, or its image
- React with additional emoticons to express how they feel

## Current Stack
- Django-based site (`humrine_site`)
- Rich text editing for blog posts and toon stories via `django-ckeditor` (`ckeditor` + `ckeditor_uploader`)
- Deployed via Docker Compose on a GCP VM (per project `dev-infra` memory files)

## Live Reference Content
- Sample blog post: https://humrine.com/blog/aeropace-back-to-school-handog-ng-aeropace-sa-ating-mga-bata/
- Sample toon story: https://humrine.com/toons/the-tale-of-the-pirate-and-the-model/

## In Scope
1. **Blog module**
   - Comment thread under each blog post
   - Like / heart / emoticon reactions on the post (and optionally its image)
2. **Toons module**
   - Comment thread under each toon story
   - Like / heart / emoticon reactions on the story (and optionally individual story images)

## Out of Scope (for now)
- Anonymous (non-subscriber) comments or reactions — gated to subscribed readers only
- Nested/threaded replies, unless requested later

## Known Blocker
A persisting error is occurring during implementation.
- **Details:** TBD — to be filled in once the relevant code and full traceback are shared.
- **Suspected area:** TBD (model/migration, `ckeditor_uploader` config, view, or template)

## Proposed Data Model (draft — to revise once existing `blog`/`toons` models are visible)
- **`Comment`**: `author` (FK to subscriber/user), `content` (plain text, not full CKEditor — see security note), `created_at`, generic relation to either `BlogPost` or `ToonStory` (via `ContentType` + `object_id`, or two nullable FKs)
- **`Reaction`**: `user`, `reaction_type` (like / heart / emoji choice), generic relation to `BlogPost`, `ToonStory`, or an individual story image
- Decide: one reaction per user per object (`unique_together`) vs. allowing multiple reaction types per user on the same object

## Security Notes
- Don't give end-user comments full CKEditor/WYSIWYG — that's appropriate for admin-authored posts/stories, not visitor-submitted comments, since it widens stored-XSS risk. A plain textarea (optionally with a sanitizer like `django-bleach`) is safer.
- Enforce the subscriber-only check at both the view level and any AJAX/API endpoint used to submit comments or reactions, not just in the template.

## Next Steps
1. Share the relevant files (models, views, forms, urls, templates, and the `ckeditor`/`ckeditor_uploader` settings) plus the full traceback of the persisting error.
2. Diagnose and fix the blocker.
3. Implement `Comment` and `Reaction` models + migrations.
4. Wire up views/templates for the blog and toons detail pages.
5. Add subscriber permission checks.
6. Test against the two sample URLs above.

## How Code Will Be Shared
TBD — see options discussed in chat: direct file upload in this conversation, a scrubbed public mirror repo, or working directly in the local repo via Claude Code.