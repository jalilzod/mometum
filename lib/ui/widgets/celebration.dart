import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/quotes.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../state/task_store.dart';

/// Celebration card shown after completing a task, with a particle burst and
/// a quote that depends on whether the task was finished on time.
Future<void> showCelebration(BuildContext context, CompletionResult result) {
  final onTime = result.onTime;
  final quote = onTime == false ? Quotes.late() : Quotes.onTime();
  final s = S.current;
  final title = switch (onTime) {
    true => s.celebOnTime,
    false => s.celebLate,
    null => s.celebDone,
  };
  final subtitle = switch (onTime) {
    true => s.celebOnTimeSub,
    false => s.celebLateSub,
    null => s.celebDoneSub,
  };

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: s.close,
    barrierColor: Colors.black.o(0.45),
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => _CelebrationCard(
      title: title,
      subtitle: subtitle,
      quote: quote,
      taskTitle: result.task.title,
      positive: onTime != false,
    ),
    transitionBuilder: (_, a, __, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(c), child: child),
      );
    },
  );
}

class _CelebrationCard extends StatefulWidget {
  const _CelebrationCard({
    required this.title,
    required this.subtitle,
    required this.quote,
    required this.taskTitle,
    required this.positive,
  });

  final String title;
  final String subtitle;
  final Quote quote;
  final String taskTitle;
  final bool positive;

  @override
  State<_CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<_CelebrationCard> with SingleTickerProviderStateMixin {
  late final _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  final _particles = List.generate(28, (i) => _Particle(Random(i * 7 + DateTime.now().second)));

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = [p.accent, p.accentAlt, p.success, p.warning, const Color(0xFF38BDF8)];
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.o(0.25), blurRadius: 40)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: 120,
              width: 200,
              child: AnimatedBuilder(
                animation: _burst,
                builder: (_, __) => CustomPaint(
                  painter: _BurstPainter(_burst.value, _particles, colors),
                  child: Center(
                    child: Transform.scale(
                      scale: Curves.elasticOut.transform(min(1.0, _burst.value * 1.6)),
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: widget.positive
                                ? [p.success, const Color(0xFF34D3B4)]
                                : [p.accent, p.accentAlt],
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: (widget.positive ? p.success : p.accent).o(0.4),
                                blurRadius: 24)
                          ],
                        ),
                        child: Icon(
                          widget.positive ? Icons.check_rounded : Icons.flag_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.title, style: context.text.headlineMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 6),
            Text(widget.taskTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(widget.subtitle,
                textAlign: TextAlign.center, style: TextStyle(color: p.textMuted)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(children: [
                Icon(Icons.format_quote_rounded, color: p.accent),
                const SizedBox(height: 4),
                Text(widget.quote.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('— ${widget.quote.author}',
                    style: TextStyle(color: p.textMuted, fontSize: 12.5)),
              ]),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(S.current.keepMomentum,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle(Random r)
      : angle = r.nextDouble() * 2 * pi,
        distance = 50 + r.nextDouble() * 60,
        size = 3 + r.nextDouble() * 4,
        colorIndex = r.nextInt(5),
        square = r.nextBool();
  final double angle;
  final double distance;
  final double size;
  final int colorIndex;
  final bool square;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.particles, this.colors);
  final double t;
  final List<_Particle> particles;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final progress = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);
    for (final p in particles) {
      final pos = c +
          Offset(cos(p.angle), sin(p.angle)) * p.distance * progress +
          Offset(0, 18 * t * t); // a touch of gravity
      final paint = Paint()..color = colors[p.colorIndex].o(fade);
      if (p.square) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(p.angle + t * 6);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
        canvas.restore();
      } else {
        canvas.drawCircle(pos, p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
