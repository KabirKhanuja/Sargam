import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_gate.dart';

class AppRoutes {
  static const home = '/';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const AuthGate(),
  };
}
