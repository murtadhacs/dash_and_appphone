import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/iraqi_phone.dart';
import '../models/student.dart';

const _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// حفظ ملفات Excel في الجهاز، وتوليد كشف الطلاب محلياً.
///
/// تقرير الحضور اليومي يأتي جاهزاً من الخادم (`/api/admin/export/excel`)،
/// ويُحفظ عبر [saveXlsx]. أما كشف الطلاب فلا مقابل له في الخادم فيُولَّد هنا.
///
/// كل دالة ترجع true إذا حُفظ الملف، وfalse إذا ألغى المستخدم نافذة الحفظ.
class ExcelExportService {
  ExcelExportService._();

  static Future<bool> exportStudents(List<Student> students) {
    final bytes = buildWorkbook(
      headers: const [
        'كود الطالب',
        'اسم الطالب',
        'الصف',
        'الشعبة',
        'ولي الأمر',
        'رقم الهاتف',
      ],
      rows: [
        for (final s in students)
          [
            s.rfidTag,
            s.name,
            s.grade ?? '',
            s.section ?? '',
            s.parentName.isEmpty ? '-' : s.parentName,
            s.parentPhone.isEmpty ? '-' : IraqiPhone.display(s.parentPhone),
          ],
      ],
    );
    return saveXlsx('كشف_الطلاب.xlsx', bytes);
  }

  /// يبني ملف xlsx بورقة واحدة: صف عناوين ملوّن ثم الصفوف، باتجاه من اليمين لليسار.
  @visibleForTesting
  static Uint8List buildWorkbook({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final excel = Excel.createExcel();
    // لا نعيد تسمية الورقة: مكتبة excel تُسقط اتجاه RTL عند rename.
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    sheet.isRTL = true;

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#FF1E3A8A'),
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.appendRow([for (final h in headers) TextCellValue(h)]);
    for (var c = 0; c < headers.length; c++) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
              .cellStyle =
          headerStyle;
    }

    for (final row in rows) {
      sheet.appendRow([for (final v in row) TextCellValue(v)]);
    }

    // عرض كل عمود بحسب أطول نص فيه (حد أدنى 12 وأقصى 50).
    for (var c = 0; c < headers.length; c++) {
      var longest = headers[c].length;
      for (final row in rows) {
        if (row[c].length > longest) longest = row[c].length;
      }
      sheet.setColumnWidth(c, (longest + 4).clamp(12, 50).toDouble());
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('تعذر إنشاء ملف Excel');
    }
    return Uint8List.fromList(encoded);
  }

  /// يفتح نافذة الحفظ ويكتب [bytes] في الملف المختار.
  static Future<bool> saveXlsx(String fileName, Uint8List bytes) async {
    final saved = await FilePicker.saveFile(
      dialogTitle: 'حفظ ملف Excel',
      fileName: fileName,
      bytes: bytes,
      mimeType: _xlsxMime,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
    );
    // على الويب يبدأ المتصفح التنزيل مباشرة ولا يُرجع الـ plugin مساراً.
    return kIsWeb || saved != null;
  }
}
