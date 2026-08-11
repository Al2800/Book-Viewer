# BookQuotes - Agent Instructions

### RULE 1 – ABSOLUTE (DO NOT EVER VIOLATE THIS)
You may NOT delete any file or directory unless I explicitly give the exact command in this session.

This includes files you just created (tests, tmp files, scripts, etc.).
You do not get to decide that something is "safe" to remove.
If you think something should be removed, stop and ask. You must receive clear written approval before any deletion command is even proposed.
Treat "never delete files without permission" as a hard invariant.

### IRREVERSIBLE GIT & FILESYSTEM ACTIONS
Absolutely forbidden unless I give the exact command and explicit approval in the same message:

git reset --hard
git clean -fd
rm -rf
Any command that can delete or overwrite code/data
Rules:

If you are not 100% sure what a command will delete, do not propose or run it. Ask first.
Prefer safe tools: git status, git diff, git stash, copying to backups, etc.
After approval, restate the command verbatim, list what it will affect, and wait for confirmation.
When a destructive command is run, record in your response:
The exact user text authorizing it
The command run
When you ran it
If that audit trail is missing, then you must act as if the operation never happened.

## Project Overview

**BookQuotes** is an iOS app that transforms paper book annotations into a digital quote library. Capture photos of book pages with underlined passages, margin notes, and highlights, then use AI to extract and organize your favorite quotes.

### Tech Stack
- **Platform:** iOS 17+ (targeting iOS 26 Liquid Glass)
- **UI:** SwiftUI
- **Architecture:** MV pattern (Model-View)
- **State:** `@Observable`, `@State`, `@Environment`
- **Persistence:** SwiftData local storage (Cloud sync is not enabled in v1)
- **AI:** Hugging Face quote extraction via the BookQuotes proxy
- **Image Processing:** Remote AI first for consented subscribers, with Apple Vision OCR fallback
- **Camera:** AVFoundation / PhotosUI
- **Networking:** async/await with URLSession

### Core Features
1. **Book Registration** - ISBN barcode catalogue lookup + manual entry
2. **Quote Capture** - Multi-page batch capture with image quality assessment
3. **Custom Markings** - User-defined annotation vocabulary (underline, highlight, margin notes)
4. **Quote Editing** - Correct LLM extraction errors with confidence scoring
5. **Data Quality** - Duplicate detection, correction feedback loop
6. **Offline Queue** - Capture anywhere, process when online
7. **Library** - Grid/list view, search, collections, tags
8. **Export** - Markdown, Plain Text, JSON, Notion, Obsidian formats

### Key Data Models
- `Book` - Title, author, cover image, reading status, quotes relationship
- `Quote` - Text, page number, margin note, marking type, confidence
- `Collection` - Custom quote groupings with icon/color
- `Tag` - Labels for cross-cutting organization
- `MarkingDefinition` - User's custom annotation vocabulary

### Architecture Layers
```
App/           → Entry point, tabs, routing (AppTab, AppRouter)
Models/        → SwiftData models (Book, Quote, Collection, Tag)
Services/      → RemoteModelQuoteExtractor, CameraService, ImageQualityAnalyzer, ISBNScanner
Features/      → Feature modules (Library, Capture, BookDetail, QuoteDetail)
Components/    → Reusable UI (QuoteCard, BookCoverView, AsyncButton)
Utilities/     → Helpers, extensions, constants
```

### Project Structure
```
BookQuotes/
├── App/                    # App entry, tabs, routing
├── Models/                 # SwiftData models
├── Services/               # Remote AI, OCR, Camera, Persistence, ImageQuality, ISBN
├── Features/               # Feature modules (Library, Capture, BookDetail, etc.)
├── Components/             # Reusable UI components
├── Utilities/              # Helpers, extensions
└── Resources/              # Assets, localization
```

### Reference Documents
- `IMPLEMENTATION_PLAN.md` - Full project plan, phases, architecture
- `docs/DATA_MODELS.md` - SwiftData models, relationships, queries
- `docs/API_INTEGRATION.md` - Remote quote extraction contract and legacy reference
- `docs/APP_STORE_CONNECT.md` - TestFlight/App Store Connect API process and local key config shape
- `docs/UI_COMPONENTS.md` - Design system, components, screens
- `docs/CUSTOM_MARKINGS.md` - User-defined annotation vocabulary system
- `docs/OFFLINE_AND_EXPORTS.md` - Offline queue, Notion/Obsidian export
- `docs/PRIORITY_FEATURES.md` - Priority features with full technical specs

