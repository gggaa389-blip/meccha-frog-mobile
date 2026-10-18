# Build the Android APK

This repository is a complete Godot project. The checked-in `.godot/` cache is
intentionally **not** version-controlled, so the first import re-imports all
textures/models and can take a while.

## Requirements

- Godot **4.7.2-stable** editor + the **matching export templates**
  (Editor → Manage Export Templates, or unzip `Godot_v4.7.2-stable_export_templates.tpz`
  into `~/.local/share/godot/export_templates/4.7.2.stable/`).
- **JDK 17** (Temurin recommended). Godot 4 Android builds target JDK 17.
- **Android SDK**: Platform-Tools, Platform 35 and Build-Tools **35.0.1**
  (install with Android Studio or `sdkmanager`).
- A keystore. A debug keystore is enough for `--export-debug`; create a
  release keystore for distribution and **never commit it**:

```bash
keytool -genkeypair -v -keystore release.keystore -alias mecchafrog \
  -keyalg RSA -keysize 2048 -validity 10000
```

## Configure the editor (once)

Editor → Editor Settings → Export → Android:

- Java SDK Path → your JDK 17 directory
- Android SDK Path → your Android SDK directory
- Debug Keystore → a debug keystore (`androiddebugkey` / `android`)

## Export (GUI)

1. Open the project in Godot 4.7.2 and wait for the import to finish.
2. Project → Export → preset **Android** (arm64, `com.mecchafrog.game`,
   immersive landscape, ETC2/ASTC textures already enabled in the project).
3. Put the release keystore/user/password in the preset **locally** (do not
   commit filled keystore fields) or use the environment variables below.
4. Export Project → `build/android/MecchaFrog.apk`.

## Export (headless)

```bash
export JAVA_HOME=/path/to/jdk17
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/path/to/release.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=mecchafrog
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='***'

Godot_v4.7.2-stable_linux.x86_64 --headless --path . --import
mkdir -p build/android
Godot_v4.7.2-stable_linux.x86_64 --headless --path . \
  --export-release "Android" build/android/MecchaFrog.apk

# Verify the result
apksigner verify --verbose --print-certs build/android/MecchaFrog.apk
zipalign -c -v 4 build/android/MecchaFrog.apk
aapt2 dump badging build/android/MecchaFrog.apk | head
sha256sum build/android/MecchaFrog.apk
```

> The export writes a ~600 MB temporary unaligned APK. Keep `TMPDIR` on a
> disk with several GB free, and make sure no stale `tmpexport-unaligned.*.apk`
> is left in a small `/tmp` tmpfs from a previously killed export.

## GitHub Actions

A ready-to-use workflow template is provided at `docs/github-workflow/build-android.yml`. Copy it to `.github/workflows/build-android.yml` in your repository to enable the manual (`workflow_dispatch`) cloud build. (Pushing workflow files with a Personal Access Token requires the token's `workflow` scope.)
For a signed release APK, configure these repository secrets first:

- `ANDROID_KEYSTORE_BASE64` — `base64 -w0 release.keystore`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`

Without the secrets the workflow fails early with an explicit message instead
of silently producing an APK signed with a throwaway key.

## Signing notes

- Updates must be signed with the **same** release keystore and a higher
  `version/code`; otherwise Android refuses the update.
- Keep the keystore file and its password somewhere safe and **outside Git**.
