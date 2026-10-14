import 'package:flutter/material.dart';

/// Simple cross-fade page transition used between the auth screens
/// and the main shell.
class FadeRoute<T> extends PageRouteBuilder<T> {
  FadeRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) : super(
         pageBuilder: (_, _, _) => page,
         transitionsBuilder: (_, animation, _, child) =>
             FadeTransition(opacity: animation, child: child),
         transitionDuration: duration,
       );
}
