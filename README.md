# Invee

### Config vars:
`Database__ConnectionString` - Conn string to the db
`Database__Type` - type of db. Currently only supporting `sqlite` and `postgres`
`OpenIDConnectSettings__Authority` - Authority for OIDC, e.g. `https://your-authentik.instance/application/o/invee`
`OpenIDConnectSettings__ClientId` - OIDC client id
`OpenIDConnectSettings__ClientSecret` - OIDC Client secret
`ShortLinks__ShortHost` - Optional short-link host (e.g. `i.your.domain`). Leave empty to disable the short-link feature.
`ShortLinks__CanonicalBaseUrl` - Canonical base URL redirected to (e.g. `https://invee.your.domain`). Required when `ShortLinks__ShortHost` is set.

### Short links

When `ShortLinks__ShortHost` is configured, requests to that host resolve a single-segment slug and issue a `302` redirect to the canonical site:

- `https://i.your.domain/multimeter` &rarr; resolves the slug to an **item** first, then a **storage**, and redirects to `https://invee.your.domain/item/multimeter` (or `/storage/...`).
- Unknown slugs (and the root `/`) redirect to the canonical home page.

Both the short host and the canonical host must be routed to the app by the reverse proxy (the `Host` header is used to select the short-link behavior).

### Mobile deep links

The Flutter app registers the `invee://` custom URL scheme so short-link pages can hand off into the app. On mobile, item/storage pages show an "Open in app" button linking to e.g. `invee://item?slug=<slug>&server=<canonicalBaseUrl>`; the app resolves the slug against the currently configured server (item first, then storage) and opens the matching screen. The app learns the server's short-link config from the `/api/health` response.

Note: this uses a custom scheme rather than verified Android App Links / iOS Universal Links, so it works for any self-hosted domain without hosting verification files, but requires an explicit tap on "Open in app" instead of the OS silently intercepting `https://` links.
