import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/quotes.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../state/settings_store.dart';
import '../../state/task_store.dart';
import '../../l10n/strings.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';

enum TaskFilter {
  all,
  today,
  upcoming,
  overdue,
  done;

  String get label => switch (this) {
        TaskFilter.all => S.current.fAll,
        TaskFilter.today => S.current.fToday,
        TaskFilter.upcoming => S.current.fUpcoming,
        TaskFilter.overdue => S.current.fOverdue,
        TaskFilter.done => S.current.fDone,
      };
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskFilter _filter = TaskFilter.all;
  String _query = '';
  bool _showDone = false;
  Priority? _priority;

  bool _matches(Task t) {
    if (_priority != null && t.priority != _priority) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.title.toLowerCase().contains(q) ||
        t.notes.toLowerCase().contains(q) ||
        t.category.label.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TaskStore>();
    final settings = context.watch<SettingsStore>().value;
    final now = DateTime.now();
    final s = S.current;

    final open = store.sortedOpen.where(_matches).toList();
    final done = store.done.where(_matches).toList();
    final overdue = open.where((t) => t.isOverdue(now)).toList();
    final today = open
        .where((t) => !t.isOverdue(now) && t.dueAt != null && Fmt.sameDay(t.dueAt!, now))
        .toList();
    final upcoming = open
        .where((t) => t.dueAt != null && Fmt.dayStart(t.dueAt!).isAfter(Fmt.dayStart(now)))
        .toList();
    final undated = open.where((t) => t.dueAt == null).toList();

    final sections = <(String, List<Task>)>[
      if (_filter == TaskFilter.all) ...[
        (s.secOverdue, overdue),
        (s.secToday, today),
        (s.secUpcoming, upcoming),
        (s.secAnytime, undated),
      ],
      if (_filter == TaskFilter.today) (s.secToday, [...overdue, ...today]),
      if (_filter == TaskFilter.upcoming) (s.secUpcoming, upcoming),
      if (_filter == TaskFilter.overdue) (s.secOverdue, overdue),
      if (_filter == TaskFilter.done) (s.secCompleted, done),
    ].where((s) => s.$2.isNotEmpty).toList();

    final nothing = sections.isEmpty;
    var index = 0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _Header(
                name: settings.userName,
                completedToday:
                    store.done.where((t) => Fmt.sameDay(t.completedAt!, now)).length,
                goal: settings.dailyGoal,
                openToday: overdue.length + today.length,
              ),
            ),
          ),
        ),
        if (overdue.isNotEmpty && _filter != TaskFilter.done)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(child: _NudgeBanner(count: overdue.length)),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _searchBar(context)),
        ),
        SliverToBoxAdapter(child: _filters(context, overdue.length)),
        if (nothing)
          SliverToBoxAdapter(child: _empty())
        else
          for (final (title, tasks) in sections) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: SectionHeader(title, count: tasks.length)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.list(children: [
                for (final t in tasks)
                  FadeSlideIn(
                    key: ValueKey('anim-${t.id}'),
                    index: index++,
                    child: TaskTile(key: ValueKey(t.id), task: t),
                  ),
              ]),
            ),
          ],
        if (_filter == TaskFilter.all && done.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                s.secCompleted,
                count: done.length,
                trailing: Pressable(
                  onTap: () => setState(() => _showDone = !_showDone),
                  child: AnimatedRotation(
                    turns: _showDone ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.expand_more_rounded, color: context.palette.textMuted),
                  ),
                ),
              ),
            ),
          ),
          if (_showDone)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.list(children: [
                for (final (i, t) in done.take(30).indexed)
                  FadeSlideIn(
                    key: ValueKey('anim-done-${t.id}'),
                    index: i,
                    child: TaskTile(key: ValueKey(t.id), task: t),
                  ),
              ]),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 180)),
      ],
    );
  }

  Widget _searchBar(BuildContext context) {
    final p = context.palette;
    return Row(children: [
      Expanded(
        child: TextField(
          onChanged: (v) => setState(() => _query = v.trim()),
          decoration: InputDecoration(
            hintText: S.current.searchHint,
            prefixIcon: Icon(Icons.search_rounded, color: p.textMuted),
            fillColor: p.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(width: 10),
      PopupMenuButton<Priority?>(
        tooltip: S.current.filterPriority,
        onSelected: (v) => setState(() => _priority = v),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (_) => [
          PopupMenuItem(value: null, child: Text(S.current.allPriorities)),
          for (final pr in Priority.values)
            PopupMenuItem(
              value: pr,
              child: Row(children: [
                Icon(Icons.circle, size: 12, color: pr.color),
                const SizedBox(width: 10),
                Text(pr.label),
              ]),
            ),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _priority?.color ?? p.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(Icons.tune_rounded, color: _priority == null ? p.text : Colors.white),
        ),
      ),
    ]);
  }

  Widget _filters(BuildContext context, int overdueCount) {
    final p = context.palette;
    return SizedBox(
      height: 62,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        physics: const BouncingScrollPhysics(),
        children: [
          for (final f in TaskFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Pressable(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: _filter == f ? p.accentGradient : null,
                    color: _filter == f ? null : p.surface,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: _filter == f
                        ? [BoxShadow(color: p.accent.o(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Row(children: [
                    Text(f.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _filter == f ? Colors.white : p.text,
                        )),
                    if (f == TaskFilter.overdue && overdueCount > 0) ...[
                      const SizedBox(width: 6),
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: _filter == f ? Colors.white : p.danger,
                        child: Text('$overdueCount',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _filter == f ? p.danger : Colors.white)),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty() => switch (_filter) {
        _ when _query.isNotEmpty || _priority != null => EmptyState(
            icon: Icons.search_off_rounded,
            title: S.current.emptyNoMatchTitle,
            body: S.current.emptyNoMatchBody),
        TaskFilter.done => EmptyState(
            icon: Icons.emoji_events_outlined,
            title: S.current.emptyDoneTitle,
            body: S.current.emptyDoneBody),
        TaskFilter.overdue => EmptyState(
            icon: Icons.verified_rounded,
            title: S.current.emptyOverdueTitle,
            body: S.current.emptyOverdueBody),
        _ => EmptyState(
            icon: Icons.rocket_launch_rounded,
            title: S.current.emptyStartTitle,
            body: S.current.emptyStartBody),
      };
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.completedToday,
    required this.goal,
    required this.openToday,
  });

  final String name;
  final int completedToday;
  final int goal;
  final int openToday;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final greeting = name.isEmpty ? Fmt.greeting() : '${Fmt.greeting()}, $name';
    final progress = goal == 0 ? 0.0 : completedToday / goal;

    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Fmt.longDate(DateTime.now()).toUpperCase(),
              style: TextStyle(
                  color: p.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(greeting, style: context.text.headlineMedium?.copyWith(fontSize: 27)),
          const SizedBox(height: 4),
          Text(
            openToday == 0
                ? S.current.nothingPressing
                : S.current.needYouToday(openToday),
            style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w500),
          ),
        ]),
      ),
      ProgressRing(
        value: progress,
        size: 72,
        stroke: 8,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$completedToday',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1)),
          Text(S.current.ofGoal(goal), style: TextStyle(fontSize: 10.5, color: p.textMuted)),
        ]),
      ),
    ]);
  }
}

class _NudgeBanner extends StatefulWidget {
  const _NudgeBanner({required this.count});
  final int count;

  @override
  State<_NudgeBanner> createState() => _NudgeBannerState();
}

class _NudgeBannerState extends State<_NudgeBanner> {
  final _quote = Quotes.delay();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: [p.danger.o(0.95), const Color(0xFFFF8A65)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: Colors.white.o(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.local_fire_department_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.current.overdueBanner(widget.count),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            Text('“${_quote.text}”',
                style: TextStyle(color: Colors.white.o(0.9), fontSize: 12.5, height: 1.35)),
          ]),
        ),
      ]),
    );
  }
}
