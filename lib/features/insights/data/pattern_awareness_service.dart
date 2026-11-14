import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/localization/app_strings.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../domain/pattern_divergence_model.dart';
import '../domain/personal_baseline_model.dart';

/// Pure computation service for detecting meaningful multi-day divergences
/// from the user's personal baseline.
///
/// Strictly abides by Part 7.2 & Clinical Guardrails:
/// - Never labels as mania, hypomania, or depression.
/// - Never predicts relapse.
/// - Clearly cites evidence and communicates uncertainty.
class PatternAwarenessService {
  static List<PatternDivergence> detectDivergences({
    required List<MindTraceModel> traces,
    required PersonalBaseline baseline,
  }) {
    if (!baseline.hasSufficientData || traces.length < 2) {
      return [];
    }

    final now = DateTime.now();
    final past3DaysCutoff = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 4));
    final recentTraces = traces.where((t) => !t.date.isBefore(past3DaysCutoff)).toList();

    if (recentTraces.length < 2) {
      return [];
    }

    recentTraces.sort((a, b) => a.date.compareTo(b.date));
    final List<PatternDivergence> divergences = [];

    // Telemetry extraction
    final recentSleeps = recentTraces
        .map((t) => t.sleepHours)
        .whereType<double>()
        .where((h) => h >= 0.0 && h <= 24.0)
        .toList();
    final recentAvgSleep = recentSleeps.isNotEmpty
        ? recentSleeps.reduce((a, b) => a + b) / recentSleeps.length
        : null;

    final recentEnergyValues = recentTraces
        .map((t) => t.energyLevel)
        .whereType<int>()
        .where((e) => e >= 1 && e <= 10)
        .toList();
    final recentAvgEnergy = recentEnergyValues.isNotEmpty
        ? recentEnergyValues.reduce((a, b) => a + b) / recentEnergyValues.length
        : null;

    final hasRacingThoughts = recentTraces.any((t) => (t.racingThoughts ?? 0) >= 6);

    final sleepDeficit = (baseline.averageSleepHours != null && recentAvgSleep != null)
        ? baseline.averageSleepHours! - recentAvgSleep
        : null;
    final energySurge = (baseline.averageEnergyLevel != null && recentAvgEnergy != null)
        ? recentAvgEnergy - baseline.averageEnergyLevel!
        : null;
    final energyDrop = (baseline.averageEnergyLevel != null && recentAvgEnergy != null)
        ? baseline.averageEnergyLevel! - recentAvgEnergy
        : null;

    // -------------------------------------------------------------------------
    // 1. Co-Occurring Combinations (Multi-Metric Shifts)
    // -------------------------------------------------------------------------
    // Combined Shift: Lower sleep co-occurring with elevated energy or racing thoughts
    if (sleepDeficit != null &&
        sleepDeficit >= 0.1 &&
        ((energySurge != null && energySurge >= 0.1) || hasRacingThoughts)) {
      final List<String> observations = [];
      observations.add(
        'Recorded sleep averaged ${recentAvgSleep!.toStringAsFixed(1)} hours across ${recentSleeps.length} nights (baseline: ${baseline.averageSleepHours!.toStringAsFixed(1)} hours across ${baseline.sleepObservationCount} nights).',
      );
      if (baseline.averageEnergyLevel != null && recentAvgEnergy != null) {
        observations.add(
          'Reported energy averaged ${recentAvgEnergy.toStringAsFixed(1)}/10 across ${recentEnergyValues.length} entries (baseline: ${baseline.averageEnergyLevel!.toStringAsFixed(1)}/10 across ${baseline.energyObservationCount} entries).',
        );
      }
      if (hasRacingThoughts) {
        final maxRacing = recentTraces
            .map((t) => t.racingThoughts ?? 0)
            .reduce((a, b) => a > b ? a : b);
        observations.add('Racing thoughts were rated at $maxRacing/10 on a recent check-in.');
      }

      final energyClause = (energySurge != null && energySurge >= 0.1)
          ? 'reported energy is higher by ${energySurge.toStringAsFixed(1)} points'
          : 'energy ratings remain steady with your baseline';

      divergences.add(
        PatternDivergence(
          id: 'div_activation_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.elevatedActivation,
          observationType: ObservationType.combinedMetricShift,
          title: 'Shift in Energy & Sleep: Combined Ratings',
          timeWindow: 'Past 3–4 days',
          contributingObservations: observations,
          baselineComparison:
              'Sleep is lower by ${sleepDeficit.toStringAsFixed(1)}h while $energyClause compared to your usual baseline.',
          uncertaintyStatement:
              'This observation reflects numbers and sensations you logged. It is an exploration of pattern shifts, not a clinical diagnosis or confirmed episode.',
          userCheckInQuestion:
              'Do you recognize this increase in energy and reduced rest in your routine over the last few days?',
          supportPlanPrompt:
              'Consider reviewing your personal early-warning signs, evening wind-down routine, or calming activities.',
          therapistPrompt:
              'If you feel ungrounded or this pattern continues, reviewing these logs with your doctor or therapist could be helpful.',
          detectedAt: now,
        ),
      );
    }

    // Combined Shift: Lower energy co-occurring with lower mood or heavy mood descriptors
    final recentIntensities = recentTraces.map((t) => t.moodIntensity).toList();
    final recentAvgIntensity = recentIntensities.isNotEmpty
        ? recentIntensities.reduce((a, b) => a + b) / recentIntensities.length
        : null;
    final hasHeavyOrLowMood = recentTraces.any((t) => t.overallMood == 'heavy' || t.overallMood == 'frustrated');
    final moodDrop = (baseline.averageMoodIntensity != null && recentAvgIntensity != null)
        ? baseline.averageMoodIntensity! - recentAvgIntensity
        : null;

    if (energyDrop != null &&
        energyDrop >= 0.1 &&
        ((moodDrop != null && moodDrop >= 0.1) || hasHeavyOrLowMood)) {
      final List<String> observations = [
        'Reported energy averaged ${recentAvgEnergy!.toStringAsFixed(1)}/10 across ${recentEnergyValues.length} entries (baseline: ${baseline.averageEnergyLevel!.toStringAsFixed(1)}/10 across ${baseline.energyObservationCount} entries).',
      ];
      if (moodDrop != null && moodDrop >= 0.1) {
        observations.add(
          'Mood intensity averaged ${recentAvgIntensity!.toStringAsFixed(1)}/10 (lower by ${moodDrop.toStringAsFixed(1)} points compared to your baseline of ${baseline.averageMoodIntensity!.toStringAsFixed(1)}/10 across ${baseline.moodObservationCount} entries).',
        );
      }
      if (hasHeavyOrLowMood) {
        observations.add('Recorded mood state reflected lower energy or heavier sensations across recent entries.');
      }

      divergences.add(
        PatternDivergence(
          id: 'div_low_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.lowActivation,
          observationType: ObservationType.combinedMetricShift,
          title: 'Drop in Energy & Mood: Combined Ratings',
          timeWindow: 'Past 3–4 days',
          contributingObservations: observations,
          baselineComparison:
              'Energy is lower by ${energyDrop.toStringAsFixed(1)} points compared to your 30-day baseline.',
          uncertaintyStatement:
              'Fluctuations in vitality and mood are a natural part of living. This observation highlights a dip from your typical level.',
          userCheckInQuestion:
              'Have you been feeling drained, carrying extra weight, or feeling less motivated lately?',
          supportPlanPrompt:
              'Gentle pacing, prioritizing basic rest, and small manageable steps can help without putting pressure on yourself.',
          therapistPrompt:
              'If this feeling persists, bringing this observation to your therapist can provide support tailored to your needs.',
          detectedAt: now,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 2. Independent Metric Differences (Never Hidden by Other Metrics)
    // -------------------------------------------------------------------------
    // Independent Sleep difference: reported regardless of energy level
    final alreadyHasCombinedSleep = divergences.any((d) => d.category == DivergenceCategory.elevatedActivation);
    if (!alreadyHasCombinedSleep && sleepDeficit != null && sleepDeficit.abs() >= 0.1) {
      divergences.add(
        PatternDivergence(
          id: 'div_sleep_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.sleepDisruption,
          observationType: ObservationType.individualMetricShift,
          title: 'Observed Difference in Sleep Duration',
          timeWindow: 'Past 3–4 days',
          contributingObservations: [
            'Recorded sleep averaged ${recentAvgSleep!.toStringAsFixed(1)} hours across ${recentSleeps.length} nights (baseline: ${baseline.averageSleepHours!.toStringAsFixed(1)} hours across ${baseline.sleepObservationCount} nights).',
          ],
          baselineComparison:
              'Sleep averaged ${recentAvgSleep.toStringAsFixed(1)}h (${sleepDeficit > 0 ? "lower" : "higher"} by ${sleepDeficit.abs().toStringAsFixed(1)}h compared to your baseline of ${baseline.averageSleepHours!.toStringAsFixed(1)}h).',
          uncertaintyStatement:
              'Sleep variations can stem from scheduling, environment, or temporary stress.',
          userCheckInQuestion:
              'How has your sleep schedule felt over these past few nights?',
          supportPlanPrompt:
              'Evening wind-down rituals, minimizing screen exposure, or resting without sleep pressure may be helpful.',
          therapistPrompt: null,
          detectedAt: now,
        ),
      );
    }

    // Independent Energy difference: reported regardless of mood
    final alreadyHasCombinedEnergy = divergences.any((d) => d.category == DivergenceCategory.lowActivation || d.category == DivergenceCategory.elevatedActivation);
    if (!alreadyHasCombinedEnergy && energyDrop != null && energyDrop.abs() >= 0.1) {
      divergences.add(
        PatternDivergence(
          id: 'div_energy_${now.millisecondsSinceEpoch}',
          category: energyDrop > 0 ? DivergenceCategory.lowActivation : DivergenceCategory.generalVariation,
          observationType: ObservationType.individualMetricShift,
          title: 'Observed Difference in Energy Level',
          timeWindow: 'Past 3–4 days',
          contributingObservations: [
            'Reported energy averaged ${recentAvgEnergy!.toStringAsFixed(1)}/10 across ${recentEnergyValues.length} entries (baseline: ${baseline.averageEnergyLevel!.toStringAsFixed(1)}/10 across ${baseline.energyObservationCount} entries).',
          ],
          baselineComparison:
              'Energy is ${energyDrop > 0 ? "lower" : "higher"} by ${energyDrop.abs().toStringAsFixed(1)} points compared to your baseline.',
          uncertaintyStatement:
              'Fluctuations in vitality and daily energy are normal bodily variations.',
          userCheckInQuestion:
              'Are you noticing changes in your daily energy or stamina?',
          supportPlanPrompt:
              'Consider gentle pacing and prioritizing basic nourishment and rest.',
          therapistPrompt: null,
          detectedAt: now,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // 3. Multi-Day Observations vs Single Observations (Physical Tension & Anxiety)
    // -------------------------------------------------------------------------
    final highTensionDays = recentTraces.where((t) => (t.physicalTension ?? 0) >= 7).length;
    final highAnxietyDays = recentTraces.where((t) => (t.anxietyLevel ?? 0) >= 7).length;

    if (highTensionDays > 0 || highAnxietyDays > 0) {
      final isMultiDay = highTensionDays >= 2 || highAnxietyDays >= 2;
      final daysCount = highTensionDays > highAnxietyDays ? highTensionDays : highAnxietyDays;
      divergences.add(
        PatternDivergence(
          id: 'div_tension_${now.millisecondsSinceEpoch}',
          category: DivergenceCategory.elevatedTension,
          observationType: isMultiDay ? ObservationType.longitudinalPattern : ObservationType.individualMetricShift,
          title: isMultiDay
              ? 'Physical Tension or Stress Noted Across $daysCount Days'
              : 'Physical Tension or Stress Noted on a Recent Check-in',
          timeWindow: 'Past 3–4 days',
          contributingObservations: [
            isMultiDay
                ? 'Physical tension or anxiety was rated 7/10 or higher on $daysCount separate recorded days ($highTensionDays tension check-ins, $highAnxietyDays anxiety check-ins).'
                : 'Physical tension or anxiety was rated 7/10 or higher on a recent check-in.',
          ],
          baselineComparison:
              'Tension and stress ratings are higher than your typical resting baseline.',
          uncertaintyStatement:
              'Stress responses often reflect external demands or physical fatigue.',
          userCheckInQuestion:
              'Are you noticing tightness in your body, shallow breathing, or heightened stress?',
          supportPlanPrompt:
              'A few minutes of vagal breathing, progressive muscle relaxation, or a quiet walk can help signal safety to your body.',
          therapistPrompt: null,
          detectedAt: now,
        ),
      );
    }

    return divergences;
  }
}

/// Therapist-ready weekly clinical summary answering Part 7.3.
class WeeklySummaryReport {
  const WeeklySummaryReport({
    required this.weekRange,
    required this.totalEntriesThisWeek,
    required this.whatChangedSummary,
    required this.topSymptoms,
    required this.sleepTrend,
    required this.recurringTriggers,
    required this.divergencePoints,
    required this.suggestedTherapyTopics,
  });

  final String weekRange;
  final int totalEntriesThisWeek;
  final String whatChangedSummary;
  final List<String> topSymptoms;
  final String sleepTrend;
  final List<String> recurringTriggers;
  final List<String> divergencePoints;
  final List<String> suggestedTherapyTopics;

  factory WeeklySummaryReport.generate({
    required List<MindTraceModel> traces,
    required PersonalBaseline baseline,
    AppStrings strings = const AppStrings('en'),
  }) {
    final now = DateTime.now();
    final weekCutoff = now.subtract(const Duration(days: 7));
    final weekTraces = traces.where((t) => t.date.isAfter(weekCutoff)).toList();

    if (weekTraces.isEmpty) {
      return WeeklySummaryReport(
        weekRange: strings.isArabic
            ? 'آخر 7 أيام'
            : (strings.isFrench ? '7 derniers jours' : 'Past 7 days'),
        totalEntriesThisWeek: 0,
        whatChangedSummary: strings.isArabic
            ? 'لم تُسجّل ملاحظات خلال الأيام السبعة الماضية.'
            : (strings.isFrench
                ? 'Aucune observation enregistrée sur les 7 derniers jours.'
                : 'No entries recorded in the past 7 days to evaluate trends.'),
        topSymptoms: const [],
        sleepTrend: strings.baselineNeedsMoreData,
        recurringTriggers: const [],
        divergencePoints: const [],
        suggestedTherapyTopics: [
          strings.isArabic
              ? 'متابعة روتين ملاحظة يومي خفيف دون أي ضغط.'
              : (strings.isFrench
                  ? 'Installer un rythme d’observation court sans pression.'
                  : 'Establish a daily observation routine with 1-minute check-ins.'),
        ],
      );
    }

    final sleepList = weekTraces.map((t) => t.sleepHours).whereType<double>().toList();
    final avgSleepThisWeek = sleepList.isNotEmpty
        ? sleepList.reduce((a, b) => a + b) / sleepList.length
        : baseline.averageSleepHours;

    final avgMoodThisWeek =
        weekTraces.map((t) => t.moodIntensity).reduce((a, b) => a + b) / weekTraces.length;

    // What changed — treat |delta| < 0.1 as "Steady with your baseline" (never "±0.0")
    final baselineMood = baseline.averageMoodIntensity;
    final moodDiff = baselineMood != null ? avgMoodThisWeek - baselineMood : null;

    final baselineSleep = baseline.averageSleepHours;
    final sleepDiff = (avgSleepThisWeek != null && baselineSleep != null)
        ? avgSleepThisWeek - baselineSleep
        : null;

    String whatChanged = strings.isArabic
        ? 'هذا الأسبوع، بلغ متوسط شدة المزاج ${avgMoodThisWeek.toStringAsFixed(1)}/10 '
        : (strings.isFrench
            ? 'Cette semaine, l’intensité moyenne était de ${avgMoodThisWeek.toStringAsFixed(1)}/10 '
            : 'This week, mood intensity averaged ${avgMoodThisWeek.toStringAsFixed(1)}/10 ');
    if (moodDiff != null && baselineMood != null) {
      if (moodDiff.abs() < 0.1) {
        whatChanged += '(${strings.steadyWithBaseline}: ${baselineMood.toStringAsFixed(1)}/10). ';
      } else {
        final signed = '${moodDiff > 0 ? '+' : '-'}${moodDiff.abs().toStringAsFixed(1)}';
        whatChanged += strings.isArabic
            ? '($signed مقارنةً بمرجع ${baselineMood.toStringAsFixed(1)}/10). '
            : (strings.isFrench
                ? '($signed par rapport à votre repère de ${baselineMood.toStringAsFixed(1)}/10). '
                : '($signed points from baseline average of ${baselineMood.toStringAsFixed(1)}/10 across ${baseline.moodObservationCount} entries). ');
      }
    } else {
      whatChanged += strings.isArabic
          ? '(لا يوجد خط مرجعي للمقارنة بعد). '
          : (strings.isFrench
              ? '(repère en cours de calibration). '
              : '(no baseline available for comparison). ');
    }

    String sleepTrendStr;
    if (avgSleepThisWeek == null) {
      sleepTrendStr = strings.isArabic
          ? 'لم تُسجّل ساعات النوم هذا الأسبوع.'
          : (strings.isFrench
              ? 'La durée du sommeil n’a pas été notée cette semaine.'
              : 'Sleep duration was not recorded this week.');
    } else if (sleepDiff != null && baselineSleep != null) {
      final avgStr = '${avgSleepThisWeek.toStringAsFixed(1)}h';
      if (sleepDiff.abs() < 0.1) {
        sleepTrendStr = strings.isArabic
            ? 'متوسط النوم $avgStr/ليلة (${strings.steadyWithBaseline}).'
            : (strings.isFrench
                ? 'Sommeil moyen de $avgStr/nuit (${strings.steadyWithBaseline}).'
                : 'Average sleep was $avgStr/night (${strings.steadyWithBaseline}).');
      } else {
        final amt = '${sleepDiff.abs().toStringAsFixed(1)}h';
        sleepTrendStr = strings.isArabic
            ? 'متوسط النوم $avgStr/ليلة (${sleepDiff > 0 ? 'أعلى بـ' : 'أقل بـ'} $amt مقارنةً بمرجع ${baselineSleep.toStringAsFixed(1)}h).'
            : (strings.isFrench
                ? 'Sommeil moyen de $avgStr/nuit (${sleepDiff > 0 ? 'en hausse de' : 'en baisse de'} $amt vs ${baselineSleep.toStringAsFixed(1)}h).'
                : 'Average sleep was $avgStr/night (${sleepDiff > 0 ? 'up by ' : 'down by '}$amt from typical baseline of ${baselineSleep.toStringAsFixed(1)}h across ${baseline.sleepObservationCount} nights).');
      }
    } else {
      sleepTrendStr = strings.isArabic
          ? 'متوسط النوم ${avgSleepThisWeek.toStringAsFixed(1)}h/ليلة (المرجع قيد المعايرة).'
          : (strings.isFrench
              ? 'Sommeil moyen de ${avgSleepThisWeek.toStringAsFixed(1)}h/nuit (repère en cours).'
              : 'Average sleep was ${avgSleepThisWeek.toStringAsFixed(1)}h/night (no baseline available for comparison).');
    }

    // Top symptoms
    final symCounts = <String, int>{};
    for (final t in weekTraces) {
      final s = t.symptomsAndExperiences;
      if (s != null && s.isNotEmpty) {
        for (final p in s.split(RegExp(r'[,;\n]')).map((x) => x.trim()).where((x) => x.isNotEmpty)) {
          symCounts[p] = (symCounts[p] ?? 0) + 1;
        }
      }
    }
    final topSymptoms = (symCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(4)
        .map((e) => '${e.key} (${e.value}x)')
        .toList();

    // Topics to discuss with therapist
    final topics = <String>[];
    if (sleepDiff != null && sleepDiff.abs() >= 0.1 && avgSleepThisWeek != null && baseline.averageSleepHours != null) {
      topics.add('Review recent sleep shifts (${avgSleepThisWeek.toStringAsFixed(1)}h/night vs ${baseline.averageSleepHours!.toStringAsFixed(1)}h baseline).');
    }
    if (topSymptoms.isNotEmpty) {
      topics.add('Discuss recurring experiences logged: ${topSymptoms.take(2).join(', ')}.');
    }
    if (baseline.recurringTriggers.isNotEmpty) {
      topics.add('Explore coping strategies for common triggers: ${baseline.recurringTriggers.take(2).join(', ')}.');
    }
    if (topics.isEmpty) {
      topics.add('General check-in on routine consistency and emotional balance.');
    }

    return WeeklySummaryReport(
      weekRange: strings.isArabic
          ? 'آخر 7 أيام (${weekTraces.length} تسجيلات)'
          : (strings.isFrench
              ? '7 derniers jours (${weekTraces.length} bilans)'
              : 'Past 7 days (${weekTraces.length} check-ins)'),
      totalEntriesThisWeek: weekTraces.length,
      whatChangedSummary: whatChanged,
      topSymptoms: topSymptoms,
      sleepTrend: sleepTrendStr,
      recurringTriggers: baseline.recurringTriggers,
      divergencePoints: const [],
      suggestedTherapyTopics: topics,
    );
  }
}

// Providers
final personalBaselineProvider = Provider<PersonalBaseline>((ref) {
  return ref.watch(mindTraceControllerProvider.select((asyncVal) {
    return PersonalBaseline.fromTraces(asyncVal.value ?? []);
  }));
});

final patternDivergencesProvider = Provider<List<PatternDivergence>>((ref) {
  return ref.watch(mindTraceControllerProvider.select((asyncVal) {
    final traces = asyncVal.value ?? [];
    final baseline = PersonalBaseline.fromTraces(traces);
    return PatternAwarenessService.detectDivergences(traces: traces, baseline: baseline);
  }));
});

final weeklySummaryProvider = Provider<WeeklySummaryReport>((ref) {
  final strings = ref.watch(appStringsProvider);
  return ref.watch(mindTraceControllerProvider.select((asyncVal) {
    final traces = asyncVal.value ?? [];
    final baseline = PersonalBaseline.fromTraces(traces);
    return WeeklySummaryReport.generate(
      traces: traces,
      baseline: baseline,
      strings: strings,
    );
  }));
});
