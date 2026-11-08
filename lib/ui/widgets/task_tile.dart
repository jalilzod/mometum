import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../models/task.dart';
import '../task_actions.dart';
import 'common.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final overdue = task.isOverdue();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('dismiss-${task.id}'),
        background: _swipeBg(p.success, Icons.check_rounded,
            task.isDone ? S.current.swipeReopen : S.current.swipeComplete, Alignment.centerLeft),
        secondaryBackground:
            _swipeBg(p.danger, Icons.delete_outline_rounded, S.current.swipeDelete, Alignment.centerRight),
        confirmDismiss: (dir) async {
          if (dir == DismissDirection.startToEnd) {
            await TaskActions.toggleComplete(context, task);
            return false; // the list rebuilds itself
          }
          return true;
        },
        onDismissed: (_) => TaskActions.delete(context, task),
        child: Pressable(
          scale: 0.98,
          onTap: () => TaskActions.open(context, task),
          onLongPress: () => TaskActions.edit(context, task),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: task.isRunning ? p.accent.o(0.6) : p.border.o(0.7),
                width: task.isRunning ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: task.isRunning ? p.accent.o(0.18) : p.shadow,
                  blurRadius: task.isRunning ? 22 : 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(width: 5, color: task.isDone ? p.border : task.priority.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                      child: Row(children: [
                        CheckCircle(
                          checked: task.isDone,
                          color: task.priority.color,
                          onTap: () => TaskActions.toggleComplete(context, task),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _body(context, overdue)),
                        if (!task.isDone) _TimerButton(task: task),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool overdue) {
    final p = context.palette;
    final chips = <Widget>[
      if (task.dueAt != null)
        Pill(
          label: Fmt.due(task.dueAt!),
          icon: overdue ? Icons.error_outline_rounded : Icons.schedule_rounded,
          color: task.isDone ? p.textMuted : (overdue ? p.danger : p.accent),
        ),
      Pill(label: task.category.label, icon: task.category.icon, color: task.category.color),
      if (task.subtasks.isNotEmpty)
        Pill(
          label: '${task.subtasks.where((s) => s.done).length}/${task.subtasks.length}',
          icon: Icons.checklist_rounded,
          color: p.textMuted,
        ),
      if (task.repeat != Repeat.none)
        Pill(label: task.repeat.label, icon: Icons.repeat_rounded, color: p.textMuted),
      if (task.sessions.isNotEmpty || task.isRunning)
        Ticking(
          active: task.isRunning,
          builder: (_) => Pill(
            label: Fmt.compact(task.trackedTime()),
            icon: Icons.timer_outlined,
            color: task.isRunning ? p.success : p.textMuted,
          ),
        ),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          color: task.isDone ? p.textMuted : p.text,
          decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
          decorationColor: p.textMuted,
        ),
        child: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      if (task.notes.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(task.notes,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.textMuted, fontSize: 13)),
      ],
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: chips),
    ]);
  }

  Widget _swipeBg(Color color, IconData icon, String label, Alignment align) => Container(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: align,
        decoration: BoxDecoration(
          color: color.o(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _TimerButton extends StatelessWidget {
  const _TimerButton({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final running = task.isRunning;
    return Pressable(
      scale: 0.85,
      onTap: () => TaskActions.toggleTimer(context, task),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(left: 6),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: running ? LinearGradient(colors: [p.accent, p.accentAlt]) : null,
          color: running ? null : p.surfaceAlt,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (c, a) => RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(a),
              child: ScaleTransition(scale: a, child: c)),
          child: Icon(
            running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(running),
            color: running ? Colors.white : p.accent,
          ),
        ),
      ),
    );
  }
}
