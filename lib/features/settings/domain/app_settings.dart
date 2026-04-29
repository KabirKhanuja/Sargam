import 'package:flutter/material.dart';

@immutable
class AppSettings {
  final ThemeMode themeMode;
  final bool hapticsEnabled;
  final int dailyGoalMinutes;
  final double tanpuraVolume;
  final String userDisplayName;

  const AppSettings({
    required this.themeMode,
    required this.hapticsEnabled,
    required this.dailyGoalMinutes,
    required this.tanpuraVolume,
    required this.userDisplayName,
  });

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    hapticsEnabled: true,
    dailyGoalMinutes: 15,
    tanpuraVolume: 0.6,
    userDisplayName: '',
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? hapticsEnabled,
    int? dailyGoalMinutes,
    double? tanpuraVolume,
    String? userDisplayName,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      tanpuraVolume: tanpuraVolume ?? this.tanpuraVolume,
      userDisplayName: userDisplayName ?? this.userDisplayName,
    );
  }
}
