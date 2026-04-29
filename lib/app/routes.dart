import 'package:flutter/material.dart';

import '../features/riyaz/presentation/riyaz_screen.dart';

class AppRoutes {
  static const home = '/';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const RiyazScreen(),
  };
}
