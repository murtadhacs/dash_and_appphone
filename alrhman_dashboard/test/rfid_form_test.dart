import 'package:alrhman_dashboard/api/api_exception.dart';
import 'package:alrhman_dashboard/models/student.dart';
import 'package:alrhman_dashboard/widgets/students/student_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpForm(
  WidgetTester t,
  Future<void> Function(StudentInput) submit, {
  Student? editing,
}) async {
  t.view.physicalSize = const Size(1200, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StudentFormDialog(
          editing: editing,
          knownParentPhones: const {'+9647701111111'},
          onSubmit: submit,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  if (editing == null) {
    await t.enterText(
      find.widgetWithText(TextFormField, 'مثال: ريان فهد الحارثي'),
      'طالب',
    );
    await t.enterText(
      find.widgetWithText(TextFormField, 'مثال: فهد عبد الله الحارثي'),
      'ولي أمر',
    );
    await t.enterText(
      find.widgetWithText(TextFormField, '07XXXXXXXXX'),
      '07701111111',
    );
    await t.pumpAndSettle();
  }
}

Future<void> save(WidgetTester t, {bool edit = false}) async {
  final button = find.text(edit ? 'تحديث التعديلات' : 'حفظ الطالب');
  await t.ensureVisible(button);
  await t.tap(button);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'create requires ASCII digits, rejects a leading zero and submits 14 digits',
    (t) async {
      var calls = 0;
      StudentInput? last;
      await pumpForm(t, (input) async {
        calls++;
        last = input;
        throw const ApiException(message: 'test');
      });
      final field = find.widgetWithText(TextFormField, 'مثال: 100');
      await save(t);
      expect(calls, 0);
      expect(find.text('رقم المستخدم في جهاز البصمة مطلوب'), findsOneWidget);
      await t.enterText(field, '٣٣');
      expect(t.widget<TextFormField>(field).controller!.text, isEmpty);
      await t.enterText(field, '033');
      await save(t);
      expect(calls, 0);
      await t.enterText(field, '12345678901234');
      await save(t);
      expect(calls, 1);
      expect(last!.rfidTag, '12345678901234');
    },
  );
  testWidgets('student RFID must be 100 or more; 1 to 99 belong to teachers', (
    t,
  ) async {
    var calls = 0;
    StudentInput? last;
    await pumpForm(t, (input) async {
      calls++;
      last = input;
      throw const ApiException(message: 'test');
    });
    final field = find.widgetWithText(TextFormField, 'مثال: 100');
    await t.enterText(field, '99');
    await save(t);
    expect(calls, 0);
    expect(find.textContaining('من 100 فأكثر'), findsWidgets);
    await t.enterText(field, '5');
    await save(t);
    expect(calls, 0);
    await t.enterText(field, '100');
    await save(t);
    expect(calls, 1);
    expect(last!.rfidTag, '100');
  });
  testWidgets(
    '409 suggestions can be filled and retried; null hides the button',
    (t) async {
      var calls = 0;
      await pumpForm(t, (input) async {
        calls++;
        expect(
          input.rfidTag,
          calls == 1
              ? '133'
              : calls == 2
              ? '134'
              : '135',
        );
        throw ApiException(
          statusCode: 409,
          message: 'generic',
          suggestedRfidTag: calls == 1
              ? '134'
              : calls == 2
              ? '135'
              : null,
        );
      });
      await t.enterText(find.widgetWithText(TextFormField, 'مثال: 100'), '133');
      await save(t);
      expect(
        find.text('الرقم 133 مسجل لطالب آخر، يمكنك استخدام 134'),
        findsOneWidget,
      );
      await t.tap(find.text('استخدام الرقم 134'));
      await t.pumpAndSettle();
      await save(t);
      expect(
        find.text('الرقم 134 مسجل لطالب آخر، يمكنك استخدام 135'),
        findsOneWidget,
      );
      await t.tap(find.text('استخدام الرقم 135'));
      await t.pumpAndSettle();
      await save(t);
      expect(find.text('الرقم 135 مسجل لطالب آخر'), findsOneWidget);
      expect(find.textContaining('استخدام الرقم'), findsNothing);
    },
  );
  testWidgets('400 RFID server message appears under the field verbatim', (
    t,
  ) async {
    await pumpForm(t, (_) async {
      throw const ApiException(
        statusCode: 400,
        message: 'generic',
        serverMessage: 'rfid_tag is required',
      );
    });
    await t.enterText(find.widgetWithText(TextFormField, 'مثال: 100'), '133');
    await save(t);
    expect(find.text('rfid_tag is required'), findsOneWidget);
    expect(find.text('generic'), findsNothing);
  });
  testWidgets('editing accepts an unchanged legacy device value', (t) async {
    StudentInput? input;
    await pumpForm(
      t,
      (i) async {
        input = i;
        throw const ApiException(message: 'test');
      },
      editing: const Student(
        id: 1,
        name: 'طالب',
        parentName: 'ولي أمر',
        parentPhone: '+9647701111111',
        rfidTag: 'admin-123',
      ),
    );
    await save(t, edit: true);
    expect(input!.rfidTag, 'admin-123');
  });
}
