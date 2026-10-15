# Subscription HWID sharing

General settings offers an explicit, default-off **Send HWID to providers** switch.
It applies when making ordinary HTTP(S) subscription requests, including manual
imports and scheduled refreshes; changing the switch does not trigger a refresh.
Per-subscription permissions continue to work when the global switch is off.
Global consent is stored locally and excluded from imported/exported settings.

The common subscription fetcher sends `X-HWID`, `X-Device-Os`, `X-Ver-Os` and
`X-Device-Model` when available, along with the existing User-Agent. On Android,
the identity is the app-scoped Android ID; enabling this switch does not rotate
it. No random ID is generated per request. A custom per-subscription ID still
takes precedence. IDs must match `[a-zA-Z0-9=-]{10,64}`; failure is reported
without logging the ID. Locale and extra hardware details are not added.

No identity headers are added to unrelated geo-resource, OTA or URLTest requests.
Existing HTTPS requirements and cross-origin redirect header stripping remain
unchanged. Explicit custom request headers remain user-controlled. A one-time
import confirmation does not change global consent or create a permanent
per-subscription permission.

Whether a provider displays device names or enforces a device limit depends on
its server-side panel; sending headers cannot guarantee those features. Device
identity is not guaranteed to match another client or survive clearing app data.

Source: [Remnawave HWID device limit](https://docs.rw/features/hwid-device-limit/).
