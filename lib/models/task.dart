import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/strings.dart';

enum Priority {
  low(Color(0xFF22C58B), Icons.south_rounded, 1),
  medium(Color(0xFF3B82F6), Icons.drag_handle_rounded, 2),
  high(Color(0xFFF59E0B), Icons.north_rounded, 3),
  urgent(Color(0xFFEF4565), Icons.priority_high_rounded, 4);

  const Priority(this.color, this.icon, this.weight);
  final Color color;
  final IconData icon;
  final int weight;

  String get label => switch (this) {
        Priority.low => S.current.prLow,
        Priority.medium => S.current.prMedium,
        Priority.high => S.current.prHigh,
        Priority.urgent => S.current.prUrgent,
      };
}

enum TaskCategory {
  personal(Icons.person_rounded, Color(0xFF8B7CFF)),
  work(Icons.work_rounded, Color(0xFF3B82F6)),
  study(Icons.school_rounded, Color(0xFF06B6D4)),
  health(Icons.favorite_rounded, Color(0xFFEF4565)),
  shopping(Icons.shopping_bag_rounded, Color(0xFFF59E0B)),
  home(Icons.home_rounded, Color(0xFF22C58B)),
  other(Icons.category_rounded, Color(0xFF94A3B8));

  const TaskCategory(this.icon, this.color);
  final IconData icon;
  final Color color;

  String get label => switch (this) {
        TaskCategory.personal => S.current.catPersonal,
        TaskCategory.work => S.current.catWork,
        TaskCategory.study => S.current.catStudy,
        TaskCategory.health => S.current.catHealth,
        TaskCategory.shopping => S.current.catShopping,
        TaskCategory.home => S.current.catHome,
        TaskCategory.other => S.current.catOther,
      };
}

enum Repeat {
  none,
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
        Repeat.none => S.current.repNever,
        Repeat.daily => S.current.repDaily,
        Repeat.weekly => S.current.repWeekly,
        Repeat.monthly => S.current.repMonthly,
      };

  DateTime next(DateTime from) => switch (this) {
        Repeat.none => from,
        Repeat.daily => from.add(const Duration(days: 1)),
        Repeat.weekly => from.add(const Duration(days: 7)),
        Repeat.monthly => DateTime(from.year, from.month + 1, from.day, from.hour, from.minute),
      };
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

String newId() {
  final r = Random();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${r.nextInt(1 << 30).toRadixString(36)}';
}

@immutable
class Subtask {
  const Subtask({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory Subtask.fromJson(Map<String, dynamic> j) => Subtask(
        id: j['id'] as String? ?? newId(),
        title: j['title'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );
}

/// One focused work interval recorded with Start / Stop.
@immutable
class TimeSession {
  const TimeSession(this.start, this.end);
  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  Map<String, dynamic> toJson() =>
      {'start': start.toIso8601String(), 'end': end.toIso8601String()};

  factory TimeSession.fromJson(Map<String, dynamic> j) =>
      TimeSession(_date(j['start'])!, _date(j['end'])!);
}

/// Immutable task model. Nullable fields are updated through `ValueGetter`
/// arguments in [copyWith] so they can be explicitly cleared.
@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.notificationId,
    this.notes = '',
    this.priority = Priority.medium,
    this.category = TaskCategory.personal,
    this.dueAt,
    this.reminderMinutes,
    this.estimateMinutes,
    this.repeat = Repeat.none,
    this.subtasks = const [],
    this.sessions = const [],
    this.activeStart,
    this.completedAt,
  });

  factory Task.create({
    required String title,
    String notes = '',
    Priority priority = Priority.medium,
    TaskCategory category = TaskCategory.personal,
    DateTime? dueAt,
    int? reminderMinutes,
    int? estimateMinutes,
    Repeat repeat = Repeat.none,
    List<Subtask> subtasks = const [],
  }) =>
      Task(
        id: newId(),
        title: title,
        notes: notes,
        priority: priority,
        category: category,
        dueAt: dueAt,
        reminderMinutes: reminderMinutes,
        estimateMinutes: estimateMinutes,
        repeat: repeat,
        subtasks: subtasks,
        createdAt: DateTime.now(),
        // Each task owns a block of 8 notification ids: notificationId * 8 + slot.
        notificationId: Random().nextInt(200000000) + 1,
      );

