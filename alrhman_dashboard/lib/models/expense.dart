class ExpenseCategory {
  final int id;
  final String name;

  /// الفئة الوحيدة التي تقبل اختيار معلم (رواتب).
  final bool isSalary;
  const ExpenseCategory(this.id, this.name, this.isSalary);

  factory ExpenseCategory.fromJson(Map<String, dynamic> j) => ExpenseCategory(
    (j['id'] as num).toInt(),
    j['name'] as String? ?? '',
    j['is_salary'] as bool? ?? false,
  );
}

/// مصروف. لا يُعدَّل ولا يُحذف؛ الخاطئ يُلغى ويبقى في القائمة مع السبب.
class Expense {
  final int id, amount;
  final ExpenseCategory category;
  final String expenseDate;
  final String? note;
  final int? teacherId;
  final String? teacherName;
  final bool voided;
  final String? voidReason;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.note,
    required this.teacherId,
    required this.teacherName,
    required this.voided,
    required this.voidReason,
  });

  factory Expense.fromJson(Map<String, dynamic> j) {
    final cat = j['category'] as Map<String, dynamic>? ?? const {};
    final teacher = j['teacher'] as Map<String, dynamic>?;
    return Expense(
      id: (j['id'] as num).toInt(),
      amount: (j['amount'] as num).toInt(),
      // الرد لا يحمل is_salary داخل الفئة، فتُحدَّد من قائمة الفئات عند الحاجة.
      category: ExpenseCategory(
        (cat['id'] as num?)?.toInt() ?? 0,
        cat['name'] as String? ?? '',
        cat['is_salary'] as bool? ?? false,
      ),
      expenseDate: j['expense_date'] as String? ?? '',
      note: j['note'] as String?,
      teacherId: (teacher?['id'] as num?)?.toInt(),
      teacherName: teacher?['full_name'] as String?,
      voided: j['status'] == 'voided',
      voidReason: j['void_reason'] as String?,
    );
  }
}

class ExpenseList {
  final String academicYear;

  /// مجموع غير الملغاة فقط.
  final int total;
  final List<Expense> expenses;
  const ExpenseList(this.academicYear, this.total, this.expenses);

  factory ExpenseList.fromJson(Map<String, dynamic> j) => ExpenseList(
    j['academic_year'] as String? ?? '',
    ((j['summary'] as Map<String, dynamic>?)?['total'] as num?)?.toInt() ?? 0,
    [
      for (final e in j['data'] as List? ?? const [])
        Expense.fromJson(e as Map<String, dynamic>),
    ],
  );
}

/// مجموع (للسنة أو لشهر). [collected] و[difference] null عند تصفية فئة واحدة:
/// تُعرضان بشرطة وليس صفراً.
class ExpenseTotals {
  final int expenses;
  final int? collected, difference;
  const ExpenseTotals(this.expenses, this.collected, this.difference);

  factory ExpenseTotals.fromJson(Map<String, dynamic> j) => ExpenseTotals(
    (j['expenses'] as num?)?.toInt() ?? 0,
    (j['collected'] as num?)?.toInt(),
    (j['difference'] as num?)?.toInt(),
  );
}

class ExpenseMonth {
  final String month;
  final ExpenseTotals totals;
  const ExpenseMonth(this.month, this.totals);
}

class ExpenseCategoryTotal {
  final int categoryId;
  final String name;
  final int total;
  const ExpenseCategoryTotal(this.categoryId, this.name, this.total);
}

class ExpenseSummary {
  final String academicYear;
  final int? categoryId;
  final ExpenseTotals totals;
  final List<ExpenseCategoryTotal> byCategory;
  final List<ExpenseMonth> byMonth;

  const ExpenseSummary({
    required this.academicYear,
    required this.categoryId,
    required this.totals,
    required this.byCategory,
    required this.byMonth,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> j) => ExpenseSummary(
    academicYear: j['academic_year'] as String? ?? '',
    categoryId: (j['category_id'] as num?)?.toInt(),
    totals: ExpenseTotals.fromJson(
      j['totals'] as Map<String, dynamic>? ?? const {},
    ),
    byCategory: [
      for (final c in j['by_category'] as List? ?? const [])
        ExpenseCategoryTotal(
          ((c as Map<String, dynamic>)['category_id'] as num).toInt(),
          c['name'] as String? ?? '',
          (c['total'] as num?)?.toInt() ?? 0,
        ),
    ],
    byMonth: [
      for (final m in j['by_month'] as List? ?? const [])
        ExpenseMonth(
          (m as Map<String, dynamic>)['month'] as String? ?? '',
          ExpenseTotals.fromJson(m),
        ),
    ],
  );
}
