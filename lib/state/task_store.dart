import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../data/json_store.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import 'settings_store.dart';

/// Result of completing a task, used to pick the right celebration.
class CompletionResult {
  const CompletionResult({required this.task, required this.onTime});
  final Task task;

  /// `null` when the task had no due date.
  final bool? onTime;
}

/// Single source of truth for tasks. Every mutation persists locally and keeps
/// scheduled notifications in sync.
class TaskStore extends ChangeNotifier {
  TaskStore(this._db, this._settings, this._notifications);

  final JsonStore _db;
  final SettingsStore _settings;
  final NotificationService _notifications;
  static const _key = 'tasks';

  List<Task> _tasks = [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<Task> get all => List.unmodifiable(_tasks);
  List<Task> get open => _tasks.where((t) => !t.isDone).toList();
  List<Task> get done =>
      _tasks.where((t) => t.isDone).toList()..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  Task? get running => _tasks.where((t) => t.isRunning).firstOrNull;

  Task? byId(String id) => _tasks.where((t) => t.id == id).firstOrNull;

  /// Open tasks in display order: overdue → by due date → undated by priority.
  List<Task> get sortedOpen {
    final list = open;
    list.sort((a, b) {
      final ad = a.dueAt, bd = b.dueAt;
      if (ad != null && bd != null) {
        final c = ad.compareTo(bd);
        return c != 0 ? c : b.priority.weight.compareTo(a.priority.weight);
      }
      if (ad != null) return -1;
      if (bd != null) return 1;
      final p = b.priority.weight.compareTo(a.priority.weight);
      return p != 0 ? p : a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  List<Task> todayTasks([DateTime? now]) {
    now ??= DateTime.now();
    final today = now;
    return _tasks
        .where((t) => t.dueAt != null && Fmt.sameDay(t.dueAt!, today))
        .toList();
  }

  Future<void> load() async {
    final raw = await _db.read(_key);
    if (raw is List) {
      _tasks = raw
          .whereType<Map>()
          .map((m) => Task.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() => _db.write(_key, _tasks.map((t) => t.toJson()).toList());

  Future<void> _sync(Task t) async {
    final s = _settings.value;
    if (!s.notificationsEnabled) return _notifications.cancel(t);
    await _notifications.schedule(t, nudges: s.motivationNudges);
  }

  Future<void> rescheduleAll() async {
    await _notifications.cancelAll();
    for (final t in _tasks.where((t) => !t.isDone)) {
      await _sync(t);
    }
  }

  void _replace(Task t) {
    final i = _tasks.indexWhere((x) => x.id == t.id);
    if (i == -1) {
      _tasks.add(t);
    } else {
      _tasks[i] = t;
    }
  }

  Future<void> upsert(Task task) async {
    _replace(task);
    notifyListeners();
    await _save();
    await _sync(task);
  }

  Future<Task?> delete(String id) async {
    final t = byId(id);
    if (t == null) return null;
    _tasks.removeWhere((x) => x.id == id);
    notifyListeners();
    await _save();
    await _notifications.cancel(t);
    return t;
  }

  /// Completes or re-opens a task. Completing stops its timer and, for
  /// repeating tasks, spawns the next occurrence.
  Future<CompletionResult?> toggleComplete(String id) async {
    final t = byId(id);
    if (t == null) return null;

    if (t.isDone) {
      await upsert(t.copyWith(completedAt: () => null));
      return null;
    }

    final now = DateTime.now();
    final finished = _stopped(t, now).copyWith(completedAt: () => now);
    _replace(finished);

    if (t.repeat != Repeat.none && t.dueAt != null) {
      var next = t.repeat.next(t.dueAt!);
      while (next.isBefore(now)) {
        next = t.repeat.next(next);
      }
      final copy = Task.create(
        title: t.title,
        notes: t.notes,
        priority: t.priority,
        category: t.category,
        dueAt: next,
        reminderMinutes: t.reminderMinutes,
        estimateMinutes: t.estimateMinutes,
        repeat: t.repeat,
        subtasks: [for (final s in t.subtasks) s.copyWith(done: false)],
      );
      _replace(copy);
      await _sync(copy);
    }

    notifyListeners();
    await _save();
    await _notifications.cancel(finished);
    return CompletionResult(task: finished, onTime: finished.completedOnTime);
  }

  Task _stopped(Task t, DateTime now) {
    if (!t.isRunning) return t;
    final session = TimeSession(t.activeStart!, now);
    return t.copyWith(
      activeStart: () => null,
      sessions: session.duration.inSeconds >= 5 ? [...t.sessions, session] : t.sessions,
    );
  }

  /// Starts the focus timer. Only one task can run at a time.
  Future<void> startTimer(String id) async {
    final now = DateTime.now();
    for (final t in _tasks.where((t) => t.isRunning && t.id != id).toList()) {
      _replace(_stopped(t, now));
    }
    final t = byId(id);
    if (t == null || t.isRunning || t.isDone) return;
    _replace(t.copyWith(activeStart: () => now));
    notifyListeners();
    await _save();
  }

  Future<void> stopTimer(String id) async {
    final t = byId(id);
    if (t == null || !t.isRunning) return;
    _replace(_stopped(t, DateTime.now()));
    notifyListeners();
    await _save();
  }

  Future<void> deleteSession(String taskId, TimeSession session) async {
    final t = byId(taskId);
    if (t == null) return;
    await upsert(t.copyWith(sessions: t.sessions.where((s) => s != session).toList()));
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final t = byId(taskId);
    if (t == null) return;
    await upsert(t.copyWith(subtasks: [
      for (final s in t.subtasks) s.id == subtaskId ? s.copyWith(done: !s.done) : s,
    ]));
  }

  Future<int> clearCompleted() async {
    final n = _tasks.where((t) => t.isDone).length;
    _tasks.removeWhere((t) => t.isDone);
    notifyListeners();
    await _save();
    return n;
  }

  /// Erases every task and cancels all scheduled notifications.
  Future<void> deleteAll() async {
    await _notifications.cancelAll();
    _tasks = [];
    notifyListeners();
    await _save();
  }

  /// Imports tasks from a backup. With [replace] the current list is wiped;
  /// otherwise tasks are merged by id (imported version wins).
  Future<int> importTasks(List<Task> incoming, {required bool replace}) async {
    if (replace) {
      await _notifications.cancelAll();
      _tasks = [];
    }
    for (final t in incoming) {
      _replace(t);
    }
    notifyListeners();
    await _save();
    await rescheduleAll();
    return incoming.length;
  }
}
