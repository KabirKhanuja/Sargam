import 'package:flutter/material.dart';

class AppRoutes {
  static const home = '/';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const Scaffold(body: Center(child: Text("Sargam"))),
  };
}
