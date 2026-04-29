import 'package:flutter/material.dart';

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
      const SharedPreferencesScreen(),
      const _AboutScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: 'Riyaz'),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Shared Prefs',
          ),
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'About'),
        ],
      ),
    );
  }
}

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sargam\n\nRiyaz + pitch monitor.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
