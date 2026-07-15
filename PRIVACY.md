# BookQuotes Privacy Policy

Last updated: July 2026

## Our Commitment

BookQuotes is designed to keep your reading notes personal. Your library is stored locally on
your device in this release.

## What We Collect

### Account Information

When you sign in with Apple, we receive your Apple-provided identifier and, if Apple shares it,
your email address. We use this information to authenticate requests to the BookQuotes service
and maintain your subscription access state.

### Image Processing

Captured pages and cover images are stored locally on your device while you review, retry, or
save them. When you save a quote, a compressed source-image copy may be kept with that quote for
reference until you delete the quote. Draft and queued images remain on-device until they are
processed or deleted.

If you enable Remote AI Processing, the selected image, extraction instructions, and resulting
text are sent through the BookQuotes service to Hugging Face Inference for quote-page extraction
or Google Gemini for cover extraction. The BookQuotes service does not write those image or
prompt payloads to its application database. Each provider handles request data under its own
terms.

### Book Metadata Lookup

When you look up a book, BookQuotes sends an ISBN, or a book title and author, directly to Google
Books to find metadata and cover images. If an ISBN is not found there, it is sent to Open Library
as a fallback. These catalogue requests do not include your BookQuotes account identifier or
library.

### Service Usage and Subscription Records

To authenticate requests and enforce subscription access, BookQuotes stores your Apple-provided
account identifier, subscription access records, monthly extraction counts, and last-updated
timestamps. Short-lived rate-limit counters may use your account and network information to
protect the service. After account deletion, a session-revocation record may remain for up to
eight days solely to prevent use of already-issued session tokens.

### Your Quotes and Books

Your extracted quotes, book metadata, tags, collections, and locally retained images are stored
on your device. Cloud sync is not enabled in this release.

## What We Do Not Collect

- Analytics or tracking data
- Advertising identifiers
- Location information
- Contact lists or unrelated personal files
- Advertising profiles or behavioural analytics

## Third-Party Services

- **Hugging Face Inference** provides model-assisted quote extraction from marked pages when you
  enable Remote AI Processing.
- **Apple Vision** provides on-device OCR fallback for marked pages.
- **Google Gemini** provides cover metadata extraction when you enable Remote AI Processing.
- **Google Books** provides requested ISBN, title, and author metadata lookups and cover images.
- **Open Library** is used as an ISBN metadata fallback when Google Books has no match.
- **Sign in with Apple** provides secure authentication without a BookQuotes password.
- **Apple StoreKit** provides subscription billing, trial eligibility, renewal status, and
  purchase management.

## Data Security

Network requests use TLS. Your local library is protected by iOS device encryption and data
protection. BookQuotes does not have access to your device-stored library.

## Account Deletion and Your Rights

You can delete your BookQuotes account from **Settings > Account > Delete Account**. This removes
subscription access records and usage data from BookQuotes servers. A session-revocation record
may remain for up to eight days to block existing tokens. Your on-device library remains unless
you delete it yourself. App Store subscriptions are billed by Apple and must be cancelled in
Apple subscription management. Removing the app from your device deletes its local library data.

## Contact

Questions about privacy can be sent to
[acampbell193@googlemail.com](mailto:acampbell193@googlemail.com).
