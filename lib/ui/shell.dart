import 'dart:async';
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../state/task_store.dart';
import 'screens/dashboard_screen.dart';
import 'screens/guide_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'task_actions.dart';
import 'widgets/common.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  StreamSubscription<String>? _tapSub;

  static const _tabs = [
    (Icons.check_circle_outline_rounded, Icons.check_circle_rounded, 0),
    (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 1),
    (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 2),
    (Icons.settings_outlined, Icons.settings_rounded, 3),
  ];

  @override
  void initState() {
    super.initState();
    final notifications = NotificationService.instance;
    _tapSub = notifications.taps.listen(_openFromNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await notifications.requestPermissions();
      final launchId = await notifications.launchPayload();
      if (launchId != null) _openFromNotification(launchId);
    });
  }

  void _openFromNotification(String id) {
    if (!mounted) return;
    final task = context.read<TaskStore>().byId(id);
    if (task != null) TaskActions.open(context, task);
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  Widget _page(int i) => switch (i) {
        0 => const TasksScreen(),
        1 => const DashboardScreen(),
        2 => const GuideScreen(),
        _ => const SettingsScreen(),
      };

  @override
  Widget build(BuildContext context) {
    // Registers a dependency so the shell (and its pages) rebuild on language change.
    final locale = Localizations.localeOf(context);
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.background,
        extendBody: true,
        body: Stack(children: [
          const _Backdrop(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween(begin: 0.97, end: 1.0).animate(a),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: KeyedSubtree(key: ValueKey(locale), child: _page(_index)),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const _RunningBar(),
              Row(children: [
                Expanded(child: _NavBar(index: _index, tabs: _tabs, onTap: _select)),
                const SizedBox(width: 12),
                _AddButton(onTap: () => TaskActions.edit(context)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }
}

/// Soft ambient gradient blobs behind every page.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IgnorePointer(
      child: Stack(children: [
        Positioned(
          top: -120,
          right: -80,
          child: _blob(p.accent.o(0.16), 320),
        ),
        Positioned(
          top: 180,
          left: -140,
          child: _blob(p.accentAlt.o(0.10), 300),
        ),
      ]),
    );
  }

  Widget _blob(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c, c.o(0)]),
        ),
      );
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.tabs, required this.onTap});
  final int index;
  final List<(IconData, IconData, int)> tabs;
  final ValueChanged<int> onTap;

  static String _label(int i) => switch (i) {
        0 => S.current.navTasks,
        1 => S.current.navDashboard,
        2 => S.current.navGuide,
        _ => S.current.navSettings,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 66,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: p.surface.o(0.82),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: p.border.o(0.7)),
          ),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth / tabs.length;
            return Stack(children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                left: index * w,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: p.accentGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: p.accent.o(0.35), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                ),
              ),
              Row(children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Semantics(
                        label: _label(tabs[i].$3),
                        selected: i == index,
                        button: true,
                        child: AnimatedScale(
                          scale: i == index ? 1.08 : 1,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            i == index ? tabs[i].$2 : tabs[i].$1,
                            color: i == index ? Colors.white : p.textMuted,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ]);
          }),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      scale: 0.88,
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          gradient: p.accentGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: p.accent.o(0.45), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

/// Floating mini-player for the running focus timer.
class _RunningBar extends StatelessWidget {
  const _RunningBar();

  @override
  Widget build(BuildContext context) {
    final task = context.select<TaskStore, Task?>((s) => s.running);
    final p = context.palette;

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
            child: c,
          ),
        ),
        child: task == null
            ? const SizedBox(key: ValueKey('none'), width: double.infinity)
            : Padding(
                key: const ValueKey('bar'),
                padding: const EdgeInsets.only(bottom: 10),
                child: Pressable(
                  scale: 0.98,
                  onTap: () => TaskActions.open(context, task),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    decoration: BoxDecoration(
                      color: p.text,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: p.shadow, blurRadius: 20)],
                    ),
                    child: Row(children: [
                      _PulseDot(color: p.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.background, fontWeight: FontWeight.w700)),
                      ),
                      Ticking(
                        builder: (_) => Text(
                          Fmt.clock(task.trackedTime()),
                          style: TextStyle(
                            color: p.background,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => TaskActions.toggleTimer(context, task),
                        icon: Icon(Icons.stop_circle_rounded, color: p.background, size: 30),
                      ),
                    ]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => SizedBox(
          width: 18,
          height: 18,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 8 + 10 * _c.value,
              height: 8 + 10 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.o(0.5 * (1 - _c.value)),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
            ),
          ]),
        ),
      );
}
