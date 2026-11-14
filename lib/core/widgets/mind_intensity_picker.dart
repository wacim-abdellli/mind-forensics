import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Expressive, low-cognitive-load 1-10 intensity picker.
///
/// Combines five custom-drawn minimalist vector faces (zero Unicode emojis)
/// representing Light through Overwhelming states with a fine 10-step
/// graduated equalizer capsule (`-`, swipe/tap waveform bars, `+`) so users
/// can pick either a broad feeling tier in one tap or fine-tune 1-10.
class MindIntensityPicker extends StatelessWidget {
  const MindIntensityPicker({
    super.key,
    required this.value,
    required this.strings,
    required this.onChanged,
    this.accentColor,
    this.showEdgeAnchors = true,
  });

  final int value;
  final AppStrings strings;
  final ValueChanged<int> onChanged;
  final Color? accentColor;
  final bool showEdgeAnchors;

  static const List<_IntensityTierSpec> _tiers = <_IntensityTierSpec>[
    _IntensityTierSpec(tierIndex: 0, min: 1, max: 2, entryValue: 1, label: '1-2'),
    _IntensityTierSpec(tierIndex: 1, min: 3, max: 4, entryValue: 3, label: '3-4'),
    _IntensityTierSpec(tierIndex: 2, min: 5, max: 6, entryValue: 5, label: '5-6'),
    _IntensityTierSpec(tierIndex: 3, min: 7, max: 8, entryValue: 8, label: '7-8'),
    _IntensityTierSpec(tierIndex: 4, min: 9, max: 10, entryValue: 10, label: '9-10'),
  ];

