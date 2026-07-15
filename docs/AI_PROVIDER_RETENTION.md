# AI Provider Retention Record

Last reviewed: 2026-07-15

This record covers the remote AI services currently reachable from the BookQuotes Worker. It is
an evidence record, not a substitute for the providers' terms or a confirmation of account-level
settings. The in-app Privacy Policy intentionally avoids promises about provider retention beyond
this evidence.

## Active Routes

| Feature | Provider route | Data sent after consent | Enforced control |
| --- | --- | --- | --- |
| Quote-page extraction | Hugging Face Inference Providers router with the `hf-inference` provider | One prepared page image and the bounded quote-extraction prompt | `HF_MODEL_ID` must include the approved `:hf-inference` suffix. Dynamic provider suffixes are rejected before image parsing or forwarding. |

For a reader with current consent, an authenticated session, and an eligible subscription, the
remote quote route is attempted first. Apple Vision OCR is the fallback when remote processing is
disabled, unavailable, rate-limited, or returns no quote candidates.

## Hugging Face Inference Providers

The current quote route is the Hugging Face Inference Providers router, pinned to
`hf-inference`; it is not a Hugging Face Inference Endpoint. The official security and compliance
documentation reviewed on 2026-07-15 states that Hugging Face does not store routed request or
response bodies for training and may retain debugging logs for up to 30 days without user data or
tokens. It also states that an external provider is responsible for its own security policy. The
provider pin avoids dynamic routing, but it does not justify claims about services other than
`hf-inference`.

Source: [Hugging Face Inference Providers security and compliance](https://huggingface.co/docs/inference-providers/en/security).

## Retired Cover Route

Book registration no longer sends cover photos to an AI provider. `/api/extract-cover` and the
legacy Gemini quote route return `410` before image parsing or forwarding. Books are registered by
ISBN catalogue lookup or manual entry.

## Release Controls

Before a provider or model provider suffix is changed:

1. Review the provider's current data-use and retention terms.
2. Update this record and the in-app/App Store privacy disclosures when the change alters data
   handling.
3. Re-run the backend provider-selection tests.
4. Confirm the deployed Worker configuration, not only `wrangler.toml`.

The production Worker must keep the approved Hugging Face model pin, atomic rate limits, session
revision checks, and App Store Server API secrets verified before each release.
