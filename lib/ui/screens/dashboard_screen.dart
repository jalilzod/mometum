import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../services/insights.dart';
import '../../state/settings_store.dart';
import '../../state/task_store.dart';
import '../../l10n/strings.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TaskStore>();
    final goal = context.select<SettingsStore, int>((s) => s.value.dailyGoal);
    final i = Insights.from(store.all);
    final p = context.palette;

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 180),
      children: [
        FadeSlideIn(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.current.dashTitle,
                style: TextStyle(
                    color: p.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(S.current.yourProgress, style: context.text.headlineMedium?.copyWith(fontSize: 27)),
          ]),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(index: 1, child: _HeroRing(insights: i, goal: goal)),
        const SizedBox(height: 14),
        FadeSlideIn(index: 2, child: _StatGrid(insights: i)),
        const SizedBox(height: 14),
        FadeSlideIn(index: 3, child: _WeekChart(week: i.week)),
        const SizedBox(height: 14),
        FadeSlideIn(index: 4, child: _PriorityBreakdown(counts: i.pendingByPriority)),
        if (i.pendingByCategory.isNotEmpty) ...[
          const SizedBox(height: 14),
          FadeSlideIn(index: 5, child: _CategoryBreakdown(counts: i.pendingByCategory)),
        ],
      ],
    );
  }
}

class _HeroRing extends StatelessWidget {
  const _HeroRing({required this.insights, required this.goal});
  final Insights insights;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final done = insights.completedToday;
    final progress = goal == 0 ? 0.0 : done / goal;
    final reached = done >= goal && goal > 0;

    return SurfaceCard(
      padding: const EdgeInsets.all(22),
      gradient: LinearGradient(
        colors: [context.palette.accent, context.palette.accentAlt],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(children: [
        ProgressRing(
          value: progress,
          size: 128,
          stroke: 13,
          track: Colors.white.o(0.18),
          colors: [Colors.white, Colors.white.o(0.75), Colors.white],
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CountUp(min(progress, 9.99) * 100,
                suffix: '%',
                style: const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 2),
            Text(S.current.dailyGoalShort, style: TextStyle(color: Colors.white.o(0.8), fontSize: 11.5)),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reached ? S.current.goalCrushed : S.current.today,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _heroLine(Icons.check_circle_rounded, S.current.doneOf(done, goal)),
            _heroLine(Icons.timer_rounded, S.current.focused(Fmt.hours(insights.focusToday))),
            _heroLine(Icons.event_rounded, S.current.stillDueToday(insights.dueToday)),
          ]),
        ),
      ]),
    );
  }

  Widget _heroLine(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.white.o(0.85)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.o(0.92), fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
        ]),
      );
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.insights});
  final Insights insights;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final weekDone = insights.week.fold<int>(0, (s, d) => s + d.completed);
    final stats = [
      _Stat(S.current.doneThisWeek, weekDone.toDouble(), '', Icons.task_alt_rounded, p.accent),
      _Stat(S.current.onTimeRate, (insights.onTimeRate ?? 0) * 100, '%', Icons.verified_rounded, p.success,
          empty: insights.onTimeRate == null),
      _Stat(S.current.focusThisWeek, insights.focusWeek.inMinutes / 60, S.current.hoursSuffix, Icons.bolt_rounded,
          p.warning, decimals: 1),
      _Stat(S.current.dayStreak, insights.streak.toDouble(), '', Icons.local_fire_department_rounded,
          p.danger),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        for (final s in stats)
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: s.color.o(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(s.icon, color: s.color, size: 20),
              ),
              const Spacer(),
              s.empty
                  ? Text('—', style: context.text.headlineMedium)
                  : CountUp(s.value,
                      suffix: s.suffix,
                      decimals: s.decimals,
                      style: context.text.headlineMedium?.copyWith(fontSize: 26)),
              Text(s.label,
                  style: TextStyle(color: p.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
          ),
      ],
    );
  }
}

