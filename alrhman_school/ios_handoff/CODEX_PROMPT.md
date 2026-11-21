# برومبت Codex: بناء تطبيق الآيفون

> **لصاحب الماك:** انسخ كل اللي تحت الخط وانطيه لـ Codex كرسالة أولى. شغّل Codex داخل مجلد الريبو (`dash_and_appphone`).
> البرومبت بالإنگليزي حتى Codex يفهمه بدقة، بس هو راح يحچي وياك بالعربي.

---

You are working on a Mac to build, test and ship the **iOS version of an existing Flutter app**. The code is already prepared for iOS. Your job is to build it, fix only what blocks the build, help the human test it on a real iPhone, produce a signed App Store build, and upload it **only after the human says yes**.

**Talk to the human in Arabic (Iraqi dialect is fine).** Keep messages short. When you need the human to do something in a GUI (Xcode, a website, the iPhone), give numbered click-by-click steps.

## 1. Project facts (do not change any of these)

| Item | Value |
|---|---|
| Repository | `https://github.com/murtadhacs/dash_and_appphone` |
| Branch | `ios-release` (work only here) |
| Flutter app folder | `alrhman_school/` (run every Flutter command from here) |
| Other folder | `alrhman_dashboard/` is a separate web dashboard. **Do not touch it.** |
| App display name | `الرحمن الابتدائية` (Arabic, RTL UI) |
| Bundle ID | `me.yisawi.futurekids.alrahman` (same as Android) |
| Version | `1.0.8+9` in `pubspec.yaml` |
| iOS minimum | 15.0 (required by the Firebase iOS SDK) |
| Devices | iPhone only (`TARGETED_DEVICE_FAMILY = 1`) |
| Flutter | 3.44.x stable or newer (Dart SDK constraint `^3.12.2`) |
| iOS plugin integration | Swift Package Manager (`FlutterGeneratedPluginSwiftPackage` in the Xcode project). CocoaPods only if Flutter falls back to it. |
| Backend URL | Compiled in as the default of `API_BASE_URL` in `lib/api/api_client.dart` = `https://alrahmanschool.up.railway.app` (production). **Do not pass `--dart-define`.** |
| Push | Firebase Cloud Messaging via APNs. Firebase project: `future-kids-attendance`. |
| Login | Parent phone number + PIN. Accounts are created by the school, not in the app. |

