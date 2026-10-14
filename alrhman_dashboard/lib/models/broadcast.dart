class BroadcastDraft {
  const BroadcastDraft({
    required this.title,
    required this.body,
    required this.type,
    this.phone,
    this.grade,
    this.section,
  });
  final String title, body, type;
  final String? phone, grade, section;
  Map<String, dynamic> toJson({required bool dryRun}) => {
    'title': title.trim(),
    'body': body.trim(),
    'audience': {
      'type': type,
      if (type == 'parent') 'parent_phone': phone,
      if (type == 'class' && grade != null) 'grade': grade,
      if (type == 'class' && section != null) 'section': section,
    },
    if (dryRun) 'dry_run': true,
  };
}

class BroadcastPage {
  BroadcastPage.fromJson(Map<String, dynamic> json)
    : items = [
        for (final item in json['data'] as List)
          BroadcastItem.fromJson(item as Map<String, dynamic>),
      ],
      hasMore = json['has_more'] == true,
      nextBefore = (json['next_before'] as num?)?.toInt();
  final List<BroadcastItem> items;
  final bool hasMore;
  final int? nextBefore;
}

class BroadcastItem {
  BroadcastItem.fromJson(Map<String, dynamic> json)
    : id = (json['id'] as num).toInt(),
      title = json['title'] as String,
      body = json['body'] as String,
      audience = json['audience'] as Map<String, dynamic>,
      recipients = (json['recipient_count'] as num).toInt(),
      readers = (json['read_count'] as num).toInt(),
      createdAt = DateTime.parse(json['created_at'] as String);
  final int id, recipients, readers;
  final String title, body;
  final Map<String, dynamic> audience;
  final DateTime createdAt;
  String get audienceLabel => switch (audience['type']) {
    'all' => 'جميع أولياء الأمور',
    'parent' =>
      '${audience['parent_name'] ?? 'ولي أمر غير متاح'}${audience['parent_phone'] == null ? '' : ' • ${audience['parent_phone']}'}',
    _ => [
      if (audience['grade'] != null) 'المرحلة ${audience['grade']}',
      if (audience['section'] != null) 'الشعبة ${audience['section']}',
    ].join(' • '),
  };
}
