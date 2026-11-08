import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/quotes.dart';
import '../l10n/strings.dart';
import '../models/task.dart';
import '../state/settings_store.dart';
import '../state/task_store.dart';
import 'screens/task_detail_screen.dart';
import 'screens/task_editor.dart';
import 'navigation.dart';
import 'widgets/celebration.dart';

/// UI-level task actions shared by every screen (feedback, undo, celebration).
abstract final class TaskActions {
  static Future<void> toggleComplete(BuildContext context, Task task) async {
    final store = context.read<TaskStore>();
    final celebrate = context.read<SettingsStore>().value.celebrations;
    HapticFeedback.mediumImpact();
    final result = await store.toggleComplete(task.id);
    final root = appNavigatorKey.currentContext;
    if (result == null || root == null || !root.mounted) return;
    if (celebrate) {
      await showCelebration(root, result);
    } else {
      _snack(S.current.completed(task.title));
    }
  }

  static Future<void> delete(BuildContext context, Task task) async {
    final store = context.read<TaskStore>();
    final removed = await store.delete(task.id);
    if (removed == null) return;
    HapticFeedback.lightImpact();
    appMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(S.current.deleted(removed.title)),
        action: SnackBarAction(label: S.current.undo, onPressed: () => store.upsert(removed)),
      ));
  }

  static Future<void> toggleTimer(BuildContext context, Task task) async {
    final store = context.read<TaskStore>();
    HapticFeedback.mediumImpact();
    if (task.isRunning) {
      await store.stopTimer(task.id);
    } else {
      await store.startTimer(task.id);
      _snack(S.current.focusStarted(Quotes.start().text));
    }
  }

  static void open(BuildContext context, Task task) => Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, __, ___) => TaskDetailScreen(taskId: task.id),
          transitionsBuilder: (_, a, __, child) {
            final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );

  static Future<void> edit(BuildContext context, [Task? task]) =>
      showTaskEditor(context, task: task);

  static void _snack(String msg) {
    appMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }
}