Already done in the code (verify, don't redo):
- `ios/Runner/Runner.entitlements` with `aps-environment`, referenced by `CODE_SIGN_ENTITLEMENTS` in all three Runner build configurations.
- `Info.plist`: `UIBackgroundModes = [remote-notification]`, `ITSAppUsesNonExemptEncryption = false`, `CFBundleLocalizations = [ar]`.
- `AppDelegate.swift` sets `UNUserNotificationCenter.current().delegate`, and has a method channel `alrhman/notification-permission` used by Dart.
- `lib/main.dart` initializes Firebase on Android and iOS inside try/catch. `lib/services/push_device.dart` waits for the APNs token before calling `FirebaseMessaging.getToken()` on iOS.
- App icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` have **no alpha channel** (App Store requirement).
- The Xcode project already references `ios/Runner/GoogleService-Info.plist` in the Runner group and the Copy Bundle Resources phase. **The file itself is not in git** (it is gitignored on purpose). The human must put it there.
- `alrhman_school/IOS_BUILD.md` has the short manual version of these steps.

## 2. Hard rules

1. **Never commit to `main` and never push `main`.** Pushing `main` auto-deploys the production dashboard on Railway.
2. Commit only on `ios-release`, only for changes you really needed (for example `DEVELOPMENT_TEAM`, a build fix, a build number bump). Show the diff and **ask before every `git push`**. End commit messages with a line saying it was made with Codex.
3. **Never commit** `GoogleService-Info.plist`, `google-services.json`, `.p8` keys, certificates, provisioning profiles, passwords or tokens.
4. Do not change: the Bundle ID, the app name, the version name, the iOS minimum (never lower it), iPhone-only, the plist reference in the Xcode project, the icons (never add alpha).
5. Do not regenerate the iOS folder (`flutter create`), and do not rewrite Dart business logic. Android must keep working: anything you touch under `lib/` must stay correct for Android too.
6. **Do not handle Apple credentials.** You never type an Apple ID, password or 2FA code. The human signs into Xcode themselves.
7. **Do not upload to App Store Connect** until the human explicitly answers yes to "ارفع النسخة هسه؟".
8. If your sandbox blocks a command that needs the network, the keychain, or a connected iPhone, ask the human to approve it. Don't look for a workaround.
9. If something fails twice the same way, stop and explain it to the human with the exact error text.

## 3. Steps

### Step 0: Check the Mac
Run and report:
```bash
sw_vers
xcodebuild -version
flutter --version
flutter doctor -v
git --version
```

**What must be there:**
- **Xcode 26 or newer**, because App Store uploads must be built with the current iOS SDK.
- **Flutter 3.44 or newer.**
- `flutter doctor` showing **no iOS toolchain errors**.

**If something is missing,** tell the human exactly what to install:
- Xcode: from the Mac App Store, then open it once and accept the license.
- If needed, run `sudo xcode-select -s /Applications/Xcode.app` and `sudo xcodebuild -runFirstLaunch`.
- Flutter: from flutter.dev.

### Step 1: Get the code
If the repo is not cloned yet:
```bash
git clone -b ios-release https://github.com/murtadhacs/dash_and_appphone.git
cd dash_and_appphone/alrhman_school
```

If it is already cloned:
```bash
git fetch origin
git switch ios-release
git pull --ff-only
```

Confirm with `git branch --show-current` that you are on `ios-release`.

### Step 2: Check the Firebase file
```bash
ls -l ios/Runner/GoogleService-Info.plist
/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist
/usr/libexec/PlistBuddy -c "Print :PROJECT_ID" ios/Runner/GoogleService-Info.plist
```

**The checks:**
- `BUNDLE_ID` must be exactly `me.yisawi.futurekids.alrahman`.
- `PROJECT_ID` must be `future-kids-attendance`.

**If they fail:**
- **The file is missing, or the Bundle ID is wrong:** stop. Tell the human to download it from Firebase Console: project `future-kids-attendance` → Project settings → the iOS app with that Bundle ID. If no iOS app exists there yet, they create one with that Bundle ID first. Then they put the file at `alrhman_school/ios/Runner/GoogleService-Info.plist`.
- **`git status` lists the file:** stop. It must stay ignored.

### Step 3: Dart checks
```bash
flutter pub get
flutter analyze
flutter test
```
Expected: analyze reports no issues, and all tests pass (55 passed on Windows on 2026-11-21). Fix only real breakages.

### Step 4: Signing team
1. Ask the human:
   - to confirm their Apple account is added in **Xcode → Settings → Accounts**;
   - for the **Team ID** (developer.apple.com/account → Membership details, 10 characters).
2. Generate the Xcode config:
   ```bash
   flutter build ios --config-only --release
   ```
3. Set the team. **Preferred:** the human opens `ios/Runner.xcworkspace` → target **Runner** → **Signing & Capabilities**, ticks **Automatically manage signing**, and picks the team.

   **If the human can't,** set `DEVELOPMENT_TEAM = <TEAM_ID>;` in the three Runner target configurations of `ios/Runner.xcodeproj/project.pbxproj` yourself. Those are the blocks that contain `PRODUCT_BUNDLE_IDENTIFIER = me.yisawi.futurekids.alrahman;`. Keep `CODE_SIGN_STYLE` automatic.
4. Verify:
   ```bash
   xcodebuild -showBuildSettings -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
     | grep -E " (DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER|CODE_SIGN_ENTITLEMENTS|CODE_SIGN_STYLE|IPHONEOS_DEPLOYMENT_TARGET|TARGETED_DEVICE_FAMILY) ="
   ```
   Expect: the team ID, `me.yisawi.futurekids.alrahman`, `Runner/Runner.entitlements`, `Automatic`, `15.0`, `1`.
5. In **Signing & Capabilities** you should see **Push Notifications** and **Background Modes → Remote notifications**. If Xcode shows a signing error about push, the human must enable **Push Notifications** on the App ID at developer.apple.com → Identifiers.

### Step 5: Compile without signing
```bash
flutter build ios --release --no-codesign
```
Fix compile errors using the troubleshooting list in section 4.

### Step 6: Test on a real iPhone
1. Ask the human to:
   - connect the iPhone with a cable, unlock it, and tap **Trust**;
   - enable **Settings → Privacy & Security → Developer Mode** (the phone restarts).
2. Find the device with `flutter devices`.
3. Run `flutter run -d <device-id>`. Use debug first so logs are visible.
   - If signing fails with a provisioning error, ask the human to press **Run** once in Xcode with the iPhone selected. That lets Xcode register the device and create the profile. Then retry.
4. Watch the logs:
   - If you see `Firebase unavailable`, the plist is not bundled. Recheck step 2.
   - Report any `APNS` or `messaging` errors.
5. Give the human this checklist (in Arabic) and wait for the answers:
   - Login with phone + PIN works, and the children's data shows.
   - The app asks for notification permission, and the human taps Allow.
   - **App open:** a real school notification (arrival or departure, or one sent from the dashboard) appears as a banner.
   - **App closed or in background:** the same kind of notification appears on the lock screen.
   - Settings → privacy policy link opens `https://alrahman.up.railway.app/privacy.html`.
   - Logout works.
   - The layout is right-to-left and readable, with nothing cut off on a small iPhone.
6. **If notifications arrive only while the app is open,** the backend is probably sending data-only FCM messages. iOS needs a `notification` block (title + body). This is server-side and not in this repo. Tell the human to report it to whoever runs the backend; do not change the app for it.
7. **If no notification arrives at all,** ask the human to check two things in Firebase Console → Project settings → Cloud Messaging → Apple app configuration:
   - that an **APNs Authentication Key** (`.p8`, with its Key ID and Team ID) is uploaded for this iOS app;
   - that the user is logged in, so the device token got registered.

### Step 7: Release build
1. Each upload needs a build number App Store Connect has not seen for this version. The first upload is `1.0.8 (9)`. If App Store Connect rejects it as a duplicate, bump only the build number in `pubspec.yaml` (for example `1.0.8+10`). Tell the human this also changes the next Android build number.
2. Build:
   ```bash
   flutter build ipa --release
   ```
   Output: `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/*.ipa`.
3. **If the export step fails on signing,** create `build/ios/ExportOptions.plist` with:
   - `method` = `app-store-connect`
   - `teamID` = the team ID
   - `signingStyle` = `automatic`
   - `destination` = `export`

   Then run:
   ```bash
   xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive \
     -exportOptionsPlist build/ios/ExportOptions.plist -exportPath build/ios/ipa -allowProvisioningUpdates
   ```
4. Verify the IPA before upload:
   ```bash
   cd build/ios/ipa && rm -rf _check && mkdir _check && unzip -q *.ipa -d _check
   /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" _check/Payload/Runner.app/Info.plist
   /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" _check/Payload/Runner.app/Info.plist
   /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" _check/Payload/Runner.app/Info.plist
   ls _check/Payload/Runner.app/GoogleService-Info.plist
   codesign -d --entitlements :- _check/Payload/Runner.app | grep -A1 aps-environment
   rm -rf _check
   ```
   Expect:
   - the Bundle ID `me.yisawi.futurekids.alrahman`;
   - version `1.0.8` and the build number;
   - the plist present;
   - `aps-environment` = `production`.

### Step 8: Upload (only after the human says yes)
1. **Before uploading,** confirm with the human that the app record exists in App Store Connect: Apps → **+** → New App, with Bundle ID `me.yisawi.futurekids.alrahman`. Then ask: **"ارفع النسخة هسه؟"**
2. **Preferred upload route (human, GUI):**
   1. `open build/ios/archive/Runner.xcarchive`
   2. Xcode Organizer → **Distribute App** → **App Store Connect** → **Upload** → keep the defaults.
3. **CLI alternative:** use the same ExportOptions with `destination` = `upload`, then run:
   ```bash
   xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive \
     -exportOptionsPlist build/ios/ExportOptions.plist -exportPath build/ios/upload -allowProvisioningUpdates
   ```
4. Tell the human:
   - processing takes about 15–30 minutes;
   - the build then appears under App Store Connect → the app → **TestFlight**;
   - encryption export compliance is already answered by `ITSAppUsesNonExemptEncryption = false`;
   - if Apple emails a warning (ITMS-xxxxx), they should paste it to you.

### Step 9: Final report (in Arabic)
Tell the human:
- what passed (analyze, tests, device test results);
- the uploaded version and build number;
- every file you changed, and whether it was committed or pushed;
- anything still open (for example the backend notification payload).

## 4. Troubleshooting

| Error | Fix |
|---|---|
| `Build input file cannot be found: .../GoogleService-Info.plist` | The plist is missing. Go to step 2. Do not remove the reference from the project. |
| `Signing for "Runner" requires a development team` | Step 4. |
| `No Account for Team` / `No signing certificate` | The human must sign into Xcode → Settings → Accounts with the Apple account that is on the team. Then retry with `-allowProvisioningUpdates`, or use the Xcode Organizer route. |
| Provisioning profile lacks `aps-environment` / Push Notifications | The human enables Push Notifications on the App ID (developer.apple.com → Identifiers → the Bundle ID). Then retry with automatic signing. |
| Swift error on `UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate` | Change it to `self as? UNUserNotificationCenterDelegate` (the form in the flutter_local_notifications README). |
| Swift package resolution fails | Run `flutter clean && flutter pub get`, then Xcode → File → Packages → Reset Package Caches, then rebuild. |
| Flutter falls back to CocoaPods / `pod` not found | `brew install cocoapods` (or `sudo gem install cocoapods`), then `flutter pub get` and rebuild. The generated `ios/Podfile` and `Podfile.lock` may be committed on `ios-release`. Their platform must be iOS 15. |
| `Minimum deployment target` error from a Firebase package | Keep 15.0 everywhere. Never lower it. If a generated Podfile says a lower platform, set `platform :ios, '15.0'`. |
| Upload says the build number already exists | Bump the build number after `+` in `pubspec.yaml` and rebuild (step 7). |
| Upload rejects the icon for transparency / alpha | Flatten all PNGs in `AppIcon.appiconset` onto an opaque background, without changing their look. |
| ITMS-90683 missing `NS...UsageDescription` | Report the exact key to the human. Add a short Arabic purpose string only for the key Apple names. |
| Notifications only arrive when the app is open | Backend payload issue (see step 6.6). Not an app bug. |
