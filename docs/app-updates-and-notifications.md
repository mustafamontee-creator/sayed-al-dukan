# App updates and push notifications

## Client behaviour

- Android clients subscribe to the Firebase Cloud Messaging topic `app_updates`.
- FCM notification messages are shown by Android while the app is in the background.
- While the app is open, the app displays a local notification on the `app_updates` channel.
- Tapping an update notification opens the app and checks `app-update.json`.
- Settings > Check for updates reads the same manifest and compares `version_code` with the installed Android build number.
- The APK download link must point to a signed APK with the same Android application ID and the same release signing certificate as the installed app.

## Publishing a new APK

1. Update `version:` in `pubspec.yaml` (for example, `1.0.14+15`).
2. Update `app-update.json` with the matching `version_name`, integer `version_code`, title and release notes.
3. Set `apk_url` to `https://github.com/mustafamontee-creator/sayed-al-dukan/releases/latest/download/app-release.apk`.
4. Commit the changes, then create and push a matching version tag such as `v1.0.14` on that commit.
5. The Build Android APK workflow builds the signed APK and attaches it to the GitHub Release. Confirm the release asset exists before announcing the update.

## Sending an update notification

Use Firebase Console > Messaging to send a notification to the topic `app_updates`.

The notification must include:
- Notification title: `يتوفر تحديث جديد لسيد الدكان`
- Notification body: a short release summary
- Custom data key `type` with value `app_update`

Use the same title/body in Arabic or English as appropriate. Send only after the release asset and matching `app-update.json` are live.

## Important limitations

- Only installed versions that already contain Firebase Messaging and subscribe to `app_updates` receive topic notifications. Versions older than that cannot be reached retroactively.
- Android notification permission must be allowed by the user; device power/network settings can also delay delivery.
- This repository does not contain a Firebase Admin service-account credential or an automated push sender. Sending is intentionally performed through the Firebase Console; never add a service-account private key to the app or repository.
- The app cannot silently install an APK. Android controls the package installer confirmation.
