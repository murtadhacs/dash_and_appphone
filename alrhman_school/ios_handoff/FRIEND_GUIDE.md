# نشر تطبيق «الرحمن الابتدائية» على الآيفون: شنو باقي وشلون تسويه

هلا بيك، وشكراً على المساعدة 🙏

هذا التطبيق مال أولياء أمور طلاب مدرسة الرحمن الابتدائية. ولي الأمر يشوف بيه حضور ابنه وجدوله وقسطه، وتوصله إشعارات من يدخل ابنه للمدرسة ومن يطلع منها. التطبيق مسوّى بـ Flutter وشغّال على الأندرويد.

---

## الخلاصة

**اللي خلص:**
- الكود جاهز للآيفون على GitHub: الريبو `murtadhacs/dash_and_appphone`، الفرع `ios-release`، مجلد `alrhman_school`.
- الإعدادات كلها مضبوطة: الإشعارات، وFirebase، والأيقونات، وأقل نسخة iOS.
- سياسة الخصوصية منشورة ومربوطة داخل التطبيق.
- إلك صلاحية Admin بحساب المطوّر عن طريق الحساب اللي استلمته.

**اللي باقي عليك:**

| # | الخطوة | الوقت التقريبي |
|---|---|---|
| ١ | تجهيز الماك | ساعة (أغلبها تنزيل Xcode) |
| ٢ | تسجيل حساب أبل بـ Xcode | ٥ دقائق |
| ٣ | معرّف التطبيق ومفتاح الإشعارات بموقع أبل | ١٠ دقائق |
| ٤ | Firebase: إضافة تطبيق الآيفون ورفع المفتاح | ١٠ دقائق |
| ٥ | صفحة التطبيق بـ App Store Connect | ٥ دقائق |
| ٦ | تنزيل الكود ووضع ملف Firebase | ٥ دقائق |
| ٧ | Codex يبني التطبيق | ٣٠–٦٠ دقيقة |
| ٨ | التجربة على الآيفون | ٢٠ دقيقة |
| ٩ | رفع النسخة وTestFlight | ٣٠ دقيقة |
| ١٠ | تعبئة صفحة المتجر | ساعة |
| ١١ | الإرسال للمراجعة | يوم أو يومين انتظار |

---

## قبل ما تبدي: تأكد عندك هذني

- [ ] ماك عليه آخر macOS، ومساحة فاضية ٤٠ GB أو أكثر
- [ ] آيفون، ووياه كيبل يربطه بالماك
- [ ] **حساب Apple** اللي انطاك إياه صاحب التطبيق، ويكون صاحب التطبيق قريب منك وقت أول دخول حتى يدزلك رمز التحقق
- [ ] **حساب GitHub** مالتك، وصاحب التطبيق ضافك على الريبو. تقبل الدعوة من إيميلك
- [ ] **دخول على Firebase** لمشروع `future-kids-attendance`. إذا ما عندك، اطلب من صاحب المشروع يضيفك
- [ ] **حساب ولي أمر تجريبي** (رقم هاتف + PIN) مربوط بيه طالب واحد على الأقل. تاخذه من صاحب التطبيق، وتحتاجه للتجربة ولمراجعة أبل

---

## ١. تجهيز الماك

1. نزّل **Xcode** من الـ App Store (لازم نسخة 26 أو أحدث). افتحه مرة وحدة، ووافق على الشروط، وخليه ينزّل مكونات iOS.
2. نزّل **Flutter** من https://docs.flutter.dev/get-started/install/macos . تحتاج نسخة 3.44 أو أحدث.
3. نزّل **Codex**.
4. افتح Terminal واكتب:
   ```bash
   flutter doctor
   ```
   إذا طلع خطأ بقسم Xcode أو iOS، Codex يگدر يساعدك تصلحه بالخطوة ٧.

## ٢. تسجيل حساب أبل بـ Xcode

⚠️ **سجّل بـ Xcode بس.** لا تسجّل الحساب بإعدادات الماك نفسه (System Settings ← Apple Account)، لأن هذا ينزّل صور صاحب الحساب وملفاته على ماكك.

1. **Xcode** ← **Settings** ← **Accounts** ← زر **+** ← **Apple ID** ← تكتب الحساب.
2. صاحب التطبيق يوصله رمز تحقق على جهازه، فيدزلك إياه.
3. تشوف الفريق (Team) يطلع بالقائمة.

