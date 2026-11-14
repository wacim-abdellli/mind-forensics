import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../investigation/domain/label_type.dart';

/// Interactive Fact / Guess / Story cognitive triage drill merged into
/// Reframe Thought and Self-Care Tools.
///
/// Uses non-color cues (icon + label + border weight) and enforces >= 48dp targets.
class ReframeDrillCard extends ConsumerStatefulWidget {
  const ReframeDrillCard({super.key});

  @override
  ConsumerState<ReframeDrillCard> createState() => _ReframeDrillCardState();
}

class _ReframeDrillCardState extends ConsumerState<ReframeDrillCard> {
  int _drillIndex = 0;
  LabelType? _selectedAnswer;
  bool _answered = false;

  static List<({String statement, LabelType correct, String explanation})>
      _getDrills(String lang) {
    if (lang == 'ar') {
      return const [
        (
          statement: '“ما جاوبنيش على الميساج متاعي عندو 4 سوايع.”',
          correct: LabelType.fact,
          explanation:
              'هذي واقعة ملموسة ومثبتة في الوقت، أي إنسان ينجم يشوفها ويثبت فيها.',
        ),
        (
          statement: '“هو يتهرب مني خاطري قلت كلمة غالطة.”',
          correct: LabelType.assumption,
          explanation:
              'هذا تخمين لنوايا الطرف الآخر من غير أي دليل حقيقي أو تأكيد مباشر.',
        ),
        (
          statement: '“أنا إنسان فاشل وعمري ما نصلح في علاقاتي.”',
          correct: LabelType.interpretation,
          explanation:
              'هذا حكم قاسي وتأويل مدمر ألقيته على روحك انطلاقاً من مجرد موقف.',
        ),
        (
          statement: '“المسؤول في الخدمة طلب تعديلات على التقرير.”',
          correct: LabelType.fact,
          explanation:
              'حدث واقعي طبيعي في سياق العمل، وطلب الملاحظات ماهوش دليل على فشلك.',
        ),
        (
          statement: '“البريزونتاسيون متاعي كانت كارثة ومصيبة كاملة.”',
          correct: LabelType.interpretation,
          explanation:
              'تضخيم كارثي: إلصاق صفة سلبية قاسية على عرض عادي يحتاج تحسين.',
        ),
      ];
    }
    if (lang == 'fr') {
      return const [
        (
          statement: '« Il n’a pas répondu à mon message depuis 4 heures. »',
          correct: LabelType.fact,
          explanation:
              'C’est un fait objectif et vérifiable que n’importe quel observateur peut constater.',
        ),
        (
          statement: '« Il m’évite parce que j’ai dit quelque chose de stupide. »',
          correct: LabelType.assumption,
          explanation:
              'Vous présumez de ses intentions secrètes sans aucune preuve factuelle.',
        ),
        (
          statement: '« Je suis nul et je gâche toujours mes relations. »',
          correct: LabelType.interpretation,
          explanation:
              'C’est un récit personnel sévère et dévalorisant plaqué sur une situation.',
        ),
        (
          statement:
              '« Le responsable a demandé des modifications sur la présentation. »',
          correct: LabelType.fact,
          explanation:
              'Un événement professionnel courant. Demander des retouches n’est pas un signe d’échec.',
        ),
        (
          statement: '« Ma présentation a été une catastrophe absolue. »',
          correct: LabelType.interpretation,
          explanation:
              'Dramatisation : étiquette émotionnelle extrême attribuée à une intervention ordinaire.',
        ),
      ];
    }
    return const [
      (
        statement: '“He didn’t reply to my message for 4 hours.”',
        correct: LabelType.fact,
        explanation:
            'This is an objective, verifiable event that can be clocked and observed by anyone.',
      ),
      (
        statement: '“He is avoiding me because I said something stupid.”',
        correct: LabelType.assumption,
        explanation:
            'This assumes his private motivations without factual evidence or confirmation.',
      ),
      (
        statement: '“I am unlovable and always ruin my relationships.”',
        correct: LabelType.interpretation,
        explanation:
            'This is a harsh personal narrative assigned onto a situational outcome.',
      ),
      (
        statement: '“The manager requested changes on the slide deck.”',
        correct: LabelType.fact,
        explanation:
            'A clear factual occurrence. Requesting edits is standard workflow, not proof of failure.',
      ),
      (
        statement: '“My presentation was a complete catastrophe.”',
        correct: LabelType.interpretation,
        explanation:
            'Catastrophizing: projecting an extreme negative emotional label on a normal presentation.',
      ),
    ];
  }

