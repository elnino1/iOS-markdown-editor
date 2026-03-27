## Formatting Toggle (UX improvement)
- **Request:** Bold/Italic/Bullet buttons should toggle — if selected text is already bold (`**...**`), tapping Bold should remove the markers rather than add more
- **Context:** Raised after Phase 4 completion. Currently tapping Bold on already-bold text nests markers.
- **Scope:** v1.2 or Phase 5 candidate. Requires detecting existing markers around selection in FormattingService before deciding insert vs remove.
