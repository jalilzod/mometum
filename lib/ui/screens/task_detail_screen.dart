import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../state/task_store.dart';
import '../task_actions.dart';
import '../../l10n/strings.dart';
import '../widgets/common.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context) {
    final task = context.select<TaskStore, Task?>((s) => s.byId(taskId));
    final p = context.palette;

    if (task == null) {
      // Deleted while open.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          Navigator.pop(context);
        }
      });
      return Scaffold(backgroundColor: p.background);
    }

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: S.current.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => TaskActions.edit(context, task),
          ),
          IconButton(
            tooltip: S.current.delete,
            icon: Icon(Icons.delete_outline_rounded, color: p.danger),
            onPressed: () async {
              final ok = await _confirmDelete(context, task);
              if (ok && context.mounted) {
                Navigator.pop(context);
                await TaskActions.delete(context, task);
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          FadeSlideIn(
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              Pill(label: task.priority.label, icon: task.priority.icon, color: task.priority.color),
              Pill(label: task.category.label, icon: task.category.icon, color: task.category.color),
              if (task.repeat != Repeat.none)
                Pill(label: task.repeat.label, icon: Icons.repeat_rounded, color: p.textMuted),
              if (task.isDone)
                Pill(label: S.current.completedTag, icon: Icons.check_rounded, color: p.success, filled: true),
            ]),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 1,
            child: Text(task.title,
                style: context.text.headlineMedium?.copyWith(
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                )),
          ),
          if (task.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            FadeSlideIn(
              index: 2,
              child: Text(task.notes, style: TextStyle(color: p.textMuted, fontSize: 15, height: 1.45)),
            ),
          ],
          const SizedBox(height: 22),
          FadeSlideIn(index: 3, child: _TimerCard(task: task)),
          const SizedBox(height: 14),
          FadeSlideIn(index: 4, child: _InfoGrid(task: task)),
          if (task.subtasks.isNotEmpty) ...[
            SectionHeader(S.current.lblChecklist,
                count: task.subtasks.length,
                trailing: Text('${(task.subtaskProgress * 100).round()}%',
                    style: TextStyle(color: p.accent, fontWeight: FontWeight.w800))),
            FadeSlideIn(
              index: 5,
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Column(children: [
                  for (final s in task.subtasks)
                    ListTile(
                      dense: true,
                      onTap: () => context.read<TaskStore>().toggleSubtask(task.id, s.id),
                      leading: CheckCircle(
                        checked: s.done,
                        color: p.textMuted,
                        size: 24,
                        onTap: () => context.read<TaskStore>().toggleSubtask(task.id, s.id),
                      ),
                      title: Text(s.title,
                          style: TextStyle(
                            fontSize: 15,
                            color: s.done ? p.textMuted : p.text,
                            decoration: s.done ? TextDecoration.lineThrough : null,
                          )),
                    ),
                ]),
              ),
            ),
          ],
          if (task.sessions.isNotEmpty) ...[
            SectionHeader(S.current.focusSessions, count: task.sessions.length),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Column(children: [
                for (final s in task.sessions.reversed)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.timer_outlined, color: p.accent),
                    title: Text(
                        '${DateFormat.MMMd().format(s.start)} · ${Fmt.time(s.start)} – ${Fmt.time(s.end)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(Fmt.compact(s.duration),
                          style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: p.textMuted),
                        onPressed: () => context.read<TaskStore>().deleteSession(task.id, s),
                      ),
                    ]),
                  ),
              ]),
            ),
          ],
          const SizedBox(height: 28),
          GradientButton(
            label: task.isDone ? S.current.markNotDone : S.current.completeTask,
            icon: task.isDone ? Icons.undo_rounded : Icons.check_circle_rounded,
            colors: task.isDone ? [p.textMuted, p.textMuted] : [p.success, const Color(0xFF34D3B4)],
            onTap: () => TaskActions.toggleComplete(context, task),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Task task) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(S.current.deleteTaskQ),
          content: Text(S.current.deleteTaskBody(task.title)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(S.current.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(S.current.delete, style: TextStyle(color: context.palette.danger)),
            ),
          ],
        ),
      ) ??
      false;
}

