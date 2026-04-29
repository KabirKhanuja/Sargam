import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/riyaz/presentation/riyaz_screen.dart';

class AppRoutes {
  static const home = '/';
  static const auth = '/auth';
  static const profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    auth: (context) => const AuthScreen(),
    profile: (context) => const ProfileScreen(),
    home: (context) => const RiyazScreen(),
  };
}
