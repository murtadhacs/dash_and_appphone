import 'package:flutter/widgets.dart';

import 'admin_api.dart';
import 'api_client.dart';
import 'token_store.dart';

/// الخدمات المشتركة للتطبيق (عميل الشبكة + واجهة الإدارة + تخزين الجلسة).
class AppServices {
  AppServices(this.client, this.api, this.store);

  factory AppServices.create({String baseUrl = apiBaseUrl, TokenStore? store}) {
    final s = store ?? SecureTokenStore();
    final c = ApiClient(baseUrl: baseUrl);
    return AppServices(c, AdminApi(c, s), s);
  }

  final ApiClient client;
  final AdminApi api;
  final TokenStore store;
}

/// يمرّر [AppServices] لأي ودجت دون تمريرها يدوياً.
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