/// Big stopwatch with a breathing glow while running.
class _TimerCard extends StatefulWidget {
  const _TimerCard({required this.task});
  final Task task;

  @override
  State<_TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<_TimerCard> with SingleTickerProviderStateMixin {
  late final _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_TimerCard old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.task.isRunning && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.task.isRunning && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.animateTo(0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final task = widget.task;
    final running = task.isRunning;
    final est = task.estimateMinutes;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [
            BoxShadow(
              color: p.accent.o(running ? 0.25 + 0.25 * _pulse.value : 0),
              blurRadius: 20 + 20 * _pulse.value,
              spreadRadius: 2 * _pulse.value,
            ),
          ],
        ),
        child: child,
      ),
      child: SurfaceCard(
        gradient: running
            ? LinearGradient(
                colors: [p.accent, p.accentAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        padding: const EdgeInsets.all(22),
        child: Ticking(
          active: running,
          builder: (context) {
            final tracked = task.trackedTime();
            final fg = running ? Colors.white : p.text;
            final sub = running ? Colors.white.o(0.8) : p.textMuted;
            final progress = est == null ? null : tracked.inSeconds / (est * 60);
            return Row(children: [
              ProgressRing(
                value: progress ?? (running ? 1 : 0),
                size: 92,
                stroke: 9,
                track: running ? Colors.white.o(0.2) : null,
                colors: running ? [Colors.white, Colors.white.o(0.7), Colors.white] : null,
                child: Icon(
                  running ? Icons.bolt_rounded : Icons.timer_outlined,
                  color: running ? Colors.white : p.accent,
                  size: 34,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(running ? S.current.focusing : S.current.timeSpent,
                      style: TextStyle(
                          color: sub, fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(Fmt.clock(tracked),
                        style: TextStyle(
                          color: fg,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                  ),
                  if (est != null)
                    Text(
                      S.current.estimateOf(Fmt.hours(Duration(minutes: est)),
                          (min(progress!, 9.99) * 100).round()),
                      style: TextStyle(color: sub, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 12),
                  if (!task.isDone)
                    Pressable(
                      onTap: () => TaskActions.toggleTimer(context, task),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: running ? Colors.white : p.accent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              color: running ? p.accent : Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(running ? S.current.stop : (task.sessions.isEmpty ? S.current.start : S.current.resume),
                              style: TextStyle(
                                color: running ? p.accent : Colors.white,
                                fontWeight: FontWeight.w800,
                              )),
                        ]),
                      ),
                    ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final overdue = task.isOverdue();
    final items = <(IconData, String, String, Color?)>[
      (
        Icons.event_rounded,
        S.current.infoDue,
        task.dueAt == null ? S.current.noDate : Fmt.due(task.dueAt!),
        overdue ? p.danger : null
      ),
      (
        Icons.notifications_active_outlined,
        S.current.infoReminder,
        task.dueAt == null ? '—' : Fmt.reminder(task.reminderMinutes),
        null
      ),
      (
        Icons.hourglass_bottom_rounded,
        S.current.infoEstimate,
        task.estimateMinutes == null ? '—' : Fmt.hours(Duration(minutes: task.estimateMinutes!)),
        null
      ),
      (
        task.isDone ? Icons.flag_rounded : Icons.add_circle_outline_rounded,
        task.isDone ? S.current.infoCompleted : S.current.infoCreated,
        Fmt.due(task.completedAt ?? task.createdAt),
        task.isDone ? (task.completedOnTime == false ? p.warning : p.success) : null
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: [
        for (final (icon, label, value, color) in items)
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Icon(icon, size: 16, color: color ?? p.accent),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                          color: p.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color ?? p.text)),
              ],
            ),
          ),
      ],
    );
  }
}
