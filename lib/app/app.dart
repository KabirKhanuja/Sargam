import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

class SargamApp extends StatelessWidget {
  const SargamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sargam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.auth,
      routes: AppRoutes.routes,
    );
  }
}
