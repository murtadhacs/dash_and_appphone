enum NavigationTab {
  dashboard,
  students,
  attendance,
  devices,
  banners,
  broadcasts,
  schedule,
  settings,
  activityLog,

  /// قسم «الحسابات»: الأقساط والمصروفات والمعلمون.
  tuition,
  academicYear,
  expenses,
  teachers,
  login;

  /// شاشات قسم «الحسابات» (تُظلَّل مجموعتها في الشريط الجانبي).
  bool get isAccounts =>
      this == tuition ||
      this == academicYear ||
      this == expenses ||
      this == teachers;
}
