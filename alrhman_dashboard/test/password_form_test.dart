import 'package:alrhman_dashboard/api/api_exception.dart';
import 'package:alrhman_dashboard/core/parent_pin.dart';
import 'package:alrhman_dashboard/models/student.dart';
import 'package:alrhman_dashboard/widgets/students/student_form_dialog.dart';
import 'package:alrhman_dashboard/widgets/students/students_table_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const parentStudent = Student(
  id: 1,
  name: 'طالب',
  parentName: 'ولي الأمر',
  parentPhone: '+9647701111111',
  rfidTag: '1001',
);
Future<void> pumpForm(
  WidgetTester t,
  Future<void> Function(StudentInput) submit, {
  Student editing = parentStudent,
  Set<String> knownParentPhones = const {'+9647701111111'},
}) async {
  t.view.physicalSize = const Size(1000, 1100);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: StudentFormDialog(
          editing: editing,
          knownParentPhones: knownParentPhones,
          onSubmit: submit,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> tap(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.tap(finder);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('قائمة الطلاب تعرض الطالب بلا ولي أمر دون خطأ', (t) async {
    t.view.physicalSize = const Size(1400, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentsTableCard(
            students: const [
              Student(
                id: 2,
                name: 'طالب غير مرتبط',
                parentName: '',
                parentPhone: '',
                rfidTag: '1002',
              ),
            ],
            total: 1,
            onEdit: (_) {},
            onDelete: (_) {},
            onExport: () {},
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('طالب غير مرتبط'), findsOneWidget);
    expect(find.text('لا يوجد ولي أمر'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'طالب بلا ولي أمر: الحفظ يتطلب الاسم والرقم ويولّد PIN للرقم الجديد',
    (t) async {
      StudentInput? saved;
      var calls = 0;
      await pumpForm(
        t,
        (input) async {
          saved = input;
          calls++;
          throw const ApiException(statusCode: 400, message: 'test');
        },
        editing: const Student(
          id: 2,
          name: 'طالب',
          parentName: '',
          parentPhone: '',
          rfidTag: '1002',
        ),
        knownParentPhones: const {},
      );
      expect(
        find.textContaining('حفظ التعديلات يعيد ربط الطالب'),
        findsOneWidget,
      );
      await tap(t, find.text('تحديث التعديلات'));
      expect(calls, 0);
      await t.enterText(
        find.widgetWithText(TextFormField, 'مثال: فهد عبد الله الحارثي'),
        'ولي الأمر الجديد',
      );
      await t.enterText(
        find.widgetWithText(TextFormField, '07XXXXXXXXX'),
        '07701111111',
      );
      await t.pumpAndSettle();
      await tap(t, find.text('تحديث التعديلات'));
      expect(calls, 1);
      expect(saved!.parentName, 'ولي الأمر الجديد');
      expect(saved!.parentPhone, '+9647701111111');
      expect(isValidParentPin(saved!.parentPin!), isTrue);
    },
  );

  testWidgets('الخادم يطلب PIN لرقم غير مسجّل رغم وجوده بالقائمة القديمة', (
    t,
  ) async {
    final inputs = <StudentInput>[];
    await pumpForm(t, (input) async {
      inputs.add(input);
      throw const ApiException(
        statusCode: 400,
        message: 'invalid',
        serverMessage:
            'parent_pin is required for a new parent (parent_phone is not registered yet)',
      );
    });
    await tap(t, find.text('تحديث التعديلات'));
    expect(inputs.single.parentPin, isNull);
    await tap(t, find.text('تحديث التعديلات'));
    expect(inputs.length, 2);
    expect(isValidParentPin(inputs.last.parentPin!), isTrue);
  });
  testWidgets('توليد وإظهار ونسخ كلمة المرور دون تعديل وقبول 72 رمزاً', (
    t,
  ) async {
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    StudentInput? submitted;
    await pumpForm(t, (input) async {
      submitted = input;
      throw const ApiException(
        statusCode: 400,
        message: 'generic',
        serverMessage: 'Server validation details',
      );
    });
    final form = find.widgetWithText(TextFormField, 'فارغ = بدون تغيير');
    final text = find.descendant(of: form, matching: find.byType(TextField));
    await tap(t, find.byTooltip('توليد كلمة مرور جديدة'));
    final generated = t.widget<TextFormField>(form).controller!.text;
    expect(generated.length, 16);
    expect(isValidParentPin(generated), isTrue);
    expect(t.widget<TextField>(text).obscureText, isTrue);
    expect(t.widget<TextField>(text).enableSuggestions, isFalse);
    await tap(t, find.byTooltip('إظهار'));
    expect(t.widget<TextField>(text).obscureText, isFalse);
    await tap(t, find.byTooltip('نسخ'));
    expect(copied, generated);
    final password = '${'a' * 70}1!';
    await t.enterText(form, password);
    await tap(t, find.text('تحديث التعديلات'));
    expect(submitted!.parentPin, password);
    expect(find.text('Server validation details'), findsOneWidget);
    expect(find.text('generic'), findsNothing);
  });
  testWidgets('التعديل الفارغ يبقي الحالية والرمز القديم يمنع الحفظ', (
    t,
  ) async {
    var calls = 0;
    StudentInput? submitted;
    await pumpForm(t, (input) async {
      calls++;
      submitted = input;
      throw const ApiException(
        statusCode: 400,
        message: 'ordinary',
        serverMessage: 'Server message',
      );
    });
    final form = find.widgetWithText(TextFormField, 'فارغ = بدون تغيير');
    await tap(t, find.text('تحديث التعديلات'));
    expect(calls, 1);
    expect(submitted!.parentPin, isNull);
    expect(find.text('Server message'), findsOneWidget);
    await t.enterText(form, '123456');
    await tap(t, find.text('تحديث التعديلات'));
    expect(calls, 1);
    expect(find.textContaining('16–72 رمزاً إنجليزياً'), findsOneWidget);
  });
}
