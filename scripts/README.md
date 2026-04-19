# Build scripts

| Script | Purpose |
|---|---|
| `build_release_android.sh` | Clean, analyze, test, and build a signed AAB. |

## First-time release setup

1. Generate an upload keystore (one-off per project):

   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (NOT committed):

   ```
   storePassword=<your_pw>
   keyPassword=<your_pw>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

3. Wire the signing config inside `android/app/build.gradle` — the standard
   Flutter release-signing recipe applies here. See
   https://docs.flutter.dev/deployment/android#signing-the-app.

4. Run `bash scripts/build_release_android.sh`.

## Compile-time flags

Configured via `--dart-define`:

| Flag | Effect |
|---|---|
| `FLAVOR=debug|qa|release` | Changes `Env.flavor`, gates logs/cheats. |
| `ENABLE_ADS=true|false` | Turns on real rewarded ads integration. |
| `ENABLE_ANALYTICS=true|false` | Forwards events to the real analytics SDK. |
| `ENABLE_REMOTE_CONFIG=true|false` | Uses Firebase RemoteConfig vs hardcoded defaults. |
| `DEBUG_TOOLS=true|false` | Surfaces the `/debug` screen + FPS overlay. |
