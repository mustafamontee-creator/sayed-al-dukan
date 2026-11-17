# Android release signing

The app release keystore is kept outside GitHub in the owner's private ChatGPT Library:
`/Sayed Al-Dukan/Signing/sayed-al-dukan-release.p12`

Never commit the keystore or its password to this repository.

## One-time GitHub Actions setup

In GitHub, open the repository settings, then **Secrets and variables → Actions**, and add these repository secrets:

- `ANDROID_KEYSTORE_BASE64`: base64 encoding of the complete `.p12` file (no line breaks).
- `ANDROID_KEYSTORE_PASSWORD`: the keystore password.

The key alias is fixed as `sayed-al-dukan-release`. The key password defaults to the keystore password.

To produce the base64 value on a computer with the keystore file:
- macOS/Linux: `base64 < sayed-al-dukan-release.p12 | tr -d '\n'`
- Windows PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("sayed-al-dukan-release.p12"))`

Do not paste either password or the base64 private-key value into chat, issues, commits, or source files.

## Build

After the two Actions secrets are saved, run **Actions → Build Android APK → Run workflow** on `feature/pro-ui-refresh`, or push a release commit to `main`.

The workflow runs Flutter analysis and tests before building the signed APK artifact. If the signing secrets are absent, the release build must not proceed.

## Current app version

- Version name: `1.0.2`
- Version code: `3`

Keep the same keystore and alias for every future Android release. Do not regenerate the key.