### Key Patterns
- **SwiftUI skills apply**: Use MV pattern, `@Observable` for view models
- **iOS 26 Liquid Glass**: Use `.glassEffect()` with fallback for older iOS
- **Async/await**: All network and AI calls use Swift concurrency
- **Vision framework**: Pre-upload blur detection, brightness analysis, text confidence

### Code Editing Discipline
Do not run scripts that bulk-modify code (codemods, invented one-off scripts, giant sed/regex refactors).
Large mechanical changes: break into smaller, explicit edits and review diffs.
Subtle/complex changes: edit by hand, file-by-file, with careful reasoning.
Backwards Compatibility & File Sprawl
We optimize for a clean architecture now, not backwards compatibility.

No "compat shims" or "v2" file clones.
When changing behavior, migrate callers and remove old code.
New files are only for genuinely new domains that don't fit existing modules.
The bar for adding files is very high.

---

## Beads Workflow

This project uses **br** from `beads_rust` for issue tracking, with **bv** (`beads_viewer`) for graph-aware triage. The tracked ledger intentionally contains legacy mixed prefixes, so invoke `br` with `--no-db` to preserve existing IDs.

## Quick Reference

```bash
br --no-db ready                         # Find available work
br --no-db show <id>                     # View issue details
br --no-db update <id> --status in_progress  # Claim work
br --no-db close <id> --reason "Completed"  # Complete work
bv --robot-triage --brief                # Dependency-aware triage
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git add <files> .beads/
   git commit -m "..."
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds


<!-- bv-agent-instructions-v1 -->

---

### Issue Tracking with br (beads_rust)
All issue tracking goes through `br --no-db`. No other TODO systems.

Key invariants:

.beads/ is authoritative state and must always be committed with code changes.
Do not edit .beads/*.jsonl directly; only via `br --no-db`.
The `--no-db` flag is mandatory here: the historical ledger mixes `bd-*` and `book-quote-*` IDs, and rewriting those durable IDs is forbidden.
Basics
Check ready work:

br --no-db ready --json
Create issues:

br --no-db create "Issue title" -t bug|feature|task -p 0-4 --json
br --no-db create "Issue title" -p 1 --deps discovered-from:bd-123 --json
Update:

br --no-db update bd-42 --status in_progress --json
br --no-db update bd-42 --priority 1 --json
Complete:

br --no-db close bd-42 --reason "Completed" --json
Types:

bug, feature, task, epic, chore
Priorities:

0 critical (security, data loss, broken builds)
1 high
2 medium (default)
3 low
4 backlog
Agent workflow:

`br --no-db ready` to find unblocked work.
Claim: `br --no-db update <id> --status in_progress`.
Implement + test.
If you discover new work, create a new bead with discovered-from:<parent-id>.
Close when done.
Commit .beads/ in the same commit as code changes.
Auto-sync:

In JSONL-only mode, `br` writes `.beads/issues.jsonl` directly and atomically.
After `git pull`, run `br --no-db list --json` and `bv --robot-triage --brief` to validate the merged ledger.
Never:

Use markdown TODO lists.
Use other trackers.
Duplicate tracking.
Using bv as an AI sidecar
bv is a graph-aware triage engine for Beads projects (`.beads/issues.jsonl`). Instead of parsing JSONL or hallucinating graph traversal, use robot flags for deterministic, dependency-aware outputs with precomputed metrics (PageRank, betweenness, critical path, cycles, HITS, eigenvector, k-core).

Scope boundary: bv handles what to work on (triage, priority, planning). For agent-to-agent coordination (messaging, work claiming, file reservations), use MCP Agent Mail, which should be available to you as an an MCP server (if it's not, then flag to the user; they might need to start Agent Mail using the am alias or by running `cd "<directory_where_they_installed_agent_mail>/mcp_agent_mail" && bash scripts/run_server_with_token.sh)' if the alias isn't available or isn't working.

⚠️ CRITICAL: Use ONLY --robot-* flags. Bare bv launches an interactive TUI that blocks your session.

The Workflow: Start With Triage
bv --robot-triage is your single entry point. It returns everything you need in one call:

