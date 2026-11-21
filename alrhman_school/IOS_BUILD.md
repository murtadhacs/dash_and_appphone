# بناء تطبيق ولي الأمر للآيفون ورفعه على App Store

دليل لصاحب الماك. كل الأوامر تنكتب داخل مجلد `alrhman_school`.

## ١. المطلوب على الماك

- **Xcode**: آخر نسخة من الـ App Store. بعد التنصيب يفتحه مرة وحدة ويوافق على الشروط.
- **Flutter**: نسخة 3.44 (stable). يتأكد بـ `flutter --version` و `flutter doctor`.
- **حساب Apple**: مضاف لفريق حساب المطوّر بصلاحية Admin أو App Manager، ومفعّل عليه الوصول للشهادات. يضيفه من Xcode ← Settings ← Accounts.

ملاحظة: المشروع يستخدم Swift Package Manager، فغالباً ما يحتاج CocoaPods. إذا Flutter طلبه، ينصّبه بـ `brew install cocoapods`.

## ٢. قبل أول بناء (مرة وحدة)

1. **ملف Firebase**: من Firebase Console، مشروع `future-kids-attendance`، يضيف تطبيق iOS بنفس الـ Bundle ID، وينزّل `GoogleService-Info.plist`، ويحطه داخل `ios/Runner/`. بدون هذا الملف البناء يفشل. الملف مستثنى من git عمداً، فلازم يوصله بشكل منفصل.
2. **مفتاح الإشعارات (APNs)**: يرفع ملف الـ `.p8` على Firebase من Project settings ← Cloud Messaging ← Apple app configuration، ويكتب وياه الـ Key ID والـ Team ID.
3. **صفحة التطبيق بالمتجر**: من App Store Connect ← Apps ← زر + ← New App. يختار المنصة iOS، واللغة الأساسية Arabic، والـ Bundle ID، ويكتب SKU (مثلاً `alrahman-parent`).

**الـ Bundle ID:** `me.yisawi.futurekids.alrahman`، نفس معرّف الأندرويد. هذا المعرّف يُستخدم بـ Firebase وبـ App Store Connect، وبعد أول رفع ما يتغير.

## ٣. فتح المشروع والتوقيع

```bash
flutter pub get
open ios/Runner.xcworkspace
```

بـ Xcode يروح على Runner (الـ target) ← **Signing & Capabilities**:
- يأشّر على **Automatically manage signing**.
- يختار **Team** حساب المطوّر.
- لازم تطلع **Push Notifications** و **Background Modes ← Remote notifications**، لأنهن مضافات بالمشروع.

## ٤. التجربة على آيفون حقيقي

يربط الآيفون بالكيبل، ويفعّل Developer Mode على الآيفون، وبعدين:

```bash
flutter run --release
```

**شنو يجرّب:**
- [ ] تسجيل الدخول
- [ ] يقبل الإشعارات، ويتأكد إن إشعار حضور أو انصراف حقيقي يوصل والتطبيق مسكّر، ويوصل هم والتطبيق مفتوح
- [ ] رابط سياسة الخصوصية من الإعدادات
- [ ] تسجيل الخروج

الإشعارات ما تشتغل على الـ Simulator، لازم آيفون حقيقي.

## ٥. البناء والرفع

```bash
flutter build ipa --release
```

بعدين يرفع النسخة بوحدة من الطريقتين:
- يفتح `build/ios/archive/Runner.xcarchive` ← **Distribute App** ← **App Store Connect** ← **Upload**.
- أو يسحب ملف `build/ios/ipa/*.ipa` على برنامج **Transporter** (مجاني من الـ App Store).

بعد حوالي ١٥–٣٠ دقيقة تطلع النسخة بـ App Store Connect ← TestFlight.

**رقم النسخة** ينقرا من `pubspec.yaml` (`version: 1.0.8+9`). كل رفع جديد لازم يكون الرقم بعد `+` أكبر من اللي قبله.

## ٦. ملاحظات

- **السيرفر**: الإشعار لازم ينرسل وبيه قسم `notification` (عنوان ونص). الرسائل اللي بيها `data` بس ما تطلع على الآيفون والتطبيق مسكّر.
- **الأيقونة**: بدون شفافية، وهذا شرط من أبل. إذا انعادت توليد الأيقونات، يستخدم `tools/prepare_branding.ps1` لأنه يحافظ على هالشي.
- **المراجعة**: لازم ننطي أبل حساب ولي أمر تجريبي بقسم App Review Information، لأن التطبيق يحتاج تسجيل دخول.
- **الأجهزة**: التطبيق للآيفون بس (مو آيباد)، وأقل نسخة iOS 15.
