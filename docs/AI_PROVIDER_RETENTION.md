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
| Cover metadata extraction | Google Gemini Developer API | One cover image and the bounded metadata-extraction prompt | The app presents Remote AI Processing consent; no BookQuotes database write is made for the image or prompt payload. |

Quote-page images are processed on-device first. The remote quote route is considered only after
the local extractor returns no candidate or fails, the reader has enabled Remote AI Processing,
and there is an authenticated session.

## Hugging Face Inference Providers

The current quote route is the Hugging Face Inference Providers router, pinned to
`hf-inference`; it is not a Hugging Face Inference Endpoint. The official security and compliance
documentation reviewed on 2026-07-15 states that Hugging Face does not store routed request or
response bodies for training and may retain debugging logs for up to 30 days without user data or
tokens. It also states that an external provider is responsible for its own security policy. The
provider pin avoids dynamic routing, but it does not justify claims about services other than
`hf-inference`.

Source: [Hugging Face Inference Providers security and compliance](https://huggingface.co/docs/inference-providers/en/security).

## Google Gemini Developer API

Gemini currently serves cover metadata extraction only; the retired legacy quote-page Gemini route
returns `410` before it reads an image. Google's Zero Data Retention documentation, reviewed on
2026-07-15, says paid Gemini Developer API services are not used to improve or train Google's
products, but normal paid-service abuse monitoring can log prompts and responses for a limited
period. Project-level approved Zero Data Retention clears user content and identifiable metadata
before logging, subject to the documented feature limitations.

No evidence of Zero Data Retention approval for the BookQuotes Google project is held in this
repository. Do not state or imply zero provider retention for Gemini until the account owner has
recorded that approval and confirmed that the application's selected API features remain eligible.

Source: [Google Gemini API Zero Data Retention](https://ai.google.dev/gemini-api/docs/zdr).

## Release Controls

Before a provider, model provider suffix, or Gemini account configuration is changed:

1. Review the provider's current data-use and retention terms.
2. Update this record and the in-app/App Store privacy disclosures when the change alters data
   handling.
3. Re-run the backend provider-selection tests.
4. Confirm the deployed Worker configuration, not only `wrangler.toml`.

The production deployment review remains open because the deployed Worker predates the current
pinning and atomic-rate-limit configuration, and required App Store Server API secrets have not
yet been provisioned.