  final String id;
  final String title;
  final String notes;
  final Priority priority;
  final TaskCategory category;
  final DateTime? dueAt;

  /// Minutes before [dueAt] to send a heads-up. `null` = no early reminder.
  final int? reminderMinutes;
  final int? estimateMinutes;
  final Repeat repeat;
  final List<Subtask> subtasks;
  final List<TimeSession> sessions;

  /// Non-null while the timer is running.
  final DateTime? activeStart;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int notificationId;

  bool get isDone => completedAt != null;
  bool get isRunning => activeStart != null;

  bool isOverdue([DateTime? now]) =>
      !isDone && dueAt != null && dueAt!.isBefore(now ?? DateTime.now());

  /// `null` when there was no due date to be on time for.
  bool? get completedOnTime =>
      (completedAt == null || dueAt == null) ? null : !completedAt!.isAfter(dueAt!);

  Duration trackedTime([DateTime? now]) {
    var total = sessions.fold<Duration>(Duration.zero, (sum, s) => sum + s.duration);
    if (activeStart != null) total += (now ?? DateTime.now()).difference(activeStart!);
    return total;
  }

  double get subtaskProgress =>
      subtasks.isEmpty ? 0 : subtasks.where((s) => s.done).length / subtasks.length;

  Task copyWith({
    String? title,
    String? notes,
    Priority? priority,
    TaskCategory? category,
    ValueGetter<DateTime?>? dueAt,
    ValueGetter<int?>? reminderMinutes,
    ValueGetter<int?>? estimateMinutes,
    Repeat? repeat,
    List<Subtask>? subtasks,
    List<TimeSession>? sessions,
    ValueGetter<DateTime?>? activeStart,
    ValueGetter<DateTime?>? completedAt,
    String? id,
    DateTime? createdAt,
    int? notificationId,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        dueAt: dueAt != null ? dueAt() : this.dueAt,
        reminderMinutes: reminderMinutes != null ? reminderMinutes() : this.reminderMinutes,
        estimateMinutes: estimateMinutes != null ? estimateMinutes() : this.estimateMinutes,
        repeat: repeat ?? this.repeat,
        subtasks: subtasks ?? this.subtasks,
        sessions: sessions ?? this.sessions,
        activeStart: activeStart != null ? activeStart() : this.activeStart,
        completedAt: completedAt != null ? completedAt() : this.completedAt,
        createdAt: createdAt ?? this.createdAt,
        notificationId: notificationId ?? this.notificationId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'priority': priority.name,
        'category': category.name,
        'dueAt': dueAt?.toIso8601String(),
        'reminderMinutes': reminderMinutes,
        'estimateMinutes': estimateMinutes,
        'repeat': repeat.name,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'activeStart': activeStart?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'notificationId': notificationId,
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String? ?? newId(),
        title: j['title'] as String? ?? 'Untitled',
        notes: j['notes'] as String? ?? '',
        priority: _enumByName(Priority.values, j['priority'], Priority.medium),
        category: _enumByName(TaskCategory.values, j['category'], TaskCategory.other),
        dueAt: _date(j['dueAt']),
        reminderMinutes: (j['reminderMinutes'] as num?)?.toInt(),
        estimateMinutes: (j['estimateMinutes'] as num?)?.toInt(),
        repeat: _enumByName(Repeat.values, j['repeat'], Repeat.none),
        subtasks: (j['subtasks'] as List? ?? [])
            .whereType<Map>()
            .map((m) => Subtask.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        sessions: (j['sessions'] as List? ?? [])
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .where((m) => _date(m['start']) != null && _date(m['end']) != null)
            .map(TimeSession.fromJson)
            .toList(),
        activeStart: _date(j['activeStart']),
        createdAt: _date(j['createdAt']) ?? DateTime.now(),
        completedAt: _date(j['completedAt']),
        notificationId:
            (j['notificationId'] as num?)?.toInt() ?? Random().nextInt(200000000) + 1,
      );
}
