import 'package:flutter/material.dart';

import '../features/goals/presentation/goals_screen.dart';
import '../features/riyaz/presentation/riyaz_screen.dart';
import '../features/settings/presentation/shared_preferences_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const RiyazScreen(),
      const GoalsScreen(),
      const SharedPreferencesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: 'Riyaz'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
