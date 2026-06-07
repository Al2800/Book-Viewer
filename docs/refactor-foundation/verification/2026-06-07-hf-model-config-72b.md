# Hugging Face 72B Model Configuration Verification

## Trigger

Build 29 still missed vertical margin lines and showed OCR-style broken-line output. The shipped iOS build was model-first, so the likely failure mode was the backend model route failing and the app falling back to local OCR.

## Findings

- Build 29 archive uses app build number `29`.
- `ExtractionReviewView` uses `ModelAssistedQuoteExtractor`.
- `ModelAssistedQuoteExtractor` calls `RemoteModelQuoteExtractor` before `OnDeviceQuoteExtractor`.
- Cloudflare production had `HF_API_TOKEN` configured but did not have `HF_MODEL_ID`.
- Without `HF_MODEL_ID`, the Worker used the code default `Qwen/Qwen2.5-VL-7B-Instruct:preferred`.
- A direct Hugging Face router probe returned that `Qwen/Qwen2.5-VL-7B-Instruct` was not supported by the enabled providers.

## Model Probe

A non-verbatim probe was run against the failing page image to avoid copying book text into logs.

Results:

- `Qwen/Qwen3-VL-8B-Instruct`: did not detect the vertical margin line.
- `Qwen/Qwen3-VL-30B-A3B-Instruct`: did not detect the vertical margin line.
- `Qwen/Qwen3-VL-235B-A22B-Instruct`: did not detect the vertical margin line.
- `Qwen/Qwen2.5-VL-72B-Instruct`: detected both underline and vertical margin-line markings.

Observed 72B usage on the non-verbatim probe:

- prompt tokens: `1046`
- completion tokens: `56`
- total tokens: `1102`

Approximate cost at `$1.01/M input` and `$1.01/M output`:

- about `$0.0011` for the non-verbatim probe;
- likely about `$0.0012-$0.0016` for full quote extraction depending on output length.

## Change

Cloudflare production secret:

```text
HF_MODEL_ID=Qwen/Qwen2.5-VL-72B-Instruct:preferred
```

Backend code default was also updated to:

```text
Qwen/Qwen2.5-VL-72B-Instruct:preferred
```

## Verification

Cloudflare production secret list now includes:

```text
HF_API_TOKEN
HF_MODEL_ID
```

Production health:

```bash
curl -sS https://api.bookquotes.uk/health
```

Result:

```json
{"status":"ok","version":"1.0.0"}
```

## Expected User Impact

No iOS rebuild is required. Build 29 should now reach a supported Hugging Face vision model before falling back to OCR.

The next TestFlight check should retest:

- the vertical margin-line page;
- the bracketed paragraph page;
- hyphenated line-wrap extraction.
