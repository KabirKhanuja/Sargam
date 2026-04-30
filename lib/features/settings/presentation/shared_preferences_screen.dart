import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../practice/presentation/practice_provider.dart';
import 'settings_provider.dart';

class SharedPreferencesScreen extends ConsumerWidget {
  const SharedPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load preferences: $e',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              _SectionCard(
                title: 'Appearance',
                children: [
                  ListTile(
                    title: const Text('Theme'),
                    subtitle: const Text('Light / Dark / System'),
                    trailing: DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      onChanged: (v) {
                        if (v == null) return;
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setSettings(settings.copyWith(themeMode: v));
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Preferences (stored)',
                subtitle: 'Saved locally on this device.',
                children: [
                  SwitchListTile(
                    title: const Text('Haptics'),
                    subtitle: const Text('Enable vibration feedback'),
                    value: settings.hapticsEnabled,
                    onChanged: (v) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setSettings(settings.copyWith(hapticsEnabled: v));
                    },
                  ),
                  ListTile(
                    title: const Text('Tanpura volume (default)'),
                    subtitle: Text(
                      '${(settings.tanpuraVolume * 100).round()}%',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Slider(
                      value: settings.tanpuraVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: '${(settings.tanpuraVolume * 100).round()}%',
                      onChanged: (v) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setSettings(settings.copyWith(tanpuraVolume: v));
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Display name'),
                    subtitle: Text(
                      settings.userDisplayName.isEmpty
                          ? 'Not set'
                          : settings.userDisplayName,
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final next = await _askText(
                        context,
                        title: 'Display name',
                        initialValue: settings.userDisplayName,
                        hintText: 'e.g. Kavya',
                      );
                      if (next == null) return;
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setSettings(
                            settings.copyWith(userDisplayName: next),
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Account',
                children: [
                  ListTile(
                    title: const Text('Log out'),
                    subtitle: const Text('Signs out and clears local data'),
                    leading: const Icon(Icons.logout),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      await ref
                          .read(practiceControllerProvider.notifier)
                          .clearAll();
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .logoutAndClear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<String?> _askText(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String hintText,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}
