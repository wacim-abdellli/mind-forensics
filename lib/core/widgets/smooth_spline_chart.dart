import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/theme/mind_tokens.dart';

/// Smooth Bezier Spline Chart with horizontal rules, subtle gradient fill,
/// and interactive scrub tooltip clamped within chart bounds.
class SmoothSplineChart extends StatelessWidget {
  const SmoothSplineChart({
    super.key,
    required this.values,
    this.height = 132,
    this.lineColor,
    this.fillColors,
    this.activePointIndex,
    this.activePointLabel,
    this.showDots = true,
    this.onPointSelected,
  });

  /// Values normalized between 0.0 and 1.0.
  final List<double> values;
  final double height;
  final Color? lineColor;
  final List<Color>? fillColors;
  final int? activePointIndex;
  final String? activePointLabel;
  final bool showDots;
  final ValueChanged<int>? onPointSelected;

  int _nearestIndex(double dx, double width) {
    if (values.length <= 1) return 0;
    const hPad = 10.0;
    final usableWidth = (width - hPad * 2).clamp(1.0, width);
    final stepX = usableWidth / (values.length - 1);
    final raw = ((dx - hPad) / stepX).round();
    return math.max(0, math.min(values.length - 1, raw));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final effectiveLine = lineColor ?? tokens.accent;
    final effectiveFill = fillColors ??
        [
          effectiveLine.withValues(alpha: 0.24),
          effectiveLine.withValues(alpha: 0.0),
        ];

    if (values.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final chart = CustomPaint(
            size: Size(width, height),
            painter: _SplinePainter(
              values: values,
              lineColor: effectiveLine,
              fillColors: effectiveFill,
              gridColor: tokens.border.withValues(alpha: 0.65),
              dotCenterColor: tokens.surface,
              tooltipBgColor: tokens.textPrimary,
              tooltipTextColor: tokens.background,
              activePointIndex: activePointIndex,
              activePointLabel: activePointLabel,
              showDots: showDots,
              textDirection: Directionality.of(context),
            ),
          );

          if (onPointSelected == null || values.length < 2) {
            return chart;
          }

          return Semantics(
            label: activePointLabel ?? 'Mood trend curve',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  onPointSelected!(_nearestIndex(details.localPosition.dx, width)),
              onHorizontalDragStart: (details) =>
                  onPointSelected!(_nearestIndex(details.localPosition.dx, width)),
              onHorizontalDragUpdate: (details) =>
                  onPointSelected!(_nearestIndex(details.localPosition.dx, width)),
              child: chart,
            ),
          );
        },
      ),
    );
  }
}

class _SplinePainter extends CustomPainter {
  _SplinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColors,
    required this.gridColor,
    required this.dotCenterColor,
    required this.tooltipBgColor,
    required this.tooltipTextColor,
    required this.textDirection,
    this.activePointIndex,
    this.activePointLabel,
    this.showDots = true,
  });

  final List<double> values;
  final Color lineColor;
  final List<Color> fillColors;
  final Color gridColor;
  final Color dotCenterColor;
  final Color tooltipBgColor;
  final Color tooltipTextColor;
  final TextDirection textDirection;
  final int? activePointIndex;
  final String? activePointLabel;
  final bool showDots;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const topPad = 32.0;
    const bottomPad = 14.0;
    const hPad = 10.0;
    final usableHeight = math.max(12.0, size.height - topPad - bottomPad);
    final usableWidth = math.max(12.0, size.width - hPad * 2);

    // Subtle horizontal grid rules (High / Mid / Low)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;
    for (final factor in [0.0, 0.5, 1.0]) {
      final y = topPad + usableHeight * factor;
      canvas.drawLine(
        Offset(hPad, y),
        Offset(size.width - hPad, y),
        gridPaint,
      );
    }

    final points = <Offset>[];
    final stepX = values.length > 1 ? usableWidth / (values.length - 1) : 0.0;

    for (int i = 0; i < values.length; i++) {
      final val = values[i].clamp(0.0, 1.0);
      final dx = values.length > 1 ? hPad + i * stepX : size.width / 2;
      final dy = topPad + usableHeight - (val * usableHeight);
      points.add(Offset(dx, dy));
    }

    if (points.length == 1) {
      _drawDot(canvas, points.first, true);
      if (activePointLabel != null) {
        _drawTooltip(canvas, size, points.first, activePointLabel!);
      }
      return;
    }

    final linePath = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, topPad + usableHeight)
      ..lineTo(points.first.dx, topPad + usableHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: fillColors,
      ).createShader(Rect.fromLTWH(0, topPad, size.width, usableHeight));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final activeIdx = activePointIndex ?? (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final isTarget = i == activeIdx;
      if (showDots || isTarget) {
        _drawDot(canvas, points[i], isTarget);
      }
    }

    if (activePointLabel != null &&
        activeIdx >= 0 &&
        activeIdx < points.length) {
      _drawTooltip(canvas, size, points[activeIdx], activePointLabel!);
    }
  }

  void _drawDot(Canvas canvas, Offset center, bool isTarget) {
    if (isTarget) {
      canvas.drawCircle(
        center,
        9.0,
        Paint()..color = lineColor.withValues(alpha: 0.22),
      );
      canvas.drawCircle(center, 5.0, Paint()..color = dotCenterColor);
      canvas.drawCircle(
        center,
        5.0,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke,
      );
    } else {
      canvas.drawCircle(center, 3.0, Paint()..color = dotCenterColor);
      canvas.drawCircle(
        center,
        3.0,
        Paint()
          ..color = lineColor.withValues(alpha: 0.65)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawTooltip(
    Canvas canvas,
    Size size,
    Offset target,
    String label,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
          fontFeatures: const [FontFeature.tabularFigures()],
          color: tooltipTextColor,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    final tooltipW = textPainter.width + 18;
    const tooltipH = 24.0;
    final maxX = math.max(4.0, size.width - tooltipW - 4.0);
    final tooltipX = (target.dx - tooltipW / 2).clamp(4.0, maxX);
    final tooltipY = (target.dy - 9.0 - tooltipH).clamp(2.0, size.height - tooltipH);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipX, tooltipY, tooltipW, tooltipH),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = tooltipBgColor);

    textPainter.paint(
      canvas,
      Offset(
        tooltipX + 9,
        tooltipY + (tooltipH - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SplinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.activePointIndex != activePointIndex ||
        oldDelegate.activePointLabel != activePointLabel ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.tooltipBgColor != tooltipBgColor ||
        oldDelegate.textDirection != textDirection;
  }
}
