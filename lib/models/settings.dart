import 'package:flutter/material.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.userName = '',
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.motivationNudges = true,
    this.defaultReminderMinutes = 15,
    this.dailyGoal = 5,
    this.celebrations = true,
    this.languageCode,
  });

  final String userName;
  final ThemeMode themeMode;
  final bool notificationsEnabled;

  /// Send motivational quotes when a task stays undone after its due time.
  final bool motivationNudges;
  final int? defaultReminderMinutes;
  final int dailyGoal;

  /// Show the quote card after completing a task.
  final bool celebrations;

  /// 'en', 'ru' or null to follow the phone's language.
  final String? languageCode;

  Locale? get locale => languageCode == null ? null : Locale(languageCode!);

  AppSettings copyWith({
    String? userName,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? motivationNudges,
    ValueGetter<int?>? defaultReminderMinutes,
    int? dailyGoal,
    bool? celebrations,
    ValueGetter<String?>? languageCode,
  }) =>
      AppSettings(
        userName: userName ?? this.userName,
        themeMode: themeMode ?? this.themeMode,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        motivationNudges: motivationNudges ?? this.motivationNudges,
        defaultReminderMinutes: defaultReminderMinutes != null
            ? defaultReminderMinutes()
            : this.defaultReminderMinutes,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        celebrations: celebrations ?? this.celebrations,
        languageCode: languageCode != null ? languageCode() : this.languageCode,
      );

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'themeMode': themeMode.name,
        'notificationsEnabled': notificationsEnabled,
        'motivationNudges': motivationNudges,
        'defaultReminderMinutes': defaultReminderMinutes,
        'dailyGoal': dailyGoal,
        'celebrations': celebrations,
        'languageCode': languageCode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        userName: j['userName'] as String? ?? '',
        themeMode: ThemeMode.values
            .firstWhere((m) => m.name == j['themeMode'], orElse: () => ThemeMode.system),
        notificationsEnabled: j['notificationsEnabled'] as bool? ?? true,
        motivationNudges: j['motivationNudges'] as bool? ?? true,
        defaultReminderMinutes: (j['defaultReminderMinutes'] as num?)?.toInt(),
        dailyGoal: (j['dailyGoal'] as num?)?.toInt() ?? 5,
        celebrations: j['celebrations'] as bool? ?? true,
        languageCode: j['languageCode'] as String?,
      );
}
