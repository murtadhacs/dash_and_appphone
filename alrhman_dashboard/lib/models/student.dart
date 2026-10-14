/// طالب كما يرجعه `GET /api/admin/students`.
class Student {
  final int id;
  final String name;
  final String parentName;

  /// الرقم القياسي `+9647XXXXXXXXX`، أو نص فارغ إن لم يُربط ولي أمر.
  final String parentPhone;

  /// معرّف الطالب على جهاز البصمة (User ID). يُستخدم أيضاً كـ"كود الطالب".
  final String rfidTag;
  final String? grade;
  final String? section;

  /// تاريخ إنشاء السجل (`created_at`) إن أرجعه الخادم.
  final DateTime? createdAt;

  const Student({
    required this.id,
    required this.name,
    required this.parentName,
    required this.parentPhone,
    required this.rfidTag,
    this.grade,
    this.section,
    this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      parentName: json['parent_name'] as String? ?? '',
      parentPhone: json['parent_phone'] as String? ?? '',
      rfidTag: json['rfid_tag'] as String? ?? '',
      grade: json['grade'] as String?,
      section: json['section'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  /// الخادم يضع `admin-<رقم>` لطالب أُنشئ بلا معرّف بصمة.
  bool get hasRealRfid => !rfidTag.startsWith('admin-');

  /// الصف والشعبة للعرض، مثل "الثالث - أ".
  String get gradeSection {
    final g = (grade ?? '').trim();
    final s = (section ?? '').trim();
    if (g.isEmpty && s.isEmpty) return '—';
    if (s.isEmpty) return g;
    if (g.isEmpty) return s;
    return '$g - $s';
  }
}
