# BookQuotes Content Bank Runbook

## Purpose

`ContentBank.json` is the editable, source-controlled 14-day primary content bank for BookQuotes. It covers 19 August–1 September 2026, with one primary record per day:

- 8 discovery/recommendation tools;
- 4 reader-practice/discussion prompts;
- 2 BookQuotes product-proof records;
- product-led share: 2/14 = 14.3%, below the 20% ceiling.

The current records are drafts. They are prepared for review, not silently authorized for publication.

## Files

- `Marketing/Social/CommunityPush/ContentBank.json` — authoritative editable bank.
- `Marketing/Social/CommunityPush/ContentBank.md` — deterministic generated review view; never edit by hand.
- `Marketing/Social/CommunityPush/assets/content-bank/` — 14 original 1080×1920 PNG masters.
- `scripts/content_bank.py` — strict validator, safe Markdown renderer, asset probe, approval hash builder, baseline guard, and CLI.
- `tests/test_content_bank.py` — validator, rendering, security, hashing, ordering, and baseline regressions.

## Normal validation

Run from the repository root:

```bash
python3 scripts/content_bank.py validate \
  Marketing/Social/CommunityPush/ContentBank.json

python3 scripts/content_bank.py render \
  Marketing/Social/CommunityPush/ContentBank.json \
  --output Marketing/Social/CommunityPush/ContentBank.md

python3 -m unittest -v tests.test_content_bank
```

Rendering happens only after validation. The renderer sorts by date and ID, sources/assets by ID, uses a fixed channel order, and has no clock dependency. Re-running it must produce identical bytes.

For a candidate that follows an approved bank already in Git:

```bash
python3 scripts/content_bank.py validate \
  Marketing/Social/CommunityPush/ContentBank.json \
  --baseline-ref origin/main
```

An approved item ID may not be changed or deleted. Make a new revision/item ID instead. The baseline check protects the JSON record; current asset bytes and exact channel captions are additionally checked against their stored hashes.

## Approval workflow

1. Keep the item `draft` or `in_review` while creative, rights, claim, and queue work is incomplete. These states require `approval.record: null`; hashes must not be stored early.
2. Confirm the final asset is the exact file in the bank, not an export variant. For 9:16 assets, review on a phone at normal size and muted. The validator also measures non-background PNG pixels: current originals must remain within x=140..940 and y=170..1500. The current masters use those bounds and keep essential content clear of the conservative lower caption/control zone.
3. Confirm `rights.status: verified`, a non-empty original-rights basis, `safe_area.status: passed`, and `readability.status: passed` with evidence.
4. Reconcile the native scheduled and published queues for the previous 30 days. The local validator catches normalized duplicate hooks/captions, reused asset bytes, and reused assets across different records; it cannot prove native platform state without a platform adapter. Record the native queue check in the review/approval evidence.
5. Confirm every factual product claim against the audited App Store lookup source `S1`. Editorial prompts use `S0` and must not be described as empirical recall, retention, or performance findings.
6. Approve only after native queue reconciliation:

```bash
python3 scripts/content_bank.py approve \
  Marketing/Social/CommunityPush/ContentBank.json \
  bq14-01 \
  --approved-by owner-id \
  --approved-at 2026-08-11T17:00:00+01:00 \
  --native-queue-confirmed
```

The command refuses unknown IDs, already-approved IDs, unverified rights, pending visual checks, or missing queue confirmation. It computes:

- `content_sha256` from canonical item JSON excluding `approval`;
- `asset_sha256` from the exact final asset bytes;
- `caption_sha256` from each exact UTF-8 channel caption;
- `native_queue_confirmed: true`, recording the explicit queue reconciliation gate.

It revalidates the complete bank before writing. Approval is a source change and must be reviewed, committed, and pushed with the corresponding generated Markdown.

## Rights and claims rules

Allowed sources are intentionally narrow:

- `S0`: original BookQuotes editorial method/prompt; not evidence of a measured outcome.
- `S1`: public Apple lookup for App Store ID `6758091579`, checked 11 August 2026.

The 14 current masters are original typography only. They contain no third-party cover art, book-page photography, reproduced quotations, audio, personal data, retailer images, or borrowed creator wording.

The two product-proof records use only claims supported by `S1`:

- collections and tags;
- Markdown, plain text, JSON, Obsidian, and Notion export.

The generated assets are explanatory typography cards rather than fabricated product screenshots. A future UI capture must use synthetic titles/placeholders and receive a separate rights/readability review.

## Channel and platform gates

- Facebook’s existing verified queue runs through 18 August; this bank starts 19 August to avoid replacement or accidental duplication.
- Instagram publication/analytics remain blocked while its Meta Business connection is unresolved.
- TikTok publication remains manual-approval-gated while account-health/distribution and attributable analytics are unresolved.
- Do not claim App Store campaign attribution until a channel-specific link has been generated and read back from the authoritative platform.
- Do not use inaccessible analytics as zero. Record unavailable outcomes as unavailable/null in the growth evidence system.

## Duplicate-risk notes

- `bq14-07` is a question-construction method, not another “three passages for book club” post.
- `bq14-11` is paraphrase plus context, not another one-line/highlight-revisit execution.
- `bq14-13` is collections/tags organization, not another searchable-library or “find the line” execution.
- `bq14-14` is one export capability explanation, not a repeated launch feature list.
- Reconcile the actual native queue immediately before scheduling; repository plans alone do not prove platform state.

## Change discipline

- Edit JSON, not generated Markdown.
- Run validation, rendering, tests, and a clean-candidate check before commit.
- Never hand-edit or silently rehash an approved item.
- If an approved asset, caption, claim, CTA, or channel adaptation changes, create a new item/revision ID and obtain a new approval.
- Keep unrelated concurrent Markdown changes out of content-bank commits.
