import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/mind_tokens.dart';
import 'mind_pressable.dart';

/// Tactile, tap-first 1-10 intensity scale replacing narrow bar sliders.
///
/// Renders two balanced 5-pill rows (`1-5` / `6-10`) with progressive soft
/// fill up to [value], minimum 48dp touch height, tabular numerals, and
/// optional localized calm/overwhelmed scale anchors.
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final selected = value.clamp(1, 10);
    final activeColor = accentColor ?? tokens.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRow(
          levels: const [1, 2, 3, 4, 5],
          selected: selected,
          activeColor: activeColor,
          tokens: tokens,
          reduceMotion: reduceMotion,
        ),
        const SizedBox(height: 6),
        _buildRow(
          levels: const [6, 7, 8, 9, 10],
          selected: selected,
          activeColor: activeColor,
          tokens: tokens,
          reduceMotion: reduceMotion,
        ),
        if (showEdgeAnchors) ...[
          const SizedBox(height: 8),
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

  Widget _buildRow({
    required List<int> levels,
    required int selected,
    required Color activeColor,
    required MindTokens tokens,
    required bool reduceMotion,
  }) {
    return Row(
      children: [
        for (int i = 0; i < levels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _IntensityPill(
              level: levels[i],
              isSelected: levels[i] == selected,
              isFilled: levels[i] < selected,
              activeColor: activeColor,
              tokens: tokens,
              reduceMotion: reduceMotion,
              semanticLabel:
                  '${strings.moodIntensityLabel} ${levels[i]}/10 (${strings.intensityLevelWord(levels[i])})',
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(levels[i]);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _IntensityPill extends StatelessWidget {
  const _IntensityPill({
    required this.level,
    required this.isSelected,
    required this.isFilled,
    required this.activeColor,
    required this.tokens,
    required this.reduceMotion,
    required this.semanticLabel,
    required this.onTap,
  });

  final int level;
  final bool isSelected;
  final bool isFilled;
  final Color activeColor;
  final MindTokens tokens;
  final bool reduceMotion;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isSelected
        ? activeColor.withValues(alpha: 0.18)
        : (isFilled
            ? activeColor.withValues(alpha: 0.07)
            : tokens.surfaceSecondary);
    final borderColor = isSelected
        ? activeColor
        : (isFilled ? activeColor.withValues(alpha: 0.28) : tokens.border);

    return Semantics(
      selected: isSelected,
      child: MindPressable(
        key: ValueKey<String>('intensity-level-$level'),
        semanticLabel: semanticLabel,
        borderRadius: BorderRadius.circular(12),
        onPressed: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Text(
            '$level',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: isSelected
                  ? FontWeight.w700
                  : (isFilled ? FontWeight.w600 : FontWeight.w500),
              color: isSelected || isFilled
                  ? tokens.textPrimary
                  : tokens.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

