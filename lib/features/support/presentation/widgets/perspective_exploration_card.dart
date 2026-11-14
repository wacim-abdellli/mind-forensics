import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/lab_colors.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../../core/widgets/mind_card.dart';
import '../../../../core/widgets/mind_pressable.dart';
import '../../../investigation/domain/label_type.dart';
import '../../../observatory/presentation/widgets/custom_perspective_sheet.dart';

/// Perspective Exploration Card:
/// - Replaces rigid cognitive distortion quiz with empowering thought deconstruction
/// - Helps users distinguish: What happened vs. What was assumed vs. Other possibilities
/// - Options-first, zero compulsory essay writing, 0 emojis
class PerspectiveExplorationCard extends ConsumerStatefulWidget {
  const PerspectiveExplorationCard({super.key});

  @override
  ConsumerState<PerspectiveExplorationCard> createState() =>
      _PerspectiveExplorationCardState();
}

class _PerspectiveExplorationCardState
    extends ConsumerState<PerspectiveExplorationCard> {
  int _scenarioIndex = 0;

  final List<Map<String, dynamic>> _scenarios = [
    {
      'fact': 'Unanswered text message for 3 hours.',
      'factAr': 'ميساج بقى من غير إجابة لمدة 3 سوايع.',
      'factFr': 'Message resté sans réponse depuis 3 heures.',
      'thought': '“They are upset with me and deliberately ignoring me.”',
      'thoughtAr': '“هو متغشش مني وقاعد يتجاهل فيا بالعاني.”',
      'thoughtFr': '« Il m’en veut et m’ignore délibérément. »',
      'label': LabelType.assumption,
      'alternatives': [
        'They are absorbed in deep work, a meeting, or driving.',
        'Their battery is flat or they read it and intended to reply properly later.',
        'Their silence reflects their own busy day, not a judgment on you.',
      ],
      'alternativesAr': [
        'لاهي في خدمة، اجتماع، أو يسوق في الكرهبة.',
        'التليفون طاح شارج أو شاف الميساج وحب يجاوبك في عقلو.',
        'الصمت متاعو يخص نهارو وضغطو هو، موش حكم عليك.',
      ],
      'alternativesFr': [
        'La personne est en réunion, au travail ou sur la route.',
        'Son téléphone n’a plus de batterie ou elle préfère répondre au calme.',
        'Ce silence reflète sa propre journée chargée, pas un rejet.',
      ],
    },
    {
      'fact': 'Manager requested revisions on section 2 of the presentation.',
      'factAr': 'المسؤول طلب تعديلات على الجزء الثاني من العرض.',
      'factFr': 'Le responsable a demandé des modifications sur la partie 2.',
      'thought': '“My work was a complete disaster and I cannot deliver.”',
      'thoughtAr': '“الخدمة متاعي كارثة وما نعرف نعمل حتى شي صحيح.”',
      'thoughtFr': '« Tout mon travail est raté et je ne suis pas à la hauteur. »',
      'label': LabelType.interpretation,
      'alternatives': [
        'Feedback is a normal collaborative iteration, not a verdict on competence.',
        'The other sections were accepted without changes.',
        'Requesting clarity indicates confidence that the draft is worth refining.',
      ],
      'alternativesAr': [
        'طلب التعديل جزء طبيعي من العمل المشترك، ماهوش شهادة فشل.',
        'الأجزاء لخرين تقبلو من غير حتى ملاحظة.',
        'طلب التحسين يعكس ثقة في قدرتك على إتمامه.',
      ],
      'alternativesFr': [
        'Les retours font partie du travail normal, ce n’est pas un constat d’échec.',
        'Toutes les autres parties ont été validées sans remarque.',
        'Demander des ajustements montre que le document mérite d’être peaufiné.',
      ],
    },
    {
      'fact': 'Woke up feeling fatigued and unmotivated this morning.',
      'factAr': 'قمت الصباح تاعب وبدنك فاشل.',
      'factFr': 'Réveil avec de la fatigue et peu d’élan ce matin.',
      'thought': '“The whole day will be wasted and I am falling behind.”',
      'thoughtAr': '“النهار كامل ضاع وموش باش نوصل نعمل شي.”',
      'thoughtFr': '« Toute la journée est gâchée, je prends du retard. »',
      'label': LabelType.assumption,
      'alternatives': [
        'Energy fluctuates naturally throughout 24 hours; morning mood is not evening outcome.',
        'Resting or adjusting today’s pace preserves stamina.',
        'Accomplishing one manageable priority is enough for a low-energy day.',
      ],
      'alternativesAr': [
        'الطاقة تتبدل طبيعياً طيلة النهار؛ إحساس الصباح موش مصير النهار كامل.',
        'تعديل نسق النهار يخليك تحافظ على توازنك.',
        'إنجاز حاجة وحدة بسيطة يكفي في نهار طاقتك فيه ناقصة.',
      ],
      'alternativesFr': [
        'L’énergie varie au cours de la journée ; la matinée ne dicte pas le soir.',
        'Adapter son rythme aujourd’hui permet de préserver ses ressources.',
        'Accomplir une seule priorité accessible suffit amplement.',
      ],
    },
  ];

  void _nextScenario() {
    HapticFeedback.lightImpact();
    setState(() {
      _scenarioIndex = (_scenarioIndex + 1) % _scenarios.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strings = ref.watch(appStringsProvider);
    final isAr = strings.isArabic;
    final isFr = strings.isFrench;

    final textPrimary = tokens.textPrimary;
    final textSecondary = tokens.textSecondary;

    final scenario = _scenarios[_scenarioIndex];
    final fact = isAr
        ? scenario['factAr']
        : (isFr ? scenario['factFr'] : scenario['fact']);
    final thought = isAr
        ? scenario['thoughtAr']
        : (isFr ? scenario['thoughtFr'] : scenario['thought']);
    final alternatives = (isAr
        ? scenario['alternativesAr']
        : (isFr ? scenario['alternativesFr'] : scenario['alternatives'])) as List<String>;

    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.sectionPerspectiveExploration.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: isAr ? 0 : 0.7,
                    color: textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MindPressable(
                onPressed: _nextScenario,
                semanticLabel: isAr
                    ? 'مثال آخر'
                    : (isFr ? 'Autre exemple' : 'Next Example'),
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAr
                              ? 'مثال آخر'
                              : (isFr ? 'Autre exemple' : 'Next Example'),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: tokens.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. Observable Fact Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? LabColors.factBackgroundDark : LabColors.factBackgroundLight,
              borderRadius: BorderRadius.circular(tokens.chipRadius),
              border: Border.all(
                color: isDark ? LabColors.factBorderDark : LabColors.factBorderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'الواقعة الملموسة (FACT)'
                      : (isFr ? 'FAIT OBSERVABLE' : 'OBSERVABLE FACT'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: isAr ? 0 : 0.5,
                    color: LabColors.factBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fact as String,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Automatic Thought Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? LabColors.assumptionBackgroundDark : LabColors.assumptionBackgroundLight,
              borderRadius: BorderRadius.circular(tokens.chipRadius),
              border: Border.all(
                color: isDark ? LabColors.assumptionBorderDark : LabColors.assumptionBorderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'ما قفز إليه العقل (THOUGHT)'
                      : (isFr
                          ? 'INTERPRÉTATION AUTOMATIQUE'
                          : 'AUTOMATIC INTERPRETATION'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: isAr ? 0 : 0.5,
                    color: LabColors.assumptionAmber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  thought as String,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Grounded Alternative Interpretations
          Text(
            isAr
                ? 'احتمالات أخرى واقعية:'
                : (isFr
                    ? 'Autres possibilités fondées sur les faits :'
                    : 'Alternative grounded possibilities:'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: alternatives.map((alt) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: tokens.accentSoft,
                  borderRadius: BorderRadius.circular(tokens.chipRadius),
                  border: Border.all(
                    color: tokens.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: tokens.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alt,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.4,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          MindButton(
            text: isAr
                ? 'تفكيك فكرة أو موقف خاص بك'
                : (isFr
                    ? 'Explorer une de vos propres pensées'
                    : 'Deconstruct a thought of your own'),
            leadingIcon: Icons.tune_rounded,
            variant: MindButtonVariant.soft,
            isFullWidth: true,
            onPressed: () => CustomPerspectiveSheet.show(context),
          ),
        ],
      ),
    );
  }
}
