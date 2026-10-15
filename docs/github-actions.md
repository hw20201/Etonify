# GitHub Actions for Etonify

This repository contains two useful workflows:

- `CI`: runs Flutter dependency restore, localization generation, optional Pigeon generation, analyzer, and tests.
- `Android Release APK`: builds signed Android APKs for `universal`, `arm64-v8a`, `armeabi-v7a`, and `x86_64`, uploads them as workflow artifacts, and creates or updates a draft GitHub Release.

## Required Repository Secrets

Open the repository on GitHub and go to:

`Settings -> Secrets and variables -> Actions -> New repository secret`

Create these secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

## Create a Release Keystore

On Windows:

```powershell
keytool -genkeypair -v `
  -keystore etonify-release.jks `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias etonify
```

Keep this file private. If you lose it, you may not be able to update APKs signed with the same identity.

## Convert Keystore to Base64

On Windows:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("etonify-release.jks")) | Set-Clipboard
```

Paste the clipboard value into `ANDROID_KEYSTORE_BASE64`.

Use the keystore password as `ANDROID_KEYSTORE_PASSWORD`, the alias as `ANDROID_KEY_ALIAS`, and the key password as `ANDROID_KEY_PASSWORD`.

## Build Signed APKs

Manual build:

1. Open `Actions`.
2. Select `Android Release APK`.
3. Click `Run workflow`.
4. Use `build_name` as `0.1.0` or `v0.1.0`; both are normalized.
5. Download APKs from the workflow artifact or from the created draft release.

Release tag build:

```powershell
git tag 0.1.0
git push origin 0.1.0
```

The workflow normalizes release metadata like this:

```text
input:         0.1.0 or v0.1.0
release tag:  0.1.0
release title: v0.1.0
```

The updater inside Etonify expects these release asset names:

```text
etonify-v0.1.0-universal.apk
etonify-v0.1.0-arm64-v8a.apk
etonify-v0.1.0-armeabi-v7a.apk
etonify-v0.1.0-x86_64.apk
```

The app first looks for the APK matching the current device ABI, then falls back to `universal`.
