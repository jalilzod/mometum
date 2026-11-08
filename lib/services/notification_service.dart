import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/format.dart';
import '../core/quotes.dart';
import '../l10n/strings.dart';
import '../models/task.dart';

/// Wraps flutter_local_notifications. Every task owns 8 notification slots:
/// `task.notificationId * 8 + slot`.
///
/// slot 0 – early reminder · slot 1 – due now · slots 2..4 – motivation nudges
/// sent if the task is still not done after the due time.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = fln.FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  /// Emits the task id of a tapped notification.
  Stream<String> get taps => _taps.stream;

  static const _nudgeDelays = [Duration(hours: 1), Duration(days: 1), Duration(days: 3)];
  static const _slotsPerTask = 8;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_supported || _ready) return;
    tzdata.initializeTimeZones();

    const settings = fln.InitializationSettings(
      android: fln.AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: fln.DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (r) {
        final id = r.payload;
        if (id != null && id.isNotEmpty) _taps.add(id);
      },
    );
    _ready = true;
  }

  /// Task id if the app was cold-started by tapping a notification.
  Future<String?> launchPayload() async {
    if (!_ready) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  /// [exactAlarms] may open a system settings page on Android 14+, so it is
  /// only requested from an explicit user action.
  Future<bool> requestPermissions({bool exactAlarms = false}) async {
    if (!_ready) return false;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? false;
      if (exactAlarms) {
        final canExact = await android?.canScheduleExactNotifications() ?? true;
        if (!canExact) await android?.requestExactAlarmsPermission();
      }
      return granted;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<fln.IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  fln.NotificationDetails _details(String channel, String channelName, String body,
          {bool important = true}) =>
      fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          channel,
          channelName,
          channelDescription: channelName,
          icon: '@drawable/ic_notification',
          importance: important ? fln.Importance.high : fln.Importance.defaultImportance,
          priority: important ? fln.Priority.high : fln.Priority.defaultPriority,
          styleInformation: fln.BigTextStyleInformation(body),
          color: const Color(0xFF6C5CE7),
        ),
        iOS: const fln.DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      );

  /// (Re)schedules every notification for [task].
  Future<void> schedule(Task task, {required bool nudges}) async {
    if (!_ready) return;
    await cancel(task);
    final due = task.dueAt;
    if (task.isDone || due == null) return;

    final base = task.notificationId * _slotsPerTask;
    final now = DateTime.now();
    final s = S.current;

    final early = task.reminderMinutes;
    if (early != null && early > 0) {
      final at = due.subtract(Duration(minutes: early));
      final body = s.nComingUpBody(task.title, Fmt.due(due));
      await _at(base, at, now, s.nComingUp, body,
          _details('reminders', s.chReminders, body), task.id);
    }

    final dueBody = s.nDueBody(task.title);
    await _at(base + 1, due, now, s.nDueTitle, dueBody,
        _details('due', s.chDue, dueBody), task.id);

    if (nudges) {
      for (var i = 0; i < _nudgeDelays.length; i++) {
        final q = Quotes.delay();
        final body = '${s.nNudgeBody(task.title)}\n\n${q.text} — ${q.author}';
        await _at(base + 2 + i, due.add(_nudgeDelays[i]), now, s.nNudgeTitle, body,
            _details('motivation', s.chMotivation, body, important: false), task.id);
      }
    }
  }

  Future<void> _at(int id, DateTime when, DateTime now, String title, String body,
      fln.NotificationDetails details, String payload) async {
    if (!when.isAfter(now)) return;
    // Scheduling an absolute UTC instant keeps one-shot alarms correct in any time zone.
    final at = tz.TZDateTime.from(when.toUtc(), tz.UTC);
    try {
      await _plugin.zonedSchedule(id, title, body, at, details,
          androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle, payload: payload);
    } on PlatformException {
      // Exact alarms not permitted (Android 14+) → fall back to inexact delivery.
      await _plugin.zonedSchedule(id, title, body, at, details,
          androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload);
    }
  }

  Future<void> cancel(Task task) async {
    if (!_ready) return;
    final base = task.notificationId * _slotsPerTask;
    for (var i = 0; i < _slotsPerTask; i++) {
      await _plugin.cancel(base + i);
    }
  }

  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }

  Future<void> showNow(String title, String body) async {
    if (!_ready) return;
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000, title, body,
        _details('general', S.current.chGeneral, body));
  }
}
