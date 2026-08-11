# Meta Standard Access support case — BookQuotes

Date prepared: 2026-08-11

## Summary

A read-only Meta Graph API integration returns no Facebook Pages for an app administrator who also has full Facebook control of the target Page. OAuth authorization succeeds and all requested permissions are granted, but `GET /me/accounts` returns an empty data array and a direct Page read returns Graph API error code 100, subcode 33.

No access token, app secret, password, cookie, MFA value, or other credential is included in this report.

## Integration

- Developer app: `BQ Growth Operations`
- App ID: `1413889780602889`
- App status: Unpublished
- Business portfolio connected to app: None
- Facebook Login for Business configuration: `BookQuotes Read Insights`
- Configuration ID: `1399529612240314`
- Login variation: General
- Token type: User access token
- Graph API version: `v26.0`
- Authorizing/app-role identity: `John McNeil`
- Target Facebook Page ID: `61592474937437`
- Expected connected Instagram username: `bookquotes.app`

The unrelated ShiftPro business portfolio is intentionally out of scope and must not be connected to this app or these assets.

## Requested permissions

Only these read-oriented permissions are configured:

- `pages_show_list`
- `pages_read_engagement`
- `instagram_basic`
- `instagram_manage_insights`

The following permissions were not requested:

- `business_management`
- `pages_manage_posts`
- `pages_manage_engagement`
- `pages_messaging`
- `instagram_content_publish`
- `instagram_manage_messages`
- `instagram_manage_comments`
- `ads_management`

## Verified prerequisites

1. A freshly generated user token returns the expected identity from `GET /me?fields=id,name`: `John McNeil`.
2. `GET /me/permissions` reports all four requested permissions as `granted`; Facebook's implicit `public_profile` permission is also granted.
3. Facebook Settings → Business integrations lists `BQ Growth Operations` as the sole active business integration.
4. Its four permission toggles are enabled:
   - Access profile and posts from the selected Instagram account
   - Access insights for the Instagram account
   - Read content posted on the Page
   - Show a list of the Pages you manage
5. Meta for Developers → App roles lists `John McNeil` as the app's sole `Administrator`.
6. The Page owner reports that `John McNeil` has full Facebook control of the BookQuotes Page.
7. A second authorization generated a fresh token, but produced the same API behavior.
8. The configuration UI states:
   - Standard Access permissions are requested only from people with roles on the app.
   - Assets cannot be selected because the configuration uses a user access token.

## Reproduction

Using Graph API Explorer for app `1413889780602889`, configuration `1399529612240314`, and a freshly generated user token:

### Identity

```http
GET /v26.0/me?fields=id,name
```

Observed: succeeds and identifies `John McNeil`.

### Permission status

```http
GET /v26.0/me/permissions
```

Observed: all requested permissions are `granted`.

### Page enumeration

```http
GET /v26.0/me/accounts?fields=id,name,tasks,instagram_business_account{id,username,name,account_type}
```

Observed:

```json
{
  "data": []
}
```

### Direct Page read

```http
GET /v26.0/61592474937437?fields=id,name,category,instagram_business_account{id,username,name}
```

Observed: Graph API error code `100`, subcode `33`, beginning `Unsupported get request`.

## Expected behavior

Because the authorizing identity is both an app administrator and reportedly has full Facebook control of the target Page, `GET /me/accounts` should return the BookQuotes Page and its assigned tasks. Once the Page is returned, its `instagram_business_account` field should identify the connected professional Instagram account.

## Questions for Meta support

1. Why does `/me/accounts` return an empty list when the user is an app administrator, the four permissions are granted, and the user has full Facebook Page control?
2. Is there an additional Page-side assignment or Standard Access requirement for Facebook Login for Business on Graph API `v26.0`?
3. Does the Page need to belong to a business portfolio even for an app-role user performing unpublished Standard Access testing with a user token?
4. If a business portfolio is required, can Meta confirm the least-privilege supported token/configuration type for read-only access to Page identity and Instagram professional-account insights?
5. Is this behavior caused by a known synchronization or New Pages Experience issue, and is there a diagnostic endpoint that can confirm the Page task mapping without exposing token values?

## Safety and scope

- No write, publishing, messaging, moderation, advertising, billing, or campaign action was attempted.
- No broader permissions should be added merely to troubleshoot Page visibility.
- Do not connect or use the unrelated ShiftPro business portfolio.
- Credentials must be supplied only through Meta's secure support tooling and must never be added to this document.