## ٣. موقع أبل للمطوّرين

افتح https://developer.apple.com/account وسجّل دخول بنفس الحساب.

**أ. سجّل الـ Team ID:** من **Membership details**. هو ١٠ أحرف وأرقام، و Codex راح يطلبه منك.

**ب. سجّل معرّف التطبيق (Bundle ID):**
1. **Certificates, IDs & Profiles** ← **Identifiers** ← زر **+** ← **App IDs** ← **App** ← **Continue**
2. بخانة Description اكتب `Alrahman Parent`
3. بخانة Bundle ID اختار **Explicit** واكتب `me.yisawi.futurekids.alrahman`
4. تحت بالقائمة أشّر على **Push Notifications** ← **Continue** ← **Register**

إذا گال المعرّف موجود أصلاً بنفس الفريق، هذا تمام. تأكد بس إن Push Notifications مفعّل عليه. وإذا گال المعرّف محجوز بحساب ثاني، وقّف وبلّغ صاحب التطبيق.

**ج. مفتاح الإشعارات (APNs):**
1. **Keys** ← زر **+** ← اكتب اسم مثل `Alrahman Push`
2. أشّر على **Apple Push Notifications service (APNs)** ← **Continue** ← **Register**
3. اضغط **Download** حتى ينزل ملف `AuthKey_XXXXXXXXXX.p8`. ⚠️ **ينزل مرة وحدة بس**، احفظه بمكان أمين.
4. سجّل الـ **Key ID**، وهو مكتوب بنفس الصفحة.

إذا كان أكو مفتاح APNs قديم بالحساب وملفه موجود عند أحد، تگدر تستخدمه، لأن المفتاح الواحد يشتغل لكل تطبيقات الحساب.

## ٤. Firebase

افتح https://console.firebase.google.com ← مشروع **future-kids-attendance**.

**أ. أضف تطبيق الآيفون:**
1. **Project Overview** ← **Add app** ← أيقونة **iOS**
2. بخانة Apple bundle ID اكتب `me.yisawi.futurekids.alrahman` بالضبط
3. بخانة App nickname اكتب `Alrahman iOS`، وبعدين **Register app**
4. نزّل ملف **`GoogleService-Info.plist`**
5. باقي خطوات الصفحة (SDK والكود) **عبّرها كلها**، لأنها مسوّية بالكود.

**ب. ارفع مفتاح الإشعارات:**
1. ⚙️ **Project settings** ← **Cloud Messaging**
2. انزل لـ **Apple app configuration**، وتحت تطبيق الآيفون اضغط **Upload** جنب **APNs Authentication Key**
3. ارفع ملف الـ `.p8`، واكتب الـ **Key ID** والـ **Team ID** ← **Upload**

## ٥. صفحة التطبيق بـ App Store Connect

افتح https://appstoreconnect.apple.com ← **Apps** ← زر **+** ← **New App**:

| الخانة | شنو تكتب |
|---|---|
| Platforms | iOS |
| Name | `الرحمن الابتدائية`. إذا گال الاسم مأخوذ، جرّب `مدرسة الرحمن الابتدائية` |
| Primary Language | Arabic |
| Bundle ID | `me.yisawi.futurekids.alrahman` |
| SKU | `alrahman-parent` |
| User Access | Full Access |

**وبعدين:** روح على **Business** (أو Agreements). إذا بيه اتفاقية تنتظر موافقة، بلّغ صاحب التطبيق، لأن بس صاحب حساب المطوّر يگدر يوافق عليها.

## ٦. تنزيل الكود ووضع ملف Firebase

بالـ Terminal:
```bash
git clone -b ios-release https://github.com/murtadhacs/dash_and_appphone.git
```
- **ملف Firebase:** انقل `GoogleService-Info.plist` إلى `dash_and_appphone/alrhman_school/ios/Runner/`.
- ⚠️ **لا ترفعه على GitHub أبداً.** هو مستثنى من git عمداً.

## ٧. Codex يبني التطبيق

1. افتح Codex داخل مجلد `dash_and_appphone`.
2. افتح ملف **`CODEX_PROMPT.md`** (موجود جوه مجلد `alrhman_school/ios_handoff/`)، وانسخ كل اللي تحت الخط، وانطيه لـ Codex.
3. Codex راح يفحص، ويبني، ويطلب منك شغلات. أهمها:
   - **الـ Team ID**
   - إنك تختار الفريق بـ Xcode ← Signing & Capabilities، وتأشّر على **Automatically manage signing**
   - إنك تربط الآيفون وتفعّل **Developer Mode**. هذا من الآيفون: **Settings ← Privacy & Security ← Developer Mode**، والآيفون يعيد تشغيله
