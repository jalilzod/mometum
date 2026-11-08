import 'dart:math';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../l10n/strings.dart';
import '../models/task.dart';

enum Quadrant {
  doFirst(Icons.local_fire_department_rounded),
  schedule(Icons.event_available_rounded),
  delegate(Icons.bolt_rounded),
  later(Icons.inbox_rounded);

  const Quadrant(this.icon);
  final IconData icon;

  String get label => switch (this) {
        Quadrant.doFirst => S.current.qDoFirst,
        Quadrant.schedule => S.current.qSchedule,
        Quadrant.delegate => S.current.qQuick,
        Quadrant.later => S.current.qLater,
      };

  String get subtitle => switch (this) {
        Quadrant.doFirst => S.current.qDoFirstSub,
        Quadrant.schedule => S.current.qScheduleSub,
        Quadrant.delegate => S.current.qQuickSub,
        Quadrant.later => S.current.qLaterSub,
      };
}

class Recommendation {
  const Recommendation(this.task, this.score, this.reason);
  final Task task;
  final double score;
  final String reason;
}

class Tip {
  const Tip(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class DayStat {
  const DayStat(this.day, this.completed, this.focus);
  final DateTime day;
  final int completed;
  final Duration focus;
}

/// Snapshot of everything the dashboard and guide need. Pure and testable.
class Insights {
  Insights._({
    required this.now,
    required this.week,
    required this.completedToday,
    required this.dueToday,
    required this.focusToday,
    required this.focusWeek,
    required this.onTimeRate,
    required this.completionRate,
    required this.streak,
    required this.peakHour,
    required this.estimateAccuracy,
    required this.pendingByPriority,
    required this.pendingByCategory,
    required this.overdue,
    required this.pending,
  });

  final DateTime now;
  final List<DayStat> week;
  final int completedToday;
  final int dueToday;
  final Duration focusToday;
  final Duration focusWeek;

  /// 0..1 or null when no completed task had a due date.
  final double? onTimeRate;
  final double? completionRate;
  final int streak;
  final int? peakHour;

  /// actual / estimate. >1 means tasks take longer than planned.
  final double? estimateAccuracy;
  final Map<Priority, int> pendingByPriority;
  final Map<TaskCategory, int> pendingByCategory;
  final int overdue;
  final int pending;

  factory Insights.from(List<Task> tasks, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final today = Fmt.dayStart(at);
    final done = tasks.where((t) => t.isDone).toList();
    final open = tasks.where((t) => !t.isDone).toList();

    Duration focusOn(DateTime day) {
      final start = day, end = day.add(const Duration(days: 1));
      var total = Duration.zero;
      for (final t in tasks) {
        for (final s in t.sessions) {
          total += _overlap(s.start, s.end, start, end);
        }
        if (t.activeStart != null) total += _overlap(t.activeStart!, at, start, end);
      }
      return total;
    }

    final week = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final c = done.where((t) => Fmt.sameDay(t.completedAt!, day)).length;
      return DayStat(day, c, focusOn(day));
    });

    final withDue = done.where((t) => t.completedOnTime != null).toList();
    final onTime = withDue.isEmpty
        ? null
        : withDue.where((t) => t.completedOnTime!).length / withDue.length;

    final weekAgo = today.subtract(const Duration(days: 6));
    final createdThisWeek = tasks.where((t) => !t.createdAt.isBefore(weekAgo)).toList();
    final completion = createdThisWeek.isEmpty
        ? null
        : createdThisWeek.where((t) => t.isDone).length / createdThisWeek.length;

    var streak = 0;
    for (var d = today;; d = d.subtract(const Duration(days: 1))) {
      final any = done.any((t) => Fmt.sameDay(t.completedAt!, d));
      if (any) {
        streak++;
      } else if (!Fmt.sameDay(d, today)) {
        break; // Today not finished yet doesn't break the streak.
      }
      if (streak > 3650) break;
    }

    int? peak;
    if (done.length >= 3) {
      final byHour = List.filled(24, 0);
      for (final t in done) {
        byHour[t.completedAt!.hour]++;
      }
      peak = byHour.indexOf(byHour.reduce(max));
    }

    final estimated = done.where((t) => (t.estimateMinutes ?? 0) > 0 && t.sessions.isNotEmpty);
    double? accuracy;
    if (estimated.isNotEmpty) {
      final est = estimated.fold<int>(0, (s, t) => s + t.estimateMinutes!);
      final act = estimated.fold<int>(0, (s, t) => s + t.trackedTime(at).inMinutes);
      accuracy = act / est;
    }

    return Insights._(
      now: at,
      week: week,
      completedToday: week.last.completed,
      dueToday: open.where((t) => t.dueAt != null && Fmt.sameDay(t.dueAt!, at)).length,
      focusToday: week.last.focus,
      focusWeek: week.fold(Duration.zero, (s, d) => s + d.focus),
      onTimeRate: onTime,
      completionRate: completion,
      streak: streak,
      peakHour: peak,
      estimateAccuracy: accuracy,
      pendingByPriority: {for (final p in Priority.values) p: open.where((t) => t.priority == p).length},
      pendingByCategory: {
        for (final c in TaskCategory.values)
          if (open.any((t) => t.category == c)) c: open.where((t) => t.category == c).length
      },
      overdue: open.where((t) => t.isOverdue(at)).length,
      pending: open.length,
    );
  }

