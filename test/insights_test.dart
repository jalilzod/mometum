import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/models/task.dart';
import 'package:momentum/services/backup_service.dart';
import 'package:momentum/models/settings.dart';
import 'package:momentum/services/insights.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);

  Task task(String title,
          {Priority p = Priority.medium, DateTime? due, DateTime? done, int? est}) =>
      Task.create(title: title, priority: p, dueAt: due, estimateMinutes: est)
          .copyWith(completedAt: () => done);

  group('SmartGuide', () {
    test('overdue urgent task ranks first', () {
      final tasks = [
        task('later', p: Priority.low),
        task('overdue', p: Priority.urgent, due: now.subtract(const Duration(hours: 3))),
        task('tomorrow', p: Priority.high, due: now.add(const Duration(days: 1))),
      ];
      final ranked = SmartGuide.rank(tasks, now);
      expect(ranked.first.task.title, 'overdue');
      expect(ranked.last.task.title, 'later');
    });

    test('completed tasks are never recommended', () {
      final ranked = SmartGuide.rank([task('done', done: now)], now);
      expect(ranked, isEmpty);
    });

    test('quadrant classification', () {
      expect(SmartGuide.quadrant(task('a', p: Priority.urgent, due: now), now), Quadrant.doFirst);
      expect(SmartGuide.quadrant(task('b', p: Priority.high), now), Quadrant.schedule);
      expect(SmartGuide.quadrant(task('c', p: Priority.low, due: now), now), Quadrant.delegate);
      expect(SmartGuide.quadrant(task('d', p: Priority.low), now), Quadrant.later);
    });
  });

  group('Insights', () {
    test('on-time rate and streak', () {
      final tasks = [
        task('on time', due: now, done: now.subtract(const Duration(hours: 1))),
        task('late', due: now.subtract(const Duration(days: 1, hours: 2)),
            done: now.subtract(const Duration(days: 1))),
      ];
      final i = Insights.from(tasks, now: now);
      expect(i.onTimeRate, 0.5);
      expect(i.streak, 2);
      expect(i.completedToday, 1);
    });
  });

  group('Backup', () {
    test('round-trips tasks through JSON', () {
      final original = [
        task('a', p: Priority.high, due: now, est: 30).copyWith(
          subtasks: const [Subtask(id: 's1', title: 'step', done: true)],
          sessions: [TimeSession(now, now.add(const Duration(minutes: 25)))],
        ),
      ];
      final decoded = BackupService.decode(BackupService.encode(original, const AppSettings()));
      expect(decoded.tasks.single.title, 'a');
      expect(decoded.tasks.single.priority, Priority.high);
      expect(decoded.tasks.single.subtasks.single.done, isTrue);
      expect(decoded.tasks.single.trackedTime().inMinutes, 25);
    });

    test('rejects garbage', () {
      expect(() => BackupService.decode('not json'), throwsA(isA<BackupException>()));
    });
  });
}
