/// جهاز بصمة مسجّل (`GET /api/admin/devices`).
class Device {
  final String serialNumber;
  final String locationName;
  final bool isActive;

  /// آخر مرة وصلت فيها بيانات من الجهاز `YYYY-MM-DD HH:MM:SS`، أو null قبل أول اتصال.
  /// لا يعني غيابها أن الجهاز معطّل: تتحدث فقط عند وصول بصمات.
  final String? lastSync;

  const Device({
    required this.serialNumber,
    required this.locationName,
    required this.isActive,
    this.lastSync,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      serialNumber: json['serial_number'] as String? ?? '',
      locationName: json['location_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      lastSync: json['last_sync'] as String?,
    );
  }
}