quick_ref: at-a-glance counts + top 3 picks
recommendations: ranked actionable items with scores, reasons, unblock info
quick_wins: low-effort high-impact items
blockers_to_clear: items that unblock the most downstream work
project_health: status/type/priority distributions, graph metrics
commands: copy-paste shell commands for next steps
bv --robot-triage # THE MEGA-COMMAND: start here bv --robot-next # Minimal: just the single top pick + claim command

Other bv Commands
Planning:

Command	Returns
--robot-plan	Parallel execution tracks with unblocks lists
--robot-priority	Priority misalignment detection with confidence
Graph Analysis:

Command	Returns
--robot-insights	Full metrics: PageRank, betweenness, HITS (hubs/authorities), eigenvector, critical path, cycles, k-core, articulation points, slack
--robot-label-health	Per-label health: health_level (healthy|warning|critical), velocity_score, staleness, blocked_count
--robot-label-flow	Cross-label dependency: flow_matrix, dependencies, bottleneck_labels
--robot-label-attention [--attention-limit=N]	Attention-ranked labels by: (pagerank × staleness × block_impact) / velocity
History & Change Tracking:

Command	Returns
--robot-history	Bead-to-commit correlations: stats, histories (per-bead events/commits/milestones), commit_index
--robot-diff --diff-since <ref>	Changes since ref: new/closed/modified issues, cycles introduced/resolved
Other Commands:

Command	Returns
--robot-burndown <sprint>	Sprint burndown, scope changes, at-risk items
--robot-forecast <id|all>	ETA predictions with dependency-aware scheduling
--robot-alerts	Stale issues, blocking cascades, priority mismatches
--robot-suggest	Hygiene: duplicates, missing deps, label suggestions, cycle breaks
--robot-graph [--graph-format=json|dot|mermaid]	Dependency graph export
--export-graph <file.html>	Self-contained interactive HTML visualization
Scoping & Filtering
bv --robot-plan --label backend # Scope to label's subgraph bv --robot-insights --as-of HEAD~30 # Historical point-in-time bv --recipe actionable --robot-plan # Pre-filter: ready to work (no blockers) bv --recipe high-impact --robot-triage # Pre-filter: top PageRank scores bv --robot-triage --robot-triage-by-track # Group by parallel work streams bv --robot-triage --robot-triage-by-label # Group by domain

Understanding Robot Output
All robot JSON includes:

data_hash — Fingerprint of source `.beads/issues.jsonl` (verify consistency across calls)
status — Per-metric state: computed|approx|timeout|skipped + elapsed ms
as_of / as_of_commit — Present when using --as-of; contains ref and resolved SHA
Two-phase analysis:

Phase 1 (instant): degree, topo sort, density — always available immediately
Phase 2 (async, 500ms timeout): PageRank, betweenness, HITS, eigenvector, cycles — check status flags
For large graphs (>500 nodes): Some metrics may be approximated or skipped. Always check status.

jq Quick Reference
bv --robot-triage | jq '.quick_ref' # At-a-glance summary bv --robot-triage | jq '.recommendations[0]' # Top recommendation bv --robot-plan | jq '.plan.summary.highest_impact' # Best unblock target bv --robot-insights | jq '.status' # Check metric readiness bv --robot-insights | jq '.Cycles' # Circular deps (must fix!) bv --robot-label-health | jq '.results.labels[] | select(.health_level == "critical")'

Performance: Phase 1 instant, Phase 2 async (500ms timeout). Prefer --robot-plan over --robot-insights when speed matters. Results cached by data hash.

Use bv instead of parsing `.beads/issues.jsonl`—it computes PageRank, critical paths, cycles, and parallel tracks deterministically.
### Session Protocol

**Before ending any session, run this checklist:**

```bash
git status              # Check what changed
br --no-db list --json  # Validate the authoritative ledger
bv --robot-triage --brief  # Validate graph/triage
git add <files> .beads/ # Stage code and beads changes
git commit -m "..."     # Commit code and beads together
git push                # Push to remote
```

### Best Practices

- Check `br --no-db ready` and `bv --robot-triage --brief` at session start to find available work
- Update status as you work (in_progress → closed)
- Create new issues with `br --no-db create` when you discover tasks
- Use descriptive titles and set appropriate priority/type
- Always validate and commit `.beads/issues.jsonl` before ending a session

<!-- end-bv-agent-instructions -->

### MCP Agent Mail — Multi-Agent Coordination
Agent Mail is available as an MCP server for coordinating work across agents.

