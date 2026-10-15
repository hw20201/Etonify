# GitHub Actions for Etonify

This repository contains two useful workflows:

- `CI`: runs Flutter dependency restore, localization generation, optional Pigeon generation, analyzer, and tests.
- `Etonify · Android arm64 builds`: builds an arm64 artifact on `master`; a `v*` tag builds a signed arm64 APK and creates or updates a draft GitHub Release. A manual run can do the same for an existing tag by supplying `release_tag`.

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

## Build or Test a Signed APK

Push a version tag such as `v0.3.9` to build a signed arm64 APK and create or update a **draft** Release:

```powershell
git tag v0.3.9
git push origin v0.3.9
```

To test an existing tag without moving it:

1. Open `Actions` and select `Etonify · Android arm64 builds`.
2. Click `Run workflow` on `master`.
3. Enter the existing tag, including the `v` prefix (for example, `v0.3.9`) in `release_tag`.
4. The signed job checks out that tag, builds the arm64 APK, and creates or updates the draft Release. It does not publish the Release.

Leave `release_tag` blank to run only the arm64 artifact build. Tag Release assets use names like `etonify-v0.3.9-arm64-v8a.apk`.