  static IconData _iconFor(LabelType type) {
    switch (type) {
      case LabelType.fact:
        return Icons.check_circle_outline_rounded;
      case LabelType.assumption:
        return Icons.help_outline_rounded;
      case LabelType.interpretation:
        return Icons.auto_stories_outlined;
    }
  }

  void _nextDrill(int totalDrills) {
    HapticFeedback.lightImpact();
    setState(() {
      _drillIndex = (_drillIndex + 1) % totalDrills;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final locale = ref.watch(localeControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final drills = _getDrills(locale.languageCode);
    final current = drills[_drillIndex % drills.length];
    final isCorrectChoice = _selectedAnswer == current.correct;

    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.practiceLabelingTitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.practiceLabelingSub,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: tokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.border),
                ),
                child: Text(
                  '${(_drillIndex % drills.length) + 1} / ${drills.length}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.surfaceSecondary,
              borderRadius: BorderRadius.circular(tokens.chipRadius),
              border: Border.all(color: tokens.border),
            ),
            child: Text(
              current.statement,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                height: 1.45,
                color: tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in LabelType.values)
                _buildOptionChip(
                  label: label,
                  correctAnswer: current.correct,
                  tokens: tokens,
                  strings: strings,
                ),
            ],
          ),
          if (_answered) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrectChoice
                    ? tokens.accentSoft
                    : tokens.surfaceSecondary,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                border: Border.all(
                  color: isCorrectChoice
                      ? tokens.accent.withValues(alpha: 0.45)
                      : tokens.border,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      isCorrectChoice
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                      color: isCorrectChoice
                          ? tokens.accent
                          : tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCorrectChoice
                              ? strings.drillCorrectBanner
                              : '${strings.drillHintPrefix} ${strings.localizedLabelName(current.correct)}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          current.explanation,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            height: 1.4,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: MindPressable(
                onPressed: () => _nextDrill(drills.length),
                semanticLabel: strings.nextDrill,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          strings.nextDrill,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: tokens.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required LabelType label,
    required LabelType correctAnswer,
    required MindTokens tokens,
    required AppStrings strings,
  }) {
    final isSelected = _selectedAnswer == label;
    final isCorrect = label == correctAnswer;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Color bg = tokens.surfaceSecondary;
    Color border = tokens.border;
    Color fg = tokens.textPrimary;

    if (_answered) {
      if (isCorrect) {
        bg = tokens.accentSoft;
        border = tokens.accent;
        fg = tokens.accent;
      } else if (isSelected) {
        bg = tokens.safetyWarmthSoft;
        border = tokens.safetyWarmth;
        fg = tokens.safetyWarmth;
      } else {
        fg = tokens.textSecondary;
      }
    } else if (isSelected) {
      bg = tokens.accentSoft;
      border = tokens.accent;
      fg = tokens.accent;
    }

    final displayName = strings.localizedLabelName(label);

    return Semantics(
      button: true,
      selected: isSelected,
      label: displayName,
      child: MindPressable(
        onPressed: _answered
            ? null
            : () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedAnswer = label;
                  _answered = true;
                });
              },
        borderRadius: BorderRadius.circular(tokens.chipRadius),
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(tokens.chipRadius),
            border: Border.all(
              color: border,
              width: isSelected || (_answered && isCorrect) ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(label), size: 17, color: fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: isSelected || (_answered && isCorrect)
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: fg,
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