  void _emit(int current, int next) {
    final clamped = next.clamp(1, 10);
    if (clamped != current) {
      onChanged(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final selected = value.clamp(1, 10);
    final activeColor = accentColor ?? tokens.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = constraints.maxWidth < 290 ? 4.0 : 6.0;
            return Row(
              children: [
                for (int i = 0; i < _tiers.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(
                    child: _ExpressiveTierCard(
                      spec: _tiers[i],
                      isSelected: selected >= _tiers[i].min && selected <= _tiers[i].max,
                      activeColor: activeColor,
                      tokens: tokens,
                      reduceMotion: reduceMotion,
                      semanticLabel:
                          '${strings.moodIntensityLabel} ${_tiers[i].min}-${_tiers[i].max}/10 (${strings.intensityLevelWord(_tiers[i].entryValue)})',
                      onTap: () {
                        final spec = _tiers[i];
                        if (selected >= spec.min && selected <= spec.max) {
                          return;
                        }
                        onChanged(spec.entryValue);
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        _PrecisionEqualizerCapsule(
          selected: selected,
          activeColor: activeColor,
          tokens: tokens,
          strings: strings,
          reduceMotion: reduceMotion,
          onChanged: (next) => _emit(selected, next),
        ),
        if (showEdgeAnchors) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    strings.calmScaleAnchor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    strings.overwhelmedScaleAnchor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _IntensityTierSpec {
  const _IntensityTierSpec({
    required this.tierIndex,
    required this.min,
    required this.max,
    required this.entryValue,
    required this.label,
  });

  final int tierIndex;
  final int min;
  final int max;
  final int entryValue;
  final String label;
}

class _ExpressiveTierCard extends StatelessWidget {
  const _ExpressiveTierCard({
    required this.spec,
    required this.isSelected,
    required this.activeColor,
    required this.tokens,
    required this.reduceMotion,
    required this.semanticLabel,
    required this.onTap,
  });

  final _IntensityTierSpec spec;
  final bool isSelected;
  final Color activeColor;
  final MindTokens tokens;
  final bool reduceMotion;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isSelected
        ? activeColor.withValues(alpha: 0.14)
        : tokens.surfaceSecondary.withValues(alpha: 0.72);
    final borderColor = isSelected ? activeColor : tokens.border;
    final badgeFill = isSelected
        ? activeColor.withValues(alpha: 0.20)
        : tokens.surface;
    final badgeBorder = isSelected ? activeColor : tokens.border;
    final strokeColor = isSelected ? tokens.textPrimary : tokens.textSecondary;

    return Semantics(
      selected: isSelected,
      child: MindPressable(
        key: ValueKey<String>('intensity-tier-${spec.tierIndex + 1}'),
        semanticLabel: semanticLabel,
        borderRadius: BorderRadius.circular(16),
        pressScale: 0.96,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 62),
          // Compensate 1.0px vs 1.5px border width so pill Rect stays invariant.
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 2.5 : 3.0,
            vertical: isSelected ? 7.5 : 8.0,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: reduceMotion ? 1.0 : (isSelected ? 1.06 : 1.0),
                duration:
                    reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CustomPaint(
                    painter: _ExpressiveFacePainter(
                      tier: spec.tierIndex,
                      badgeFill: badgeFill,
                      badgeBorder: badgeBorder,
                      strokeColor: strokeColor,
                      isSelected: isSelected,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  spec.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? tokens.textPrimary : tokens.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrecisionEqualizerCapsule extends StatelessWidget {
  const _PrecisionEqualizerCapsule({
    required this.selected,
    required this.activeColor,
    required this.tokens,
    required this.strings,
    required this.reduceMotion,
    required this.onChanged,
  });

  final int selected;
  final Color activeColor;
  final MindTokens tokens;
  final AppStrings strings;
  final bool reduceMotion;
  final ValueChanged<int> onChanged;

  int _levelFromLocalDx({
    required double dx,
    required double width,
    required TextDirection direction,
  }) {
    if (width <= 0) return selected;
    var ratio = (dx / width).clamp(0.0, 0.9999);
    if (direction == TextDirection.rtl) {
      ratio = 1.0 - ratio;
    }
    return (ratio * 10).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final animDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 140);

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: tokens.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: MindPressable(
              key: const ValueKey<String>('intensity-step-down'),
              enabled: selected > 1,
              semanticLabel: strings.intensityDecreaseLabel,
              borderRadius: BorderRadius.circular(15),
              onPressed: selected > 1 ? () => onChanged(selected - 1) : null,
              child: Center(
                child: Icon(
                  Icons.remove_rounded,
                  size: 18,
                  color: selected > 1 ? tokens.textPrimary : tokens.textTertiary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              container: true,
              slider: true,
              label: strings.moodIntensityLabel,
              value: '$selected/10 ${strings.intensityLevelWord(selected)}',
              increasedValue: selected < 10 ? '${selected + 1}/10' : null,
              decreasedValue: selected > 1 ? '${selected - 1}/10' : null,
              onIncrease: selected < 10 ? () => onChanged(selected + 1) : null,
              onDecrease: selected > 1 ? () => onChanged(selected - 1) : null,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  void updateFromDx(double dx) {
                    final next = _levelFromLocalDx(
                      dx: dx,
                      width: constraints.maxWidth,
                      direction: direction,
                    );
                    if (next != selected) {
                      HapticFeedback.selectionClick();
                      onChanged(next);
                    }
                  }

                  return GestureDetector(
                    key: const ValueKey<String>('intensity-equalizer'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => updateFromDx(details.localPosition.dx),
                    onHorizontalDragStart: (details) =>
                        updateFromDx(details.localPosition.dx),
                    onHorizontalDragUpdate: (details) =>
                        updateFromDx(details.localPosition.dx),
                    child: SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            for (int level = 1; level <= 10; level++)
                              Expanded(
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: animDuration,
                                    curve: Curves.easeOutCubic,
                                    width: level == selected ? 6.0 : 4.5,
                                    height: (10.0 + (level - 1) * 1.3) +
                                        (level == selected ? 3.5 : 0.0),
                                    decoration: BoxDecoration(
                                      color: level == selected
                                          ? activeColor
                                          : (level < selected
                                              ? activeColor.withValues(
                                                  alpha: 0.38 + (level / 10) * 0.34,
                                                )
                                              : tokens.border),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: MindPressable(
              key: const ValueKey<String>('intensity-step-up'),
              enabled: selected < 10,
              semanticLabel: strings.intensityIncreaseLabel,
              borderRadius: BorderRadius.circular(15),
              onPressed: selected < 10 ? () => onChanged(selected + 1) : null,
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: selected < 10 ? tokens.textPrimary : tokens.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bespoke minimalist vector face painter (0 Unicode characters / 0 emojis).
class _ExpressiveFacePainter extends CustomPainter {
  const _ExpressiveFacePainter({
    required this.tier,
    required this.badgeFill,
    required this.badgeBorder,
    required this.strokeColor,
    required this.isSelected,
  });

  final int tier;
  final Color badgeFill;
  final Color badgeBorder;
  final Color strokeColor;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 1.2;

    final fillPaint = Paint()
      ..color = badgeFill
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    final borderPaint = Paint()
      ..color = badgeBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.5 : 1.0;
    canvas.drawCircle(center, radius, borderPaint);

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.75 : 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    switch (tier) {
      case 0:
        // Tier 1 (Light): peaceful closed arches + calm serene smile
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx - radius * 0.34, center.dy - radius * 0.08),
            width: radius * 0.32,
            height: radius * 0.24,
          ),
          math.pi * 1.12,
          math.pi * 0.76,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx + radius * 0.34, center.dy - radius * 0.08),
            width: radius * 0.32,
            height: radius * 0.24,
          ),
          math.pi * 1.12,
          math.pi * 0.76,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + radius * 0.14),
            width: radius * 0.72,
            height: radius * 0.56,
          ),
          math.pi * 0.16,
          math.pi * 0.68,
          false,
          stroke,
        );
        break;

      case 1:
        // Tier 2 (Mild): soft open eyes + gentle calm smile
        canvas.drawCircle(
          Offset(center.dx - radius * 0.34, center.dy - radius * 0.15),
          radius * 0.10,
          dotPaint,
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.34, center.dy - radius * 0.15),
          radius * 0.10,
          dotPaint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + radius * 0.14),
            width: radius * 0.62,
            height: radius * 0.44,
          ),
          math.pi * 0.20,
          math.pi * 0.60,
          false,
          stroke,
        );
        break;

      case 2:
        // Tier 3 (Moderate): balanced open eyes + steady horizontal mouth
        canvas.drawCircle(
          Offset(center.dx - radius * 0.34, center.dy - radius * 0.15),
          radius * 0.10,
          dotPaint,
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.34, center.dy - radius * 0.15),
          radius * 0.10,
          dotPaint,
        );
        canvas.drawLine(
          Offset(center.dx - radius * 0.28, center.dy + radius * 0.28),
          Offset(center.dx + radius * 0.28, center.dy + radius * 0.28),
          stroke,
        );
        break;

      case 3:
        // Tier 4 (Strong): slightly furrowed brows + gentle downturn arch
        canvas.drawLine(
          Offset(center.dx - radius * 0.44, center.dy - radius * 0.38),
          Offset(center.dx - radius * 0.18, center.dy - radius * 0.28),
          stroke,
        );
        canvas.drawLine(
          Offset(center.dx + radius * 0.44, center.dy - radius * 0.38),
          Offset(center.dx + radius * 0.18, center.dy - radius * 0.28),
          stroke,
        );
        canvas.drawCircle(
          Offset(center.dx - radius * 0.32, center.dy - radius * 0.08),
          radius * 0.095,
          dotPaint,
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.32, center.dy - radius * 0.08),
          radius * 0.095,
          dotPaint,
        );
        final frown = Path()
          ..moveTo(center.dx - radius * 0.28, center.dy + radius * 0.34)
          ..quadraticBezierTo(
            center.dx,
            center.dy + radius * 0.16,
            center.dx + radius * 0.28,
            center.dy + radius * 0.34,
          );
        canvas.drawPath(frown, stroke);
        break;

      case 4:
      default:
        // Tier 5 (Overwhelming): deeper angled brows + wavy tense mouth
        canvas.drawLine(
          Offset(center.dx - radius * 0.46, center.dy - radius * 0.42),
          Offset(center.dx - radius * 0.15, center.dy - radius * 0.26),
          stroke,
        );
        canvas.drawLine(
          Offset(center.dx + radius * 0.46, center.dy - radius * 0.42),
          Offset(center.dx + radius * 0.15, center.dy - radius * 0.26),
          stroke,
        );
        canvas.drawCircle(
          Offset(center.dx - radius * 0.32, center.dy - radius * 0.06),
          radius * 0.095,
          dotPaint,
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.32, center.dy - radius * 0.06),
          radius * 0.095,
          dotPaint,
        );
        final wave = Path()
          ..moveTo(center.dx - radius * 0.36, center.dy + radius * 0.30)
          ..quadraticBezierTo(
            center.dx - radius * 0.18,
            center.dy + radius * 0.14,
            center.dx,
            center.dy + radius * 0.30,
          )
          ..quadraticBezierTo(
            center.dx + radius * 0.18,
            center.dy + radius * 0.46,
            center.dx + radius * 0.36,
            center.dy + radius * 0.30,
          );
        canvas.drawPath(wave, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ExpressiveFacePainter oldDelegate) {
    return tier != oldDelegate.tier ||
        badgeFill != oldDelegate.badgeFill ||
        badgeBorder != oldDelegate.badgeBorder ||
        strokeColor != oldDelegate.strokeColor ||
        isSelected != oldDelegate.isSelected;
  }
}
