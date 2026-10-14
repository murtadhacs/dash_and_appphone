import 'package:alrhman_dashboard/api/api_exception.dart';
import 'package:alrhman_dashboard/core/baghdad_time.dart';
import 'package:alrhman_dashboard/models/attendance_entry.dart';
import 'package:alrhman_dashboard/models/manual_attendance.dart';
import 'package:alrhman_dashboard/widgets/attendance/manual_attendance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const student = AttendanceEntry(
  studentId: 42,
  fullName: 'الاسم في القائمة',
  status: PresenceStatus.absent,
);
void main() {
  setUpAll(() => initializeDateFormatting('en'));
  setUp(() => BaghdadTime.clock = () => DateTime.utc(2026, 10, 14, 6));
  tearDown(() => BaghdadTime.clock = DateTime.now);
  testWidgets(
    'unconnected form limits dates and keeps real registration disabled',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualAttendanceDialog(
              student: student,
              initialDate: DateTime(2026, 10, 10),
            ),
          ),
        ),
      );
      expect(
        t
            .widget<DropdownButtonFormField<DateTime>>(
              find.byType(DropdownButtonFormField<DateTime>),
            )
            .initialValue,
        DateTime(2026, 10, 14),
      );
      expect(find.textContaining('التسجيل غير متاح حالياً'), findsOneWidget);
      expect(
        t
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'معاينة قبل التأكيد'),
            )
            .onPressed,
        isNull,
      );
      expect(
        t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        true,
      );
      expect(
        t
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        '08:00',
      );
      await t.tap(find.byType(DropdownButtonFormField<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('خروج').last);
      await t.pumpAndSettle();
      expect(find.text('13:00'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'confirmation uses server identity and cannot submit before acceptance',
    (t) async {
      int previews = 0, writes = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManualAttendanceDialog(
              student: student,
              initialDate: DateTime(2026, 10, 13),
              onPreview: (draft) async {
                previews++;
                expect(draft.studentId, 42);
                expect(draft.time, '08:00');
                expect(draft.date, DateTime(2026, 10, 13));
                return const ManualAttendancePreview(
                  studentName: 'اسم الخادم',
                  grade: 'G3',
                  section: 'A',
                );
              },
              onSubmit: (_) async {
                writes++;
                throw const ApiException(
                  statusCode: 409,
                  message: 'generic',
                  serverMessage: 'a punch already exists',
                );
              },
            ),
          ),
        ),
      );
      await t.tap(find.text('معاينة قبل التأكيد'));
      await t.pumpAndSettle();
      expect(previews, 1);
      expect(writes, 0);
      expect(
        find.textContaining('الطالب: اسم الخادم\nالصف: G3\nالشعبة: A'),
        findsOneWidget,
      );
      await t.tap(find.text('تراجع'));
      await t.pumpAndSettle();
      expect(writes, 0);
      await t.tap(find.text('معاينة قبل التأكيد'));
      await t.pumpAndSettle();
      await t.tap(find.text('تأكيد التسجيل'));
      await t.pumpAndSettle();
      expect(writes, 1);
      expect(find.text('a punch already exists'), findsOneWidget);
    },
  );
}
