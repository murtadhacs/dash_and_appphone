const activityActionLabels = <String, String>{
  'parent.account_delete': 'حذف ولي الأمر لحسابه',
  'login.success': 'تسجيل دخول',
  'login.failed': 'محاولة دخول فاشلة',
  'student.create': 'إضافة طالب',
  'student.update': 'تعديل طالب',
  'student.deactivate': 'إيقاف طالب',
  'device.create': 'إضافة جهاز',
  'device.update': 'تعديل جهاز',
  'device.disable': 'تعطيل جهاز',
  'leave.create': 'تسجيل إجازة',
  'leave.delete': 'إلغاء إجازة',
  'settings.update': 'تعديل الإعدادات',
  'schedule.save': 'حفظ الجدول',
  'schedule.import': 'استيراد الجدول',
  'broadcast.send': 'إرسال إشعار',
  'holiday.create': 'تسجيل عطلة',
  'holiday.cancel': 'إلغاء عطلة',
  'banner.create': 'إضافة إعلان',
  'banner.update': 'تعديل إعلان',
  'banner.delete': 'حذف إعلان',
  'export.attendance': 'تصدير الحضور',
  'export.schedule': 'تصدير الجدول',
  'attendance.manual_create': 'تسجيل حضور يدوي',
  'attendance.manual_delete': 'حذف حضور يدوي',
};

class ActivityLogItem {
  ActivityLogItem.fromJson(Map<String, dynamic> json)
    : id = (json['id'] as num).toInt(),
      createdAt = DateTime.parse(json['created_at'] as String),
      actor = json['actor'] as String,
      action = json['action'] as String,
      method = json['method'] as String,
      path = json['path'] as String,
      status = (json['status'] as num).toInt(),
      result = json['result'] as String,
      ip = json['ip'] as String?,
      targetType = json['target_type'] as String?,
      targetId = json['target_id'] as String?,
      detail = json['detail'] as String?;

  final int id, status;
  final DateTime createdAt;
  final String actor, action, method, path, result;
  final String? ip, targetType, targetId, detail;

  String get actionLabel => activityActionLabels[action] ?? action;
  String get targetLabel =>
      [targetType, targetId].whereType<String>().join(' • ');
  bool get isPreview => detail?.contains('dry_run') ?? false;
  DateTime get baghdadTime => createdAt.toUtc().add(const Duration(hours: 3));
}

class ActivityLogPage {
  ActivityLogPage.fromJson(Map<String, dynamic> json)
    : items = [
        for (final item in json['data'] as List)
          ActivityLogItem.fromJson(item as Map<String, dynamic>),
      ],
      hasMore = json['has_more'] == true,
      nextBefore = (json['next_before'] as num?)?.toInt();

  final List<ActivityLogItem> items;
  final bool hasMore;
  final int? nextBefore;
}
