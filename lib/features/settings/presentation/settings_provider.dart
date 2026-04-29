import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final repo = SettingsRepository(prefs);
    return repo.load();
  }

  Future<void> setSettings(AppSettings next) async {
    state = AsyncData(next);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await SettingsRepository(prefs).save(next);
  }

  Future<void> logoutAndClear() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await SettingsRepository(prefs).clearAll();
    state = const AsyncData(AppSettings.defaults);
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsControllerProvider).asData?.value;
  return settings?.themeMode ?? AppSettings.defaults.themeMode;
});