class _Stat {
  _Stat(this.label, this.value, this.suffix, this.icon, this.color,
      {this.decimals = 0, this.empty = false});
  final String label;
  final double value;
  final String suffix;
  final IconData icon;
  final Color color;
  final int decimals;
  final bool empty;
}

class _WeekChart extends StatefulWidget {
  const _WeekChart({required this.week});
  final List<DayStat> week;

  @override
  State<_WeekChart> createState() => _WeekChartState();
}

class _WeekChartState extends State<_WeekChart> {
  bool _focus = false;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final values = widget.week
        .map((d) => _focus ? d.focus.inMinutes.toDouble() : d.completed.toDouble())
        .toList();
    final maxV = values.fold<double>(0, max);
    final sel = _selected ?? widget.week.length - 1;
    final selValue = _focus
        ? Fmt.hours(widget.week[sel].focus)
        : S.current.tasksCount(widget.week[sel].completed);

    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(S.current.last7, style: context.text.titleMedium),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${DateFormat.EEEE().format(widget.week[sel].day)} · $selValue',
                  key: ValueKey('$sel$_focus'),
                  style: TextStyle(color: p.textMuted, fontSize: 12.5),
                ),
              ),
            ]),
          ),
          _Toggle(
            options: [S.current.tabTasks, S.current.tabFocus],
            index: _focus ? 1 : 0,
            onChanged: (i) => setState(() => _focus = i == 1),
          ),
        ]),
        const SizedBox(height: 22),
        SizedBox(
          height: 150,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selected = i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('$_focus-$i'),
                          tween: Tween(begin: 0, end: maxV == 0 ? 0 : values[i] / maxV),
                          duration: Duration(milliseconds: 700 + i * 90),
                          curve: Curves.easeOutBack,
                          builder: (_, v, __) => FractionallySizedBox(
                            heightFactor: max(0.04, v.clamp(0.0, 1.0)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: sel == i ? 26 : 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: sel == i
                                      ? [p.accent, p.accentAlt]
                                      : [p.accent.o(0.28), p.accentAlt.o(0.28)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.E().format(widget.week[i].day).substring(0, 1),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: sel == i ? p.accent : p.textMuted,
                      ),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.options, required this.index, required this.onChanged});
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const w = 64.0;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: Stack(children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          left: index * w,
          top: 0,
          bottom: 0,
          width: w,
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [BoxShadow(color: p.shadow, blurRadius: 8)],
            ),
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: w,
                height: 30,
                child: Center(
                  child: Text(options[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: i == index ? p.text : p.textMuted,
                      )),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _PriorityBreakdown extends StatelessWidget {
  const _PriorityBreakdown({required this.counts});
  final Map<Priority, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(S.current.openByPriority, style: context.text.titleMedium),
        const SizedBox(height: 16),
        if (total == 0)
          Text(S.current.noOpen, style: TextStyle(color: context.palette.textMuted))
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 14,
              child: Row(children: [
                for (final pr in Priority.values.reversed)
                  if ((counts[pr] ?? 0) > 0)
                    Expanded(
                      flex: counts[pr]!,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: v,
                            child: Container(color: pr.color),
                          ),
                        ),
                      ),
                    ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 16, runSpacing: 8, children: [
            for (final pr in Priority.values.reversed)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: pr.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('${pr.label} · ${counts[pr] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
          ]),
        ],
      ]),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.counts});
  final Map<TaskCategory, int> counts;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.first.value;
    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(S.current.openByCategory, style: context.text.titleMedium),
        const SizedBox(height: 8),
        for (final (i, e) in entries.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              Icon(e.key.icon, size: 18, color: e.key.color),
              const SizedBox(width: 10),
              SizedBox(
                width: 76,
                child: Text(e.key.label,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                      color: p.surfaceAlt, borderRadius: BorderRadius.circular(99)),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: e.value / maxV),
                    duration: Duration(milliseconds: 800 + i * 120),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          decoration: BoxDecoration(
                            color: e.key.color,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
      ]),
    );
  }
}
