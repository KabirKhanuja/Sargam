import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

class SettingsRepository {
  static const _kThemeMode = 'settings.themeMode';
  static const _kHapticsEnabled = 'settings.hapticsEnabled';
  static const _kDailyGoalMinutes = 'settings.dailyGoalMinutes';
  static const _kTanpuraVolume = 'settings.tanpuraVolume';
  static const _kUserDisplayName = 'settings.userDisplayName';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  AppSettings load() {
    return AppSettings(
      themeMode: _readThemeMode(_prefs.getString(_kThemeMode)),
      hapticsEnabled:
          _prefs.getBool(_kHapticsEnabled) ??
          AppSettings.defaults.hapticsEnabled,
      dailyGoalMinutes:
          _prefs.getInt(_kDailyGoalMinutes) ??
          AppSettings.defaults.dailyGoalMinutes,
      tanpuraVolume:
          _prefs.getDouble(_kTanpuraVolume) ??
          AppSettings.defaults.tanpuraVolume,
      userDisplayName:
          _prefs.getString(_kUserDisplayName) ??
          AppSettings.defaults.userDisplayName,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_kThemeMode, _writeThemeMode(settings.themeMode));
    await _prefs.setBool(_kHapticsEnabled, settings.hapticsEnabled);
    await _prefs.setInt(_kDailyGoalMinutes, settings.dailyGoalMinutes);
    await _prefs.setDouble(_kTanpuraVolume, settings.tanpuraVolume);
    await _prefs.setString(_kUserDisplayName, settings.userDisplayName);
  }

  Future<void> clearAll() => _prefs.clear();

  static ThemeMode _readThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  static String _writeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
