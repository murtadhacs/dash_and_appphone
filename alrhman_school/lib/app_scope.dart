import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/parent_api.dart';
import 'api/session_store.dart';
import 'services/push_device.dart';

/// الخدمات المشتركة: واجهة الـ API والتنقل العام (للعودة للدخول عند انتهاء الجلسة).
class AppServices {
  AppServices(this.api, {GlobalKey<NavigatorState>? navigatorKey})
    : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();

  factory AppServices.create() {
    final push = FirebasePushDevice();
    final api = ParentApi(ApiClient(), SecureSessionStore(), pushDevice: push);
    push.shouldShowNotification = () =>
        api.client.token != null && api.deviceRegistered != false;
    return AppServices(api);
  }

  final ParentApi api;
  final GlobalKey<NavigatorState> navigatorKey;
}

/// يمرّر [AppServices] لأي ودجت.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope غير موجود فوق هذا الودجت');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope old) => services != old.services;
}
