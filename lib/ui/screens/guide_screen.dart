import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/quotes.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../services/insights.dart';
import '../../state/task_store.dart';
import '../task_actions.dart';
import '../../l10n/strings.dart';
import '../widgets/common.dart';

/// Smart guide: what to do next, why, and patterns from your history.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TaskStore>();
    final p = context.palette;
    final now = DateTime.now();
    final ranked = SmartGuide.rank(store.all, now);
    final insights = Insights.from(store.all, now: now);
    final tips = SmartGuide.tips(insights, store.all);
    final quick = SmartGuide.quickWins(store.sortedOpen)
        .where((t) => ranked.isEmpty || t.id != ranked.first.task.id)
        .toList();
    final quote = Quotes.ofTheDay();

    var i = 0;
    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 180),
      children: [
        FadeSlideIn(
          index: i++,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.current.guideTitle,
                style: TextStyle(
                    color: p.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(S.current.whatNext, style: context.text.headlineMedium?.copyWith(fontSize: 27)),
          ]),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          index: i++,
          child: ranked.isEmpty
              ? SurfaceCard(
                  child: EmptyState(
                    icon: Icons.self_improvement_rounded,
                    title: S.current.allCaughtUp,
                    body: S.current.allCaughtUpBody,
                  ),
                )
              : _NextUpCard(rec: ranked.first),
        ),
        if (ranked.length > 1) ...[
          SectionHeader(S.current.then),
          for (final r in ranked.skip(1).take(3))
            FadeSlideIn(index: i++, child: _RankRow(rec: r)),
        ],
        if (quick.isNotEmpty) ...[
          SectionHeader(S.current.quickWins, count: quick.length),
          FadeSlideIn(
            index: i++,
            child: SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: quick.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, k) => _QuickWin(task: quick[k]),
              ),
            ),
          ),
        ],
        if (insights.pending > 0) ...[
          SectionHeader(S.current.priorityMatrix),
          FadeSlideIn(index: i++, child: _Matrix(tasks: store.sortedOpen, now: now)),
        ],
        SectionHeader(S.current.insights),
        for (final t in tips) FadeSlideIn(index: i++, child: _TipCard(tip: t)),
        SectionHeader(S.current.quoteOfDay),
        FadeSlideIn(
          index: i++,
          child: SurfaceCard(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.format_quote_rounded, color: p.accent, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(quote.text,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, height: 1.4)),
                  const SizedBox(height: 8),
                  Text('— ${quote.author}', style: TextStyle(color: p.textMuted)),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.rec});
  final Recommendation rec;

  @override
  Widget build(BuildContext context) {
    final t = rec.task;
    final p = context.palette;
    return Pressable(
      scale: 0.98,
      onTap: () => TaskActions.open(context, t),
      child: SurfaceCard(
        padding: const EdgeInsets.all(22),
        gradient: LinearGradient(
          colors: [p.accent, p.accentAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.o(0.2),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(S.current.doThisNext,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ]),
            ),
            const Spacer(),
            Pill(label: t.priority.label, color: Colors.white, icon: t.priority.icon),
          ]),
          const SizedBox(height: 16),
          Text(t.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(rec.reason,
              style: TextStyle(color: Colors.white.o(0.9), fontSize: 14, height: 1.4)),
          const SizedBox(height: 18),
          Row(children: [
            if (t.dueAt != null) ...[
              Icon(Icons.schedule_rounded, color: Colors.white.o(0.85), size: 16),
              const SizedBox(width: 6),
              Text(Fmt.due(t.dueAt!),
                  style: TextStyle(color: Colors.white.o(0.9), fontWeight: FontWeight.w600)),
            ],
            const Spacer(),
            Pressable(
              onTap: () => TaskActions.toggleTimer(context, t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(t.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: p.accent),
                  const SizedBox(width: 4),
                  Text(t.isRunning ? S.current.pause : S.current.startNow,
                      style: TextStyle(color: p.accent, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rec});
  final Recommendation rec;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = rec.task;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        scale: 0.98,
        onTap: () => TaskActions.open(context, t),
        child: SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 6,
              height: 40,
              decoration: BoxDecoration(color: t.priority.color, borderRadius: BorderRadius.circular(9)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(rec.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.textMuted, fontSize: 12.5)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textMuted),
          ]),
        ),
      ),
    );
  }
}

class _QuickWin extends StatelessWidget {
  const _QuickWin({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: () => TaskActions.open(context, task),
      child: SizedBox(
        width: 170,
        child: SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.bolt_rounded, color: p.warning, size: 18),
              const SizedBox(width: 4),
              Text(S.current.approxMin(task.estimateMinutes ?? 0),
                  style: TextStyle(color: p.warning, fontWeight: FontWeight.w800, fontSize: 12)),
            ]),
            const Spacer(),
            Text(task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

class _Matrix extends StatelessWidget {
  const _Matrix({required this.tasks, required this.now});
  final List<Task> tasks;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final groups = {for (final q in Quadrant.values) q: <Task>[]};
    for (final t in tasks) {
      groups[SmartGuide.quadrant(t, now)]!.add(t);
    }
    final colors = {
      Quadrant.doFirst: p.danger,
      Quadrant.schedule: p.accent,
      Quadrant.delegate: p.warning,
      Quadrant.later: p.textMuted,
    };

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        for (final q in Quadrant.values)
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            color: colors[q]!.o(0.08),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(q.icon, color: colors[q], size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(q.label,
                      style: TextStyle(fontWeight: FontWeight.w800, color: colors[q])),
                ),
                Text('${groups[q]!.length}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: colors[q], fontSize: 18)),
              ]),
              Text(q.subtitle, style: TextStyle(color: p.textMuted, fontSize: 11)),
              const SizedBox(height: 8),
              for (final t in groups[q]!.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('• ${t.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                ),
            ]),
          ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});
  final Tip tip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [p.accent.o(0.16), p.accentAlt.o(0.16)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tip.icon, color: p.accent, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tip.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              Text(tip.body, style: TextStyle(color: p.textMuted, fontSize: 13.5, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }
}
