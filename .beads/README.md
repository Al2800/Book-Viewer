# BookQuotes Beads Tracker

This repository uses:

- [`beads_rust`](https://github.com/Dicklesworthstone/beads_rust) via the `br` CLI for issue mutations.
- [`beads_viewer`](https://github.com/Dicklesworthstone/beads_viewer) via the `bv` CLI for dependency-aware triage and planning.
- `.beads/issues.jsonl` as the authoritative, Git-tracked issue ledger.

## Required operating mode

The historical ledger intentionally contains both `bd-*` and `book-quote-*` issue IDs. Preserve those durable references by running `br` in JSONL-only mode:

```bash
br --no-db ready --json
br --no-db list --status open --json
br --no-db show <issue-id> --json
br --no-db create "Issue title" --type task --priority 1 --json
br --no-db update <issue-id> --status in_progress --json
br --no-db close <issue-id> --reason "Completed" --json
```

Do not initialize a replacement database, rename issue prefixes, or edit `issues.jsonl` directly. `br --no-db` performs atomic JSONL writes while preserving mixed IDs.

## Viewer workflow

Use only robot flags in agent/non-interactive sessions; bare `bv` launches the interactive TUI.

```bash
bv --robot-triage --brief
bv --robot-next
bv --robot-plan
bv --robot-insights
```

Start with `bv --robot-triage --brief`. The viewer reads `.beads/issues.jsonl` and computes graph metrics without becoming a second source of truth.

## Git workflow

Beads state is committed and pushed with the work it describes:

```bash
br --no-db list --json
bv --robot-triage --brief
git add .beads/ <related-files>
git commit -m "..."
git push
git status --short --branch
```

Do not maintain a duplicate Markdown or GitHub-Issues backlog.

## Legacy migration record

On 2026-08-11, the tracked legacy JSONL was made compatible with `beads_rust` 0.2.22. Only comment-ID JSON types changed; issue IDs, issue text, dependencies, timestamps, labels, and comments were preserved.

- 204 quoted numeric comment IDs were converted to JSON integers.
- Three UUID comment IDs, which the current `br` schema cannot represent, were mapped to the next unused integers:
  - `019e9d55-8a28-7509-9272-50c66870df82` → `503`
  - `019e9d55-8a68-7b13-917f-f1059905d5d0` → `504`
  - `019e9d55-8a49-78aa-ac26-e052acb6a8ae` → `505`
- The pre-migration ledger SHA-256 was `395875efada5d4655c94ce4852a1db1ba8fc824adeb88cf044ed1a130406ccfa`.

Future issue changes must go through `br --no-db`.