  static Duration _overlap(DateTime a0, DateTime a1, DateTime b0, DateTime b1) {
    final s = a0.isAfter(b0) ? a0 : b0;
    final e = a1.isBefore(b1) ? a1 : b1;
    return e.isAfter(s) ? e.difference(s) : Duration.zero;
  }
}

/// The "smart guide": ranks open tasks and explains why.
abstract final class SmartGuide {
  /// Higher = do sooner. Blends importance, urgency, momentum and effort.
  static double score(Task t, DateTime now) {
    var s = t.priority.weight * 10.0;

    final due = t.dueAt;
    if (due != null) {
      final hours = due.difference(now).inMinutes / 60;
      if (hours < 0) {
        s += 40 + min(-hours, 72) / 2; // overdue: strongest pull, grows with lateness
      } else {
        s += 35 * exp(-hours / 24); // decays over ~a day
      }
    }
    if (t.isRunning) s += 25;
    if (t.sessions.isNotEmpty) s += 6; // already started → finish it
    if (t.subtaskProgress > 0) s += 8 * t.subtaskProgress;
    final est = t.estimateMinutes;
    if (est != null && est <= 15) s += 5; // quick win bonus
    return s;
  }

  static List<Recommendation> rank(List<Task> tasks, [DateTime? now]) {
    now ??= DateTime.now();
    final open = tasks.where((t) => !t.isDone).toList();
    final list = [for (final t in open) Recommendation(t, score(t, now), reason(t, now))];
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  static String reason(Task t, DateTime now) {
    final s = S.current;
    final due = t.dueAt;
    if (t.isRunning) return s.rRunning;
    if (due != null && due.isBefore(now)) return s.rOverdue(Fmt.compact(now.difference(due)));
    if (due != null && due.difference(now).inHours < 6) {
      return s.rDueSoon(Fmt.relative(due, now), t.priority.label.toLowerCase());
    }
    if (t.sessions.isNotEmpty || t.subtaskProgress > 0) return s.rStarted;
    final est = t.estimateMinutes;
    if (est != null && est <= 15) return s.rQuick(est);
    if (t.priority.weight >= 3) return s.rHigh;
    return s.rDefault;
  }

  static Quadrant quadrant(Task t, DateTime now) {
    final urgent = t.dueAt != null && t.dueAt!.difference(now).inHours < 48;
    final important = t.priority.weight >= 3;
    if (urgent && important) return Quadrant.doFirst;
    if (important) return Quadrant.schedule;
    if (urgent) return Quadrant.delegate;
    return Quadrant.later;
  }

  static List<Task> quickWins(List<Task> tasks) =>
      tasks.where((t) => !t.isDone && (t.estimateMinutes ?? 99) <= 15).take(5).toList();

  static List<Tip> tips(Insights i, List<Task> tasks) {
    final s = S.current;
    final tips = <Tip>[];
    if (i.overdue > 0) {
      tips.add(Tip(Icons.warning_amber_rounded, s.tipOverdueT(i.overdue), s.tipOverdueB));
    }
    final urgent = i.pendingByPriority[Priority.urgent] ?? 0;
    if (urgent > 3) tips.add(Tip(Icons.tune_rounded, s.tipUrgentT, s.tipUrgentB(urgent)));
    if (i.peakHour != null) {
      tips.add(Tip(Icons.insights_rounded, s.tipPeakT(Fmt.hour(i.peakHour!)), s.tipPeakB));
    }
    final acc = i.estimateAccuracy;
    if (acc != null && acc > 1.25) {
      tips.add(Tip(Icons.timer_outlined, s.tipSlowT((acc * 100 - 100).round()), s.tipSlowB));
    } else if (acc != null && acc < 0.8) {
      tips.add(Tip(Icons.speed_rounded, s.tipFastT, s.tipFastB));
    }
    final rate = i.onTimeRate;
    if (rate != null && rate >= 0.8) {
      tips.add(Tip(Icons.verified_rounded, s.tipReliableT((rate * 100).round()), s.tipReliableB));
    } else if (rate != null && rate < 0.5) {
      tips.add(Tip(Icons.schedule_rounded, s.tipSlipT, s.tipSlipB));
    }
    final noDue = tasks.where((t) => !t.isDone && t.dueAt == null).length;
    if (noDue >= 5) tips.add(Tip(Icons.event_note_rounded, s.tipNoDueT(noDue), s.tipNoDueB));
    if (i.streak >= 3) {
      tips.add(Tip(Icons.local_fire_department_rounded, s.tipStreakT(i.streak), s.tipStreakB));
    }
    if (i.focusToday.inMinutes == 0 && i.pending > 0) {
      tips.add(Tip(Icons.play_circle_outline_rounded, s.tipNoFocusT, s.tipNoFocusB));
    }
    if (tips.isEmpty) tips.add(Tip(Icons.auto_awesome_rounded, s.tipClearT, s.tipClearB));
    return tips;
  }
}