4. Codex **ما يرفع شي لأبل** إلا بعد ما يسألك وانت توافق.
5. Codex **ممنوع يغيّر فرع `main`**، لأن هذا ينشر لوحة المدرسة على السيرفر مباشرة. إذا شفته يحاول، وقّفه.

## ٨. التجربة على الآيفون

Codex يشغّل التطبيق على آيفونك. جرّب:
- [ ] تسجيل الدخول برقم الهاتف والـ PIN، وتطلع بيانات الطالب
- [ ] يطلب إذن الإشعارات، واضغط **السماح**
- [ ] **والتطبيق مفتوح:** يوصل إشعار حقيقي (دخول أو خروج طالب، أو إشعار تدزه المدرسة من اللوحة)
- [ ] **والتطبيق مسكّر:** يوصل نفس الإشعار على شاشة القفل
- [ ] من الإعدادات، رابط سياسة الخصوصية يفتح
- [ ] تسجيل الخروج يشتغل
- [ ] الصفحات كلها عربي ومن اليمين لليسار، وما بيها شي مقصوص

**إذا الإشعار يوصل بس والتطبيق مفتوح:** المشكلة بالسيرفر، مو بالتطبيق، لأن الإشعار ينرسل بدون عنوان ونص. بلّغ صاحب التطبيق.

## ٩. رفع النسخة وTestFlight

1. Codex يبني النسخة النهائية، ويسألك قبل الرفع. وافق، أو ارفعها بنفسك من Xcode:
   - **Organizer** ← **Distribute App** ← **App Store Connect** ← **Upload**
2. بعد ١٥–٣٠ دقيقة تطلع النسخة بـ App Store Connect ← التطبيق ← **TestFlight**.
3. نزّل تطبيق **TestFlight** من الـ App Store على آيفونك، وجرّب النسخة منه مرة أخيرة.

## ١٠. صفحة المتجر

App Store Connect ← التطبيق ← النسخة **1.0.8**.

### المعلومات العامة

| الخانة | المقترح |
|---|---|
| Subtitle | `متابعة حضور أبنائك وإشعارات المدرسة` |
| Category | Education |
| Price | Free |
| Availability | العراق، أو كل الدول |
| Privacy Policy URL | `https://alrahman.up.railway.app/privacy.html` |
| Support URL | نفس الرابط، لأن بيه إيميل الدعم |
| Copyright | `2026 مدرسة الرحمن الابتدائية` |
| Keywords | `مدرسة,الرحمن,حضور,غياب,ولي الأمر,إشعارات,طلاب,قسط,جدول` |

### الوصف (Description)
```
تطبيق «الرحمن الابتدائية» مخصص لأولياء أمور طلاب مدرسة الرحمن الابتدائية.

• إشعار فوري عند وصول ابنك إلى المدرسة وعند انصرافه
• سجل الحضور والغياب والإجازات
• الجدول الدراسي لكل ابن
• المتبقي من القسط الدراسي
• إعلانات المدرسة وتنبيهاتها

الحساب تنشئه إدارة المدرسة لولي الأمر، ويُسجَّل الدخول برقم الهاتف ورمز PIN.
لا إعلانات، ولا تتبّع، ولا بيع للبيانات.
```

### صور الشاشة (Screenshots)
- **المقاس:** آيفون 6.9 إنچ، يعني 1320×2868 أو 1290×2796. ما نحتاج صور آيباد، لأن التطبيق للآيفون بس.
- **الأسهل:** بـ Xcode افتح Simulator من نوع **iPhone 17 Pro Max** (أو 16 Pro Max)، وشغّل التطبيق عليه، وسجّل دخول بالحساب التجريبي، واضغط ⌘S على كل شاشة.
- **العدد:** ٤–٦ صور. مثلاً: الرئيسية، الحضور، الجدول، القسط، الإشعارات، الإعدادات.

### الخصوصية (App Privacy)
**Data Collection:** نعم، نجمع بيانات. اختار هذني فقط:

