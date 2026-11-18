import 'package:flutter/material.dart';
import 'package:goabusconnect/app/router.dart';
import 'package:goabusconnect/theme/app_theme.dart';

class GoaBusConnectApp extends StatelessWidget {
  const GoaBusConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GoaBusConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
