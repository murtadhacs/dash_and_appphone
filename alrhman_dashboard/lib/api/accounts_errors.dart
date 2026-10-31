import 'api_exception.dart';

/// رسائل عربية لأخطاء المعلمين والأقساط والمصروفات. الخادم يرد بالإنجليزية وقد
/// تتغير الصياغة، فالفرع الأساسي رمز HTTP، والنص يُطابَق بكلمات مفتاحية فقط.
extension AccountsErrors on ApiException {
  String get accountsMessage {
    final m = (serverMessage ?? '').toLowerCase();
    switch (statusCode) {
      case 409:
        if (m.contains('phone is already used')) {
          return 'رقم الهاتف مستخدم لمعلم آخر';
        }
        if (m.contains('rfid_tag is already used by a student')) {
          return 'رقم البصمة هذا لطالب، ولا يجوز أن يُعطى لمعلم';
        }
        if (m.contains('rfid_tag is already used')) {
          return 'رقم البصمة هذا لمعلم آخر';
        }
        if (m.contains('exceeds the remaining')) {
          return 'المبلغ أكبر من المتبقي على الطالب. تأكد من عدم وجود صفر زائد.';
        }
        if (m.contains('discount exceeds the fee')) {
          return 'الخصم أكبر من القسط';
        }
        if (m.contains('discount exceeds the remaining')) {
          return 'الخصم أكبر مما تبقى بعد الدفعات';
        }
        if (m.contains('set the fee for this grade first')) {
          return 'حدد قسط هذا الصف أولاً من «أقساط الصفوف»';
        }
        if (m.contains('already voided')) return 'أُلغي هذا السجل من قبل';
        if (m.contains('apply_to_existing')) {
          final ids = RegExp(r'ids?: ([0-9, ]+)').firstMatch(serverMessage!);
          return 'لم يتغير شيء، ولا حتى قسط الصف: التصحيح يجعل رصيد بعض '
              'الطلاب سالباً${ids == null ? '' : ' (رقم الطالب: ${ids.group(1)!.trim()})'}';
        }
        if (m.contains('only for the salary')) {
          return 'اختيار المعلم مسموح لفئة «رواتب» فقط';
        }
        if (m.contains('already used by another category')) {
          return 'الاسم مستخدم لفئة أخرى';
        }
        return 'تعذر الحفظ: يتعارض مع بيانات محفوظة';
      case 400:
        if (m.contains('phone must be an iraqi mobile')) {
          return 'رقم الهاتف يجب أن يكون رقماً عراقياً مثل 07XXXXXXXXX';
        }
        if (m.contains('rfid_tag must be')) {
          return 'رقم البصمة للمعلم من 1 إلى 99 بأرقام فقط ودون صفر في البداية';
        }
        if (m.contains('amount must be')) {
          return 'المبلغ عدد صحيح بالدينار من 1 إلى 1,000,000,000';
        }
        if (m.contains('cannot be in the future')) {
          return 'التاريخ لا يجوز أن يكون في المستقبل';
        }
        if (m.contains('academic_year must be')) {
          return 'السنة الدراسية سنتان متتاليتان مثل 2026-2027';
        }
        if (m.contains('is required')) return 'حقل مطلوب ناقص: $serverMessage';
        return message;
      case 404:
        if (m.contains('teacher')) return 'المعلم غير موجود';
        if (m.contains('student')) return 'الطالب غير موجود';
        if (m.contains('payment')) return 'الدفعة غير موجودة';
        if (m.contains('expense')) return 'المصروف غير موجود';
        if (m.contains('category')) return 'الفئة غير موجودة';
        return message;
      default:
        return message;
    }
  }
}
