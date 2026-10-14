import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'api/app_services.dart';
import 'app_shell.dart';
import 'core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // كل اللغات: 'ar' للعرض و'en' لتنسيق التواريخ الرقمية
  runApp(AlrhmanApp(services: AppServices.create()));
}

class AlrhmanApp extends StatelessWidget {
  final AppServices services;
  const AlrhmanApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        title: 'نظام الرحمن الابتدائية - الإدارة المدرسية',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // اللغة العربية تفعّل اتجاه RTL تلقائياً.
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AppShell(),
      ),
    );
  }
}
