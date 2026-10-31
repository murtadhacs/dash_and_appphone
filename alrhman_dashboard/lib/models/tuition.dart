/// صف في قائمة الأقساط (`GET /api/admin/tuition`). المبالغ دنانير صحيحة.
class TuitionRow {
  final int studentId;
  final String fullName;
  final String? grade, section;
  final bool isActive;

  /// null عندما لا يوجد قسط للصف ([feeSet] false): يُعرض «لم يحدد القسط» وليس صفراً.
  final int? fee;
  final int discount, paid;
  final int? remaining;
  final bool feeSet;

  const TuitionRow({
    required this.studentId,
    required this.fullName,
    required this.grade,
    required this.section,
    required this.isActive,
    required this.fee,
    required this.discount,
    required this.paid,
    required this.remaining,
    required this.feeSet,
  });

  factory TuitionRow.fromJson(Map<String, dynamic> j) => TuitionRow(
    studentId: (j['student_id'] as num).toInt(),
    fullName: j['full_name'] as String? ?? '',
    grade: j['grade'] as String?,
    section: j['section'] as String?,
    isActive: j['is_active'] as bool? ?? true,
    fee: (j['fee'] as num?)?.toInt(),
    discount: (j['discount'] as num?)?.toInt() ?? 0,
    paid: (j['paid'] as num?)?.toInt() ?? 0,
    remaining: (j['remaining'] as num?)?.toInt(),
    feeSet: j['fee_set'] as bool? ?? j['fee'] != null,
  );

  String get gradeSection {
    final g = (grade ?? '').trim();
    final s = (section ?? '').trim();
    if (g.isEmpty && s.isEmpty) return '—';
    if (s.isEmpty) return g;
    if (g.isEmpty) return s;
    return '$g - $s';
  }
}

class TuitionSummary {
  final int totalFee,
      totalDiscount,
      totalCollected,
      totalRemaining,
      notSetCount;
  const TuitionSummary({
    required this.totalFee,
    required this.totalDiscount,
    required this.totalCollected,
    required this.totalRemaining,
    required this.notSetCount,
  });

  factory TuitionSummary.fromJson(Map<String, dynamic> j) => TuitionSummary(
    totalFee: (j['total_fee'] as num?)?.toInt() ?? 0,
    totalDiscount: (j['total_discount'] as num?)?.toInt() ?? 0,
    totalCollected: (j['total_collected'] as num?)?.toInt() ?? 0,
    totalRemaining: (j['total_remaining'] as num?)?.toInt() ?? 0,
    notSetCount: (j['not_set_count'] as num?)?.toInt() ?? 0,
  );
}

class TuitionList {
  final String academicYear;
  final TuitionSummary summary;
  final List<TuitionRow> rows;
  const TuitionList(this.academicYear, this.summary, this.rows);

  factory TuitionList.fromJson(Map<String, dynamic> j) => TuitionList(
    j['academic_year'] as String? ?? '',
    TuitionSummary.fromJson(j['summary'] as Map<String, dynamic>? ?? const {}),
    [
      for (final r in j['data'] as List? ?? const [])
        TuitionRow.fromJson(r as Map<String, dynamic>),
    ],
  );
}

/// دفعة نقدية. لا تُعدَّل ولا تُحذف؛ الخاطئة تُلغى وتبقى في السجل مع السبب.
class TuitionPayment {
  final int id, amount;
  final String paidAt;
  final String? note;
  final bool voided;
  final String? voidedAt, voidReason;

  const TuitionPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    required this.note,
    required this.voided,
    required this.voidedAt,
    required this.voidReason,
  });

  factory TuitionPayment.fromJson(Map<String, dynamic> j) => TuitionPayment(
    id: (j['id'] as num).toInt(),
    amount: (j['amount'] as num).toInt(),
    paidAt: j['paid_at'] as String? ?? '',
    note: j['note'] as String?,
    voided: j['status'] == 'voided',
    voidedAt: j['voided_at'] as String?,
    voidReason: j['void_reason'] as String?,
  );
}

/// قسط طالب واحد مع كل دفعاته (الأحدث أولاً).
class TuitionDetail {
  final TuitionRow row;
  final String? discountNote;
  final List<TuitionPayment> payments;
  final String academicYear;

  const TuitionDetail(
    this.row,
    this.discountNote,
    this.payments,
    this.academicYear,
  );

  factory TuitionDetail.fromJson(
    Map<String, dynamic> data, {
    required String academicYear,
  }) => TuitionDetail(
    TuitionRow.fromJson(data),
    data['discount_note'] as String?,
    [
      for (final p in data['payments'] as List? ?? const [])
        TuitionPayment.fromJson(p as Map<String, dynamic>),
    ],
    academicYear,
  );
}

class GradeFee {
  final String grade;
  final int? fee;
  final String? updatedAt;
  const GradeFee(this.grade, this.fee, this.updatedAt);

  factory GradeFee.fromJson(Map<String, dynamic> j) => GradeFee(
    j['grade'] as String? ?? '',
    (j['fee'] as num?)?.toInt(),
    j['updated_at'] as String?,
  );
}

class GradeFees {
  final String academicYear;
  final List<GradeFee> fees;
  const GradeFees(this.academicYear, this.fees);

  factory GradeFees.fromJson(Map<String, dynamic> j) =>
      GradeFees(j['academic_year'] as String? ?? '', [
        for (final f in j['data'] as List? ?? const [])
          GradeFee.fromJson(f as Map<String, dynamic>),
      ]);
}
