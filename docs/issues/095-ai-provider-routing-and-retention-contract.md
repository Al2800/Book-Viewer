# 095 - Make AI provider routing and retention claims enforceable

Status: in_progress
Area: Backend / AI Providers / Privacy
Priority: critical (release blocker 7)

## Problem

The Hugging Face model uses `:preferred`, which may route requests to external inference providers with separate policies. The privacy policy nevertheless promises that images are not retained. Gemini may retain prompts for abuse monitoring unless the account has zero-data-retention approval.

## Acceptance Criteria

- [x] Production routing uses an explicitly approved provider or an allowlist with reviewed terms.
- [x] Provider identity is documented and enforced operationally.
- [x] Retention claims do not exceed the contractual guarantees of every active provider.
- [x] Provider changes require a privacy review before deployment.
- [x] A no-remote-processing mode remains available.

## Verification

- [x] Backend tests for provider selection and rejected providers.
- [ ] Deployment configuration review.
- [ ] Recorded evidence of provider retention terms or ZDR approval.

## Implementation Notes

Quote-page extraction defaults to the explicitly routed `hf-inference` provider and rejects
dynamic-routing suffixes such as `:preferred`, `:fastest`, and `:cheapest` before image parsing
or forwarding. The Worker allowlist is the deployment control point; changing it requires a
privacy and retention review. The user-facing policy no longer makes provider-retention claims
outside BookQuotes' control, and remote processing remains an explicit, revocable choice.

This remains open until production deployment is confirmed with a supported `hf-inference` model
route and the applicable provider terms (including Google Gemini's retention configuration) are
recorded by the account owner.