CRITICAL: How Agents Access Agent Mail
Coding agents (Claude Code, Codex, Gemini CLI) access Agent Mail NATIVELY via MCP tools.

You do NOT need to implement HTTP wrappers, client classes, or JSON-RPC handling
MCP tools are available directly in your environment (e.g., macro_start_session, send_message, fetch_inbox)
If MCP tools aren't available, flag it to the user — they may need to start the Agent Mail server
The AgentMailClient class in brenner.ts and apps/web/src/lib/agentMail.ts is for:

The brenner CLI tool (for human operators interacting from command line)
The web app (which runs in browser/server and can't use MCP natively)
DO NOT create HTTP wrappers or unify "client code" for agent-to-Agent-Mail communication — this is already handled by your MCP runtime.

What Agent Mail gives:

Identities, inbox/outbox, searchable threads.
Advisory file reservations (leases) to avoid agents clobbering each other.
Persistent artifacts in git (human-auditable).
Core patterns:

Same repo

Register identity:
ensure_project then register_agent with the repo's absolute path as project_key.
Reserve files before editing:
file_reservation_paths(project_key, agent_name, ["src/**"], ttl_seconds=3600, exclusive=true).
Communicate:
send_message(..., thread_id="FEAT-123").
fetch_inbox, then acknowledge_message.
Fast reads:
resource://inbox/{Agent}?project=<abs-path>&limit=20.
resource://thread/{id}?project=<abs-path>&include_bodies=true.
Macros vs granular:

Prefer macros when speed is more important than fine-grained control:
macro_start_session, macro_prepare_thread, macro_file_reservation_cycle, macro_contact_handshake.
Use granular tools when you need explicit behavior.
Common pitfalls:

"from_agent not registered" → call register_agent with correct project_key.
FILE_RESERVATION_CONFLICT → adjust patterns, wait for expiry, or use non-exclusive reservation.

---

### Morph Warp Grep — AI-Powered Code Search
Use mcp__morph-mcp__warp_grep for “how does X work?” discovery across the codebase.

When to use:

You don’t know where something lives.
You want data flow across multiple files (API → service → schema → types).
You want all touchpoints of a cross-cutting concern (e.g., moderation, billing).
Example:

mcp__morph-mcp__warp_grep(
  repoPath: "/data/projects/communitai",
  query: "How is the L3 Guardian appeals system implemented?"
)
Warp Grep:

Expands a natural-language query to multiple search patterns.
Runs targeted greps, reads code, follows imports, then returns concise snippets with line numbers.
Reduces token usage by returning only relevant slices, not entire files.
When not to use Warp Grep:

You already know the function/identifier name; use rg.
You know the exact file; just open it.
You only need a yes/no existence check.
Comparison:

Scenario	Tool
“How is auth session validated?”	warp_grep
“Where is handleSubmit defined?”	rg
“Replace var with let”	ast-grep
cass — Cross-Agent Search
cass indexes prior agent conversations (Claude Code, Codex, Cursor, Gemini, ChatGPT, etc.) so we can reuse solved problems.

Rules:

Never run bare cass (TUI). Always use --robot or --json.
Examples:

cass health
cass search "authentication error" --robot --limit 5
cass view /path/to/session.jsonl -n 42 --json
cass expand /path/to/session.jsonl -n 42 -C 3 --json
cass capabilities --json
cass robot-docs guide
Tips:

Use --fields minimal for lean output.
Filter by agent with --agent.
Use --days N to limit to recent history.
stdout is data-only, stderr is diagnostics; exit code 0 means success.

Treat cass as a way to avoid re-solving problems other agents already handled.

### Memory System: cass-memory
The Cass Memory System (cm) is a tool for giving agents an effective memory based on the ability to quickly search across previous coding agent sessions across an array of different coding agent tools (e.g., Claude Code, Codex, Gemini-CLI, Cursor, etc) and projects (and even across multiple machines, optionally) and then reflect on what they find and learn in new sessions to draw out useful lessons and takeaways; these lessons are then stored and can be queried and retrieved later, much like how human memory works.

The cm onboard command guides you through analyzing historical sessions and extracting valuable rules.

Quick Start
# 1. Check status and see recommendations
cm onboard status

# 2. Get sessions to analyze (filtered by gaps in your playbook)
cm onboard sample --fill-gaps

# 3. Read a session with rich context
cm onboard read /path/to/session.jsonl --template

# 4. Add extracted rules (one at a time or batch)
cm playbook add "Your rule content" --category "debugging"
# Or batch add:
cm playbook add --file rules.json

# 5. Mark session as processed
cm onboard mark-done /path/to/session.jsonl
Before starting complex tasks, retrieve relevant context:

cm context "<task description>" --json
This returns:

relevantBullets: Rules that may help with your task
antiPatterns: Pitfalls to avoid
historySnippets: Past sessions that solved similar problems
suggestedCassQueries: Searches for deeper investigation
Protocol
START: Run cm context "<task>" --json before non-trivial work
WORK: Reference rule IDs when following them (e.g., "Following b-8f3a2c...")
FEEDBACK: Leave inline comments when rules help/hurt:
// [cass: helpful b-xyz] - reason
// [cass: harmful b-xyz] - reason
END: Just finish your work. Learning happens automatically.
Key Flags
Flag	Purpose
--json	Machine-readable JSON output (required!)
--limit N	Cap number of rules returned
--no-history	Skip historical snippets for faster response
stdout = data only, stderr = diagnostics. Exit 0 = success.

UBS Quick Reference for AI Agents
UBS stands for "Ultimate Bug Scanner": The AI Coding Agent's Secret Weapon: Flagging Likely Bugs for Fixing Early On

Golden Rule: ubs <changed-files> before every commit. Exit 0 = safe. Exit >0 = fix & re-run.

Commands:

ubs file.ts file2.py                    # Specific files (< 1s) — USE THIS
ubs $(git diff --name-only --cached)    # Staged files — before commit
ubs --only=js,python src/               # Language filter (3-5x faster)
ubs --ci --fail-on-warning .            # CI mode — before PR
ubs --help                              # Full command reference
ubs sessions --entries 1                # Tail the latest install session log
ubs .                                   # Whole project (ignores things like .venv and node_modules automatically)
Output Format:

⚠️  Category (N errors)
    file.ts:42:5 – Issue description
    💡 Suggested fix
Exit code: 1
Parse: file:line:col → location | 💡 → how to fix | Exit 0/1 → pass/fail

Fix Workflow:

Read finding → category + fix suggestion
Navigate file:line:col → view context
Verify real issue (not false positive)
Fix root cause (not symptom)
Re-run ubs <file> → exit 0
Commit
Speed Critical: Scope to changed files. ubs src/file.ts (< 1s) vs ubs . (30s). Never full scan for small edits.

Bug Severity:

Critical (always fix): Null safety, XSS/injection, async/await, memory leaks
Important (production): Type narrowing, division-by-zero, resource leaks
Contextual (judgment): TODO/FIXME, console logs
Anti-Patterns:

❌ Ignore findings → ✅ Investigate each
❌ Full scan per edit → ✅ Scope to file
❌ Fix symptom (if (x) { x.y }) → ✅ Root cause (x?.y)

## Commit Discipline (Multi-Agent)

When multiple agents share the same working tree, commit discipline prevents confusion.

### Core Rules

1. **Commit frequently, not just at task end**
   - Commit after each logical change (file created, function added, bug fixed)
   - Other agents see progress, not mystery uncommitted files

2. **Pull before editing any file you didn't create**
   ```bash
   git pull --rebase
   ```

3. **All work on main branch**
   - No feature branches, no worktrees
   - Use advisory file reservations via agent-mail to avoid conflicts

4. **Conventional commit format**
   ```
   type(scope): description
   
   [optional body]
   
   Refs: <bead-id>
   ```
   Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

5. **Push immediately after committing**
   - Don't leave commits sitting locally
   - Other agents need to see your changes

### If You See Uncommitted Changes You Didn't Make

- Check `git log` to see recent commits
- Check agent-mail for who's working on what
- Ask before modifying files with uncommitted changes from others

### Commit Prompts

See `command_palette.md` for detailed commit prompts:
- `git_commit` - Detailed multi-file commit
- `git_commit_wip` - Quick WIP checkpoint
- `git_selective_commit` - Group changes by area
- `git_error_checkpoint` - Record lint/type error counts

### Full Git Workflow Guide

For comprehensive multi-agent git patterns, commit agent setup, and troubleshooting:
→ [git-multi-agent-workflow.md](~/clawd/docs/git-multi-agent-workflow.md)
