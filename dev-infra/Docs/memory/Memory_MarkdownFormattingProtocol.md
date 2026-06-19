# Memory Detail: Markdown Formatting Protocol for Code Blocks

## Purpose
To ensure that code snippets and file contents shared in chat interfaces are displayed correctly without breaking the page layout or "flooding" the canvas, AND so the user gets a copy button on every shared block.

## The Rule (Final — Updated 2026-06-19)

When sharing a markdown document that contains triple-backtick code blocks inside it, wrap the ENTIRE document in a 4-backtick fence with the `text` language tag. The outer fence is: four backticks followed immediately by the word `text`. The closing fence is: four backticks on their own line.

Example structure (described in words, not literal backticks, to avoid prematurely closing this very block):

- OPEN: four backticks + the word text
- ...document content, including any triple-backtick code blocks like ```javascript ... ``` ...
- CLOSE: four backticks on their own line

### Why `text` and not `markdown`?
- The `markdown` language tag in this IM does NOT trigger code-block rendering with a copy button. It renders as plain page text.
- The `text` language tag DOES trigger code-block rendering with a copy button.
- The 4-backtick outer fence allows the inner 3-backtick blocks to be displayed as literal text (not parsed as nested code blocks), which is exactly what we want when sharing a markdown document for the user to copy.

### Why 4 backticks and not 3?
- A 3-backtick outer fence would be prematurely closed by the first inner 3-backtick fence.
- A 4-backtick outer fence is not closed by inner 3-backtick fences — only by another 4-backtick fence.

### Critical: Do NOT put literal 4-backtick sequences inside the document content
If the document you are sharing contains a literal 4-backtick sequence (e.g., you are showing someone what the outer fence looks like), the outer fence will close prematurely and the rest of the document will spill onto the page canvas. When you need to refer to the outer fence inside a document, describe it in words ("four backticks followed by the word text") instead of typing the literal sequence.

## Forbidden Formats (Confirmed Broken in This IM)

- 3-backtick markdown fence (````markdown` with 3 backticks) — no copy button; premature close when content has inner triple backticks
- 4-backtick markdown fence — renders as plain page text, NO code block at all
- 3-backtick text fence with inner triple backticks — premature close

## Allowed Formats

- 4-backtick text fence — FOR SHARING MARKDOWN DOCUMENTS (this is the primary format)
- 3-backtick javascript fence — FOR SINGLE JAVASCRIPT SNIPPETS WITH NO INNER FENCES
- 3-backtick bash fence — FOR SINGLE BASH SNIPPETS
- 3-backtick python fence — FOR SINGLE PYTHON SNIPPETS
- 3-backtick json fence — FOR SINGLE JSON SNIPPETS

## File Modification Protocol (Updated 2026-06-19)

When a memory file or any project file needs to be updated:

1. NEVER use the `Write` tool. It opens a tabbed window in the IM and does not auto-close.
2. NEVER use the `Edit` tool. It opens a tabbed window in the IM and does not auto-close.
3. NEVER use `Bash` with `cat >`, `cat >>`, `sed -i`, `echo >`, or any file-WRITING command. The output opens a tabbed window in the IM and does not auto-close.
4. INSTEAD: Display the complete updated file contents inline as a 4-backtick `text` block. The user will copy it with the copy button and paste it into their editor to save.

## Read-Only Tool Use (Updated 2026-06-19)

Tools that open tabbed windows MAY be used for READ-ONLY analysis (vision, image analysis, file reads for inspection, grep, find, etc.) under the following conditions:

1. The tool call is for READ-ONLY purposes — it does NOT modify any file.
2. The tabbed window is CLOSED immediately after the result is obtained. The AI assistant should not leave the tab open or rely on the user to close it.
3. The result is then summarized inline in the chat as plain text (or as a 4-backtick `text` block if the result is itself a document/code snippet).
4. If the tool call is for image/vision analysis, the AI assistant should summarize what was seen in plain text in the next chat message — NOT redirect the user to the tabbed window.

### Allowed Read-Only Tools
- `Bash` with read-only commands: `ls`, `grep`, `find`, `cat` (for reading), `head`, `tail`, `wc`, `file`, `stat`
- `Read` tool (for reading file contents — the output opens a tab, but it is read-only and should be closed immediately)
- Vision tools (`z-ai vision` CLI, VLM SDK) for analyzing uploaded images — the AI assistant reads the result, closes the tab, and summarizes inline
- `Glob` tool (for finding files by pattern)
- `Grep` tool (for searching file contents)

### Forbidden Tools (Always)
- `Write` tool — opens a tabbed window that doesn't auto-close; use inline 4-backtick `text` block instead
- `Edit` tool — opens a tabbed window that doesn't auto-close; use inline 4-backtick `text` block instead
- `Bash` with file-WRITING commands (`cat >`, `cat >>`, `sed -i`, `echo >`, `printf >`, etc.) — same reason

## Self-Check Before Every Document Share

Before pasting a markdown document into the chat, ask:
1. Is the outer fence 4 backticks with the `text` tag? If no, fix it.
2. Does the document end with a 4-backtick closing fence on its own line? If no, fix it.
3. Is the entire document in ONE message (not split across messages)? If no, restructure.
4. Does the document content contain any literal 4-backtick sequence? If yes, replace with a word description ("four backticks followed by the word text") to avoid prematurely closing the outer fence.

## Self-Check Before Every File Modification

Before modifying any file, ask:
1. Will this tool call open a tabbed window in the IM? If yes, STOP.
2. Is there a way to display the change inline as a 4-backtick `text` block instead? If yes, do that.
3. Has the user explicitly authorized a file-modifying tool call? If no, do not modify files.

## Self-Check Before Every Read-Only Tool Use

Before calling a read-only tool that opens a tabbed window (vision, Read, etc.), ask:
1. Is this for READ-ONLY purposes (no file modification)? If no, STOP and use the file-modification protocol instead.
2. Will I be able to close the tab immediately after getting the result? If yes, proceed.
3. Will I summarize the result inline in the next chat message (not redirect the user to the tab)? If yes, proceed.

## Status
- Established: 2026-06-18 (original)
- Updated: 2026-06-19 (final format confirmed: 4-backtick text fence; file-modification tools forbidden; read-only tools allowed if tab is closed immediately)
- Applies to: All AI assistants sharing markdown/code content in this IM environment
- Enforcement: Self-check before every document share, file modification, AND read-only tool use