# نظام أطفال المستقبل - لوحة الإدارة المدرسية (Flutter)

تحويل تصميم AI Studio (React) إلى Flutter، مع فصل الشاشات (`screens`) عن الودجتات (`widgets`).

## التشغيل

```bash
flutter pub get
flutter run -d chrome      # أو: -d windows
```

## البنية

```
lib/
├── main.dart              نقطة البدء (RTL + العربية)
├── app_shell.dart         الهيكل: Sidebar + Header + الشاشة الحالية + الحالة المشتركة
├── core/                  الألوان، الثيم، نقاط التوقف
├── models/                Student, AttendanceRecord, DeviceInfo, SchoolSettings
├── data/mock_data.dart    البيانات التجريبية
├── services/              excel_export_service.dart
├── screens/               شاشة = ملف واحد، تدير الحالة وتركّب الودجتات
│   ├── dashboard_screen.dart
│   ├── students_screen.dart
│   ├── attendance_screen.dart
│   ├── devices_screen.dart
│   ├── settings_screen.dart
│   └── login_screen.dart
└── widgets/               ودجتات بلا منطق أعمال، مقسّمة حسب الشاشة
    ├── common/            AppCard, AppButton, AppDialog, AppTextField, AppDataTable, ...
    ├── layout/            Sidebar, AppHeader
    └── dashboard/ students/ attendance/ devices/ settings/ login/
```

القاعدة: الشاشة تملك الحالة وتمرّر البيانات والـ callbacks للودجتات؛ الودجتات لا تعرف بعضها ولا تعرف الشاشات.

## الربط بالـ API

العقد: `flutter_api.yaml` (الإصدار 1.10.0) و`FLUTTER_HANDOFF.md`. العنوان الافتراضي هو staging، ويتغيّر عند التشغيل:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```

- `lib/api/`: `ApiClient` (Bearer + معالجة الأخطاء)، `AdminApi` (كل عمليات `/api/admin/*`)، `TokenStore` (التوكن في التخزين الآمن).
- 401 على أي طلب موثَّق يعيد لشاشة الدخول؛ 429 يعرض دقائق الانتظار.
- لوحة التحكم وشاشة الحضور تتحدّثان تلقائياً كل 20 ثانية.
- رمز ولي الأمر (PIN): 6 أرقام يولّدها التطبيق بـ `Random.secure()` لولي أمر جديد فقط، ويُعرض مرة واحدة بعد الحفظ.
- تصدير حضور اليوم من الخادم (`/api/admin/export/excel`)؛ كشف الطلاب يُولَّد محلياً.

## الاختبارات

```bash
flutter test
```

تشمل اختبار العقد (`api_test`)، والمنطق (`core_test`)، والشاشات على خادم وهمي في الذاكرة (`screens_test`).

## ما لم يُبنَ بعد

- الجدول الأسبوعي: صفحة قائمة الصفوف ومعاينة الحصص وتعديلها مباشرةً عبر GET وPUT `/api/admin/schedule`؛ جميع الصفوف من `/api/admin/schedule/classes`.
- تاريخ انضمام الطالب: يتطلب `created_at` في استجابة الطلاب (غير موجود في العقد الحالي).

## الإصدار 1.0.1

- قسم «بنرات ولي الأمر» للإضافة والتعديل والحذف ورفع الصور والمعاينة والتنزيل.
- طلب GET لتحديث القائمة والصور بعد حفظ البنر أو حذفه.
- الصور بصيغ JPEG وPNG وWebP حتى 2 MiB، مع معاينة البنرات المخفية بواسطة توكن الإدارة.
- نسخة الويب على Railway staging؛ رابط تنزيل APK في `downloads/alrhman_school_parent_1.0.1.apk`.
