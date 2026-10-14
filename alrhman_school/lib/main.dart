// ========================================================
// مدرسة الرحمن الابتدائية — تطبيق ولي الأمر (Flutter / Dart)
// Arabic RTL, Cairo typography, Lucide icons.
// ========================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'services/push_device.dart';
import 'screens/login_screen.dart';
import 'screens/special_states_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_text.dart';
import 'widgets/fade_route.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  }
  final services = AppServices.create();
  await (services.api.pushDevice as FirebasePushDevice).initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(AlRahmanSchoolApp(services: services));
}

class AlRahmanSchoolApp extends StatefulWidget {
  const AlRahmanSchoolApp({super.key, required this.services});

  final AppServices services;

  @override
  State<AlRahmanSchoolApp> createState() => _AlRahmanSchoolAppState();
}

class _AlRahmanSchoolAppState extends State<AlRahmanSchoolApp> {
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    // 401/403 على أي طلب: نحذف الجلسة ونعود لشاشة الدخول (مرة واحدة).
    widget.services.api.client.onUnauthorized = () async {
      if (_redirecting) return;
      _redirecting = true;
      await widget.services.api.clearSession();
      widget.services.navigatorKey.currentState?.pushAndRemoveUntil(
        FadeRoute(page: const LoginScreen(sessionExpired: true)),
        (_) => false,
      );
      _redirecting = false;
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      child: MaterialApp(
        navigatorKey: widget.services.navigatorKey,
        title: 'مدرسة الرحمن — تطبيق ولي الأمر',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: AppText.fontFamily,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.brandPurple,
            primary: AppColors.brandPurple,
            secondary: AppColors.brandBlue,
            surface: Colors.white,
          ),
          textTheme: Typography.blackMountainView.apply(
            fontFamily: AppText.fontFamily,
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: AppColors.brandPurple,
            selectionColor: Color(0x33A91FAF),
            selectionHandleColor: AppColors.brandPurple,
          ),
        ),
        // Whole app is RTL, like `<html dir="rtl">`.
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SplashScreen(),
        routes: {SpecialStatesRoute.name: (_) => const SpecialStatesRoute()},
      ),
    );
  }
}

/// Standalone route for the special-states preview (empty / error / retry).
/// Not linked from the UI; open with `Navigator.pushNamed(context, '/special-states')`.
class SpecialStatesRoute extends StatelessWidget {
  const SpecialStatesRoute({super.key});

  static const String name = '/special-states';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SpecialStatesScreen(),
    );
  }
}
