import 'package:alrhman_dashboard/core/baghdad_time.dart';
import 'package:alrhman_dashboard/core/iraqi_phone.dart';
import 'package:alrhman_dashboard/core/parent_pin.dart';
import 'package:alrhman_dashboard/services/excel_export_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting());

  group('IraqiPhone.normalize', () {
    test('الصيغ المقبولة كلها تعطي الرقم نفسه', () {
      const expected = '+9647701234567';
      for (final input in [
        '07701234567',
        '+9647701234567',
        '009647701234567',
        '9647701234567',
        '+964 0770 123 4567',
        '0770-123-4567',
        '(0770) 123.4567',
        '٠٧٧٠١٢٣٤٥٦٧', // أرقام عربية-هندية
        '۰۷۷۰۱۲۳۴۵۶۷', // أرقام فارسية
      ]) {
        expect(IraqiPhone.normalize(input), expected, reason: input);
      }
    });

    test('أرقام غير عراقية أو ناقصة ترجع null', () {
      for (final input in [
        '',
        'abc',
        '0770123456',
        '01234567890',
        '+966501234567',
        '07701234567890',
      ]) {
        expect(IraqiPhone.normalize(input), isNull, reason: input);
      }
    });

    test('display يعرض الصيغة المحلية', () {
      expect(IraqiPhone.display('+9647701234567'), '07701234567');
    });
  });

  group('كلمة مرور ولي الأمر', () {
    test('يولَّد 16 رمز ASCII مع حرف ورقم ورمز دائماً', () {
      for (var i = 0; i < 200; i++) {
        final password = generateParentPin();
        expect(password.length, 16);
        expect(password.codeUnits.every((c) => c >= 33 && c <= 126), isTrue);
        expect(RegExp(r'[A-Za-z]').hasMatch(password), isTrue);
        expect(RegExp(r'[0-9]').hasMatch(password), isTrue);
        expect(RegExp(r'[^A-Za-z0-9]').hasMatch(password), isTrue);
      }
    });

    test(
      'المدقق يرفض القاعدة القديمة والمسافات والمحارف غير ASCII والأنواع الناقصة',
      () {
        for (final bad in [
          '12345',
          '123456',
          '12345a',
          '١٢٣٤٥٦',
          'Kq7#vR2m!Tx9pW4',
          '${'a' * 71}1!',
          'Kq7#vR2m!Tx9pW4z ',
          ' Kq7#vR2m!Tx9pW4z',
          'Kq7#vR2m!Tx9pW4z\n',
          'Kq7#vR2m!Tx9pW4z\t',
          'Kq7#vR2m!Tx9pW4ز',
          'Kq7#vR2m!Tx9pW4é',
          'abcdefghijklmno1',
          'abcdefghijklmno!',
          '123456789012345!',
          '',
        ]) {
          expect(isValidParentPin(bad), isFalse, reason: bad);
        }
      },
    );
    test('يقبل حدّي 16 و72 وجميع الرموز ASCII المطبوعة', () {
      expect(isValidParentPin('Kq7#vR2m!Tx9pW4z'), isTrue);
      expect(isValidParentPin('${'a' * 70}1!'), isTrue);
      for (var code = 33; code <= 126; code++) {
        expect(
          isValidParentPin('Abcdefghijklm1!${String.fromCharCode(code)}'),
          isTrue,
        );
      }
    });
  });

  test('BaghdadTime.minutesOfDay يحوّل صيغة 12 ساعة', () {
    expect(BaghdadTime.minutesOfDay('07:15 AM'), 7 * 60 + 15);
    expect(BaghdadTime.minutesOfDay('12:05 PM'), 12 * 60 + 5);
    expect(BaghdadTime.minutesOfDay('12:30 AM'), 30);
    expect(BaghdadTime.minutesOfDay('01:00 PM'), 13 * 60);
    expect(BaghdadTime.minutesOfDay(null), isNull);
    expect(BaghdadTime.minutesOfDay('غير صالح'), isNull);
  });

  test('ملف Excel يحتوي العناوين والصفوف بالترتيب وباتجاه RTL', () {
    final bytes = ExcelExportService.buildWorkbook(
      headers: const ['الاسم', 'الصف'],
      rows: const [
        ['عمر', 'تمهيدي'],
        ['ليان', 'روضة 2'],
      ],
    );

    final book = Excel.decodeBytes(bytes);
    final sheet = book[book.getDefaultSheet()!];

    expect(sheet.isRTL, isTrue);
    expect(sheet.maxRows, 3);
    String at(int c, int r) => sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
        .value
        .toString();
    expect(at(0, 0), 'الاسم');
    expect(at(1, 2), 'روضة 2');
  });
}
