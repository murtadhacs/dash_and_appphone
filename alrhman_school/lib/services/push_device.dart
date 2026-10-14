import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum PhoneNotificationPermission { allowed, denied, notDetermined, unavailable }

abstract class PushDevice {
  Future<String?> token();
  Stream<String> get tokenRefresh;
  Future<PhoneNotificationPermission> permission();
  Future<void> requestPermission();
  Future<void> openSettings();
  Future<void> deleteToken();
}

class UnavailablePushDevice implements PushDevice {
  @override
  Future<String?> token() async => null;
  @override
  Stream<String> get tokenRefresh => const Stream.empty();
  @override
  Future<PhoneNotificationPermission> permission() async =>
      PhoneNotificationPermission.unavailable;
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> openSettings() async {}
  @override
  Future<void> deleteToken() async {}
}

/// Reads OS permission independently of the account's push setting.
class PhonePushDevice extends UnavailablePushDevice {
  static const _channel = MethodChannel('alrhman/notification-permission');

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<PhoneNotificationPermission> permission() async {
    if (!_supported) return PhoneNotificationPermission.unavailable;
    try {
      final value = await _channel.invokeMethod<String>('status');
      return PhoneNotificationPermission.values.firstWhere(
        (p) => p.name == value,
        orElse: () => PhoneNotificationPermission.unavailable,
      );
    } on PlatformException {
      return PhoneNotificationPermission.unavailable;
    } on MissingPluginException {
      return PhoneNotificationPermission.unavailable;
    }
  }

  @override
  Future<void> requestPermission() async {
    if (_supported) await _channel.invokeMethod<void>('request');
  }

  @override
  Future<void> openSettings() async {
    if (_supported) await _channel.invokeMethod<void>('settings');
  }
}

/// FCM registration plus local presentation of foreground Android messages.
class FirebasePushDevice extends PhonePushDevice {
  static const channel = AndroidNotificationChannel(
    'attendance_alerts',
    'إشعارات وصول الأبناء وانصرافهم',
    description: 'تنبيهات المدرسة والحضور والانصراف',
    importance: Importance.high,
  );

  final _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool Function()? shouldShowNotification;

  bool get _ready =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (!_ready) return;
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      if (shouldShowNotification?.call() != true) return;
      final content = ForegroundNotificationContent.fromMessage(message);
      if (content == null) return;
      try {
        await _notifications.show(
          id:
              (message.messageId ??
                      DateTime.now().microsecondsSinceEpoch.toString())
                  .hashCode &
              0x7fffffff,
          title: content.title,
          body: content.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: 'ic_notification',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      } catch (_) {
        debugPrint('Unable to display foreground notification');
      }
    });
  }

  @override
  Future<String?> token() async =>
      _ready ? FirebaseMessaging.instance.getToken() : null;

  @override
  Stream<String> get tokenRefresh =>
      _ready ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  @override
  Future<void> deleteToken() async {
    if (_ready) await FirebaseMessaging.instance.deleteToken();
    await _notifications.cancelAll();
  }
}

class ForegroundNotificationContent {
  const ForegroundNotificationContent(this.title, this.body);
  final String title;
  final String body;

  static ForegroundNotificationContent? fromMessage(RemoteMessage message) {
    final title =
        message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return null;
    return ForegroundNotificationContent(
      title.isEmpty ? 'مدرسة الرحمن' : title,
      body,
    );
  }
}
