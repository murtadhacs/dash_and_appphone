class SchoolBanner {
  const SchoolBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.isActive,
    this.contentType,
    this.sizeBytes,
  });

  final int id;
  final String title;
  final String imageUrl;
  final bool isActive;
  final String? contentType;
  final int? sizeBytes;

  bool get hasUploadedImage => contentType != null;
  String get extension => switch (contentType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
  };

  factory SchoolBanner.fromJson(Map<String, dynamic> json) => SchoolBanner(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? '',
    imageUrl: json['image_url'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    contentType: json['image_content_type'] as String?,
    sizeBytes: (json['image_size_bytes'] as num?)?.toInt(),
  );
}
