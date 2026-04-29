import 'package:flutter/material.dart';

import 'home_shell.dart';

class AppRoutes {
  static const home = '/';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeShell(),
  };
}