| النوع | مربوط بالمستخدم؟ | للتتبّع؟ | الغرض |
|---|---|---|---|
| Contact Info ← Name | نعم | لا | App Functionality |
| Contact Info ← Phone Number | نعم | لا | App Functionality |
| Identifiers ← User ID | نعم | لا | App Functionality |
| Identifiers ← Device ID | نعم | لا | App Functionality |
| Financial Info ← Other Financial Info (القسط) | نعم | لا | App Functionality |
| Other Data ← Other Data Types (الحضور والجدول) | نعم | لا | App Functionality |

- ما نجمع: الموقع، الصور، جهات الاتصال، بيانات الصحة، الإعلانات، ولا Analytics.
- السؤال **Do you or your third-party partners use data for tracking?** جوابه **No**.

### التصنيف العمري (Age Rating)
جاوب **None / No** على كل الأسئلة، والنتيجة تطلع **4+**. وبسؤال **Made for Kids** جاوب **لا**، لأن التطبيق لأولياء الأمور، مو للأطفال.

### معلومات المراجعة (App Review Information)
- **Sign-in required:** نعم. واكتب رقم الهاتف والـ PIN مال **الحساب التجريبي** اللي اخذته من صاحب التطبيق، مو حساب حقيقي.
- **Contact:** اسمك أو اسم صاحب التطبيق، ورقم موبايل، والإيميل `alrhamansupport@gmail.com`.
- **Notes:** انسخ هذا كما هو، لأن المراجعين يقرون إنگليزي:
```
This app is for parents of students at Al-Rahman Primary School (Iraq).
Parent accounts are created by the school administration; there is no
in-app sign-up. Sign in with the demo phone number and PIN above (field
"Password"/PIN). The demo account is linked to a test student so you can
see attendance, timetable, fee balance and notifications.
Attendance events come from the school's attendance devices; notifications
are sent by the school through Firebase Cloud Messaging.
Account deletion: Settings > "حذف حساب ولي الأمر" (Delete parent account),
confirm with the PIN.
The app has no ads, no tracking and no in-app purchases.
```

### Build
بقسم **Build** اختار النسخة اللي رفعتها (1.0.8 (9)) ← **Save** ← **Add for Review** ← **Submit**.

## ١١. بعد الإرسال

- المراجعة تاخذ عادة يوم أو يومين.
- **إذا انرفض:** انسخ رسالة أبل كاملة ودزها لصاحب التطبيق (أو لـ Codex إذا المشكلة بالكود). أكثر الأسباب المتوقعة:
  - **الحساب التجريبي ما يشتغل، أو ما بيه بيانات:** تأكد منه قبل الإرسال.
  - **"التطبيق لمؤسسة معيّنة":** إذا أبل گالت هيچ، نطلب منهم **Unlisted App Distribution**. هذا يعني التطبيق ينشر برابط خاص وما يطلع بالبحث، وهذا مناسب لتطبيق مدرسة.
  - **تطبيق مكرر:** إذا الحساب بيه تطبيقات مدارس ثانية تشبهه، أبل ممكن تعتبره مكرر. بلّغ صاحب التطبيق.
- **التحديثات الجاية:**
  1. `git pull` على فرع `ios-release`
  2. نزيد رقم البناء بـ `pubspec.yaml` (الرقم بعد `+`)
  3. نبني ونرفع من جديد

---

## ممنوعات ⚠️
- **لا ترفع على فرع `main` ولا تعدّل عليه.** هذا ينشر لوحة المدرسة على السيرفر مباشرة.
- **لا ترفع على GitHub** ملف `GoogleService-Info.plist`، ولا ملف `.p8`، ولا أي باسورد.
- **لا تغيّر** الـ Bundle ID، ولا اسم التطبيق بالكود، ولا رقم النسخة 1.0.8.
- **لا تسجّل حساب Apple** بإعدادات الماك نفسه. سجّله بـ Xcode بس.
- **لا تنطي ملف الـ `.p8` لأحد** غير صاحب التطبيق، لأنه مثل الباسورد.

## شنو تدز لصاحب التطبيق بالآخر
- [ ] نتيجة التجربة على الآيفون، وخصوصاً: الإشعارات وصلت والتطبيق مسكّر؟
- [ ] رقم النسخة اللي انرفعت، وهل طلعت بـ TestFlight
- [ ] ملف الـ `.p8` والـ Key ID بشكل خاص، حتى يحتفظ بيهن
- [ ] أي تغيير سواه Codex بالكود (بفرع `ios-release` فقط)
- [ ] حالة المراجعة، وأي رسالة رفض من أبل كاملة
