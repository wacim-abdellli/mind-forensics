import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_badge.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../../core/widgets/mind_segmented.dart';
import '../../../core/widgets/smooth_spline_chart.dart';
import '../../case_file/presentation/clinical_export_preview_sheet.dart';
import '../../investigation/controllers/investigation_providers.dart';
import '../../investigation/domain/case_model.dart';
import '../../mind_trace/controllers/mind_trace_controller.dart';
import '../../mind_trace/domain/mind_trace_model.dart';
import '../../progress/data/progress_analytics_service.dart';
import '../../progress/domain/progress_analytics_model.dart';
import '../data/pattern_awareness_service.dart';
import '../domain/pattern_divergence_model.dart';
import '../domain/personal_baseline_model.dart';

/// Insights destination: Turns self-observation into personal understanding.
/// Matches Phone 4 in the master reference with mood trends spline, pattern cards,
/// botanical encouragement, and clinical baseline analytics.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  static const _rangeLabels = ['1W', '1M', '3M', '6M'];
  String _selectedRange = '1M';
  int? _selectedPointIndex;

  List<MindTraceModel> _filterTracesByRange(List<MindTraceModel> traces) {
    final now = DateTime.now();
    final Duration window;
    switch (_selectedRange) {
      case '1W':
        window = const Duration(days: 7);
        break;
      case '3M':
        window = const Duration(days: 90);
        break;
      case '6M':
        window = const Duration(days: 180);
        break;
      case '1M':
      default:
        window = const Duration(days: 30);
        break;
    }
    final cutoff = now.subtract(window);
    return traces.where((t) => !t.date.isBefore(cutoff)).toList();
  }

  void _showRangeOverviewSheet(
    BuildContext context,
    List<MindTraceModel> filteredTraces,
    MindTokens tokens,
    AppStrings strings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.calendarTitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  MindBadge(label: _selectedRange),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                strings.isArabic
                    ? '${filteredTraces.length} ملاحظات في هذه الفترة المحددة.'
                    : (strings.isFrench
                        ? '${filteredTraces.length} observations sur la période sélectionnée.'
                        : '${filteredTraces.length} observations recorded in this $_selectedRange window.'),
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
              const SizedBox(height: 16),
              MindButton(
                text: strings.progressTabCalendar,
                isFullWidth: true,
                leadingIcon: Icons.calendar_month_outlined,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/progress');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = ref.watch(appStringsProvider);
    final baseline = ref.watch(personalBaselineProvider);
    final divergences = ref.watch(patternDivergencesProvider);
    final weeklySummary = ref.watch(weeklySummaryProvider);
    final cases = ref.watch(savedCasesProvider).value ?? [];
    final allTraces = ref.watch(mindTraceControllerProvider).value ?? [];
    final traces = _filterTracesByRange(allTraces);
    final analytics = ref.watch(progressAnalyticsProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.navInsights,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today_outlined, size: 20, color: tokens.textPrimary),
            tooltip: strings.calendarTitle,
            onPressed: () {
              HapticFeedback.lightImpact();
              _showRangeOverviewSheet(context, traces, tokens, strings);
            },
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, size: 20, color: tokens.textPrimary),
            tooltip: strings.exportSummaryButton,
            onPressed: () {
              HapticFeedback.lightImpact();
              ClinicalExportPreviewSheet.show(context, cases);
            },
          ),
          const SupportButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Time Horizon Filter + Quick Self-Care Tools Shortcut
            MindSegmented(
              index: _rangeLabels.indexOf(_selectedRange).clamp(0, _rangeLabels.length - 1),
              labels: _rangeLabels,
              onChanged: (idx) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedRange = _rangeLabels[idx];
                  _selectedPointIndex = null;
                });
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                button: true,
                label: strings.navObservatory,
                child: MindPressable(
                  onPressed: () => context.push('/observatory'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: tokens.accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.spa_outlined, size: 16, color: tokens.accent),
                        const SizedBox(width: 8),
                        Text(
                          strings.navObservatory,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: tokens.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. Mood Trends Section
            Text(
              strings.moodTrendsHeader,
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            _buildMoodTrendsCard(context, tokens, traces, strings),
            const SizedBox(height: 18),

            // 3. Your Patterns Section
            _buildYourPatternsSection(
              context,
              tokens,
              analytics,
              baseline,
              allTraces,
              strings,
            ),
            const SizedBox(height: 18),

            // 4. Context & Mood Links (Shown only when triggers or helpers exist to keep UI calm)
            if (traces.any((t) =>
                (t.situation?.trim().isNotEmpty ?? false) ||
                (t.behavioralResponse?.trim().isNotEmpty ?? false))) ...[
              _buildContextMoodLinksCard(context, traces, tokens, strings),
              const SizedBox(height: 18),
            ],

            // 5. Personal Baseline Card (Preserved Core)
            _buildBaselineCard(context, baseline, tokens, strings),
            const SizedBox(height: 18),

            // 6. Pattern Awareness Divergences (if any detected)
            if (divergences.isNotEmpty) ...[
              Text(
                strings.patternAwarenessTitle.toUpperCase(),
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              ...divergences.map((d) => _buildDivergenceCard(context, d, tokens, strings)),
              const SizedBox(height: 18),
            ],

            // 7. Weekly Therapist Summary Card (Preserved Core)
            _buildWeeklyTherapistSummaryCard(context, weeklySummary, cases, tokens, strings),
            const SizedBox(height: 18),

            // 8. Detailed Analytics Deep-Dive Button (Preserved Core)
            MindCard(
              padding: const EdgeInsets.all(16),
              onTap: () => context.push('/progress'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tokens.accentSoft,
                      borderRadius: BorderRadius.circular(tokens.chipRadius),
                    ),
                    child: Icon(Icons.analytics_outlined, size: 20, color: tokens.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.fullProgressTrendsTitle,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.fullProgressTrendsSub,
                          style: TextStyle(color: tokens.textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: tokens.textTertiary,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}

  Widget _buildMoodTrendsCard(
    BuildContext context,
    MindTokens tokens,
    List<MindTraceModel> traces,
    AppStrings strings,
  ) {
    final distinctDays = traces.map((t) => t.dateKey).toSet().length;
    if (distinctDays < 2) {
      return MindCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.surfaceSecondary,
              ),
              child: Icon(
                Icons.show_chart_rounded,
                size: 20,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.calibratingChartTitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.calibratingChartSub,
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final sortedTraces = [...traces]..sort((a, b) => a.date.compareTo(b.date));
    final recentTraces = sortedTraces.length > 14
        ? sortedTraces.sublist(sortedTraces.length - 14)
        : sortedTraces;
    final chartValues = recentTraces
        .map((t) => ((t.moodIntensity - 1) / 9.0).clamp(0.05, 0.95))
        .toList();
    final activeIdx = (_selectedPointIndex != null &&
            _selectedPointIndex! >= 0 &&
            _selectedPointIndex! < recentTraces.length)
        ? _selectedPointIndex!
        : recentTraces.length - 1;
    final selectedTrace = recentTraces[activeIdx];
    final activeLabel =
        '${strings.shortMonthName(selectedTrace.date.month)} ${selectedTrace.date.day} · ${selectedTrace.moodIntensity}/10';

    return MindCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 132,
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    strings.chartHighLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.textTertiary,
                    ),
                  ),
                  Text(
                    strings.chartMidLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.textTertiary,
                    ),
                  ),
                  Text(
                    strings.chartLowLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SmoothSplineChart(
              values: chartValues,
              height: 132,
              activePointIndex: activeIdx,
              activePointLabel: activeLabel,
              lineColor: tokens.accent,
              showDots: true,
              onPointSelected: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _selectedPointIndex = idx);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourPatternsSection(
    BuildContext context,
    MindTokens tokens,
    ProgressAnalyticsModel analytics,
    PersonalBaseline baseline,
    List<MindTraceModel> allTraces,
    AppStrings strings,
  ) {
    final insights = analytics.insights;
    final weekCutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentWeek = allTraces
        .where((t) => !t.date.isBefore(weekCutoff))
        .toList();

    final weekSleeps = recentWeek
        .where((t) => t.sleepHours != null)
        .map((t) => t.sleepHours!)
        .toList();
    final avgWeekSleep = weekSleeps.isEmpty
        ? null
        : weekSleeps.reduce((a, b) => a + b) / weekSleeps.length;
    final avgWeekMood = recentWeek.isEmpty
        ? null
        : recentWeek.map((t) => t.moodIntensity).reduce((a, b) => a + b) /
            recentWeek.length;

    String? mostCommonMood;
    if (recentWeek.isNotEmpty) {
      final counts = <String, int>{};
      for (final t in recentWeek) {
        final m = t.overallMood.trim();
        if (m.isNotEmpty) {
          counts[m] = (counts[m] ?? 0) + 1;
        }
      }
      if (counts.isNotEmpty) {
        mostCommonMood = counts.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                strings.yourPatternsHeader,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: strings.viewAllArrowLabel,
              child: MindPressable(
                onPressed: () => context.push('/progress'),
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          strings.viewAllArrowLabel,
                          style: TextStyle(
                            color: tokens.accent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: tokens.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (baseline.hasSufficientData && recentWeek.isNotEmpty) ...[
          MindCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (avgWeekSleep != null && baseline.averageSleepHours != null)
                  _buildDeltaComparisonRow(
                    tokens: tokens,
                    icon: Icons.bedtime_outlined,
                    label: strings.baselineSleepComparisonTitle,
                    value: ProgressAnalyticsCalculator.describeDeltaVsBaseline(
                      recentAverage: avgWeekSleep,
                      baselineAverage: baseline.averageSleepHours!,
                      unit: 'h',
                      strings: strings,
                    ),
                  ),
                if (avgWeekMood != null &&
                    baseline.averageMoodIntensity != null) ...[
                  if (avgWeekSleep != null &&
                      baseline.averageSleepHours != null)
                    Divider(height: 18, thickness: 0.5, color: tokens.border),
                  _buildDeltaComparisonRow(
                    tokens: tokens,
                    icon: Icons.speed_outlined,
                    label: strings.baselineMoodComparisonTitle,
                    value: ProgressAnalyticsCalculator.describeDeltaVsBaseline(
                      recentAverage: avgWeekMood,
                      baselineAverage: baseline.averageMoodIntensity!,
                      unit: '/10',
                      strings: strings,
                    ),
                  ),
                ],
                if (mostCommonMood != null) ...[
                  Divider(height: 18, thickness: 0.5, color: tokens.border),
                  _buildDeltaComparisonRow(
                    tokens: tokens,
                    icon: Icons.label_outline_rounded,
                    label: strings.mostCommonThisWeekLabel,
                    value: mostCommonMood,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (insights.isEmpty)
          MindCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 20, color: tokens.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.isArabic
                        ? 'الأنماط قيد المعايرة: مع استمرارك في تسجيل الملاحظات اليومية، ستظهر هنا روابط دقيقة بين النوم والمزاج.'
                        : (strings.isFrench
                            ? 'Calibration en cours : à mesure que vous notez vos observations, les liens entre sommeil, humeur et stress apparaîtront ici.'
                            : 'Patterns calibrating: As you log observations over time, correlations between sleep, mood, and stress will appear here.'),
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          ...insights.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MindCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () => context.push('/progress'),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.accentSoft,
                      ),
                      child: Icon(
                        item.icon,
                        size: 19,
                        color: tokens.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: tokens.textTertiary,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDeltaComparisonRow({
    required MindTokens tokens,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: tokens.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContextMoodLinksCard(
    BuildContext context,
    List<MindTraceModel> traces,
    MindTokens tokens,
    AppStrings strings,
  ) {
    final triggerStats = <String, List<int>>{};
    final helpedStats = <String, int>{};

    for (final t in traces) {
      if (t.situation != null && t.situation!.isNotEmpty) {
        for (final raw in t.situation!.split(',')) {
          final tag = raw.trim();
          if (tag.isEmpty) continue;
          triggerStats.putIfAbsent(tag, () => []).add(t.moodIntensity);
        }
      }
      if (t.behavioralResponse != null && t.behavioralResponse!.isNotEmpty) {
        for (final raw in t.behavioralResponse!.split(',')) {
          final tag = raw.trim();
          if (tag.isEmpty) continue;
          helpedStats[tag] = (helpedStats[tag] ?? 0) + 1;
        }
      }
    }

    final topTriggers = triggerStats.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topHelpers = helpedStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 17, color: tokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.triggerMoodCorrelationsTitle,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              MindBadge(label: _selectedRange),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.triggerMoodCorrelationsSub,
            style: TextStyle(fontSize: 11.5, color: tokens.textSecondary, height: 1.35),
          ),
          if (topTriggers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topTriggers.take(4).map((e) {
                final avg = (e.value.reduce((a, b) => a + b) / e.value.length).toStringAsFixed(1);
                return MindBadge(
                  label: '${e.key} • $avg/10 (${e.value.length}x)',
                  backgroundColor: tokens.surfaceSecondary,
                );
              }).toList(),
            ),
          ],
          if (topHelpers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topHelpers.take(3).map((e) {
                return MindBadge(
                  icon: Icons.spa_outlined,
                  label: '${e.key} (${e.value}x)',
                  backgroundColor: tokens.accentSoft,
                  textColor: tokens.accent,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBaselineCard(
    BuildContext context,
    PersonalBaseline baseline,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.straighten_outlined, size: 16, color: tokens.accent),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        strings.personalBaselineTitle.toUpperCase(),
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: MindBadge(
                  label: baseline.statusLabel,
                  backgroundColor: baseline.hasEstablishedBaseline
                      ? tokens.accentSoft
                      : tokens.surfaceSecondary,
                  textColor: baseline.hasEstablishedBaseline
                      ? tokens.accent
                      : (baseline.hasSufficientData ? tokens.textPrimary : tokens.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!baseline.hasSufficientData) ...[
            Text(
              strings.baselineNeedsMoreData,
              style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
            ),
          ] else ...[
            Text(
              strings.rollingNormalSubtitle,
              style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatColumn(
                  strings.typicalSleepLabel,
                  baseline.averageSleepHours != null ? '${baseline.averageSleepHours}h' : '—',
                  tokens,
                ),
                _buildStatColumn(
                  strings.typicalEnergyLabel,
                  baseline.averageEnergyLevel != null ? '${baseline.averageEnergyLevel}/10' : '—',
                  tokens,
                ),
                _buildStatColumn(
                  strings.moodIntensityShortLabel,
                  baseline.averageMoodIntensity != null ? '${baseline.averageMoodIntensity}/10' : '—',
                  tokens,
                ),
              ],
            ),
            if (baseline.commonEmotions.isNotEmpty) ...[
              const Divider(height: 24, thickness: 0.5),
              Text(
                '${strings.frequentEmotionsLabel}: ${baseline.commonEmotions.join(', ')}',
                style: TextStyle(color: tokens.textTertiary, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, MindTokens tokens) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: tokens.textTertiary, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivergenceCard(
    BuildContext context,
    PatternDivergence d,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MindCard(
        borderColor: tokens.accent,
        backgroundColor: tokens.accentSoft.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_outlined, size: 16, color: tokens.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.title,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                MindBadge(label: d.timeWindow),
              ],
            ),
            const SizedBox(height: 10),
            ...d.contributingObservations.map((obs) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: tokens.accent, fontSize: 13)),
                      Expanded(
                        child: Text(
                          obs,
                          style: TextStyle(color: tokens.textPrimary, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(tokens.chipRadius),
                border: Border.all(color: tokens.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.userCheckInQuestion,
                    style: TextStyle(color: tokens.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.supportPlanPrompt,
                    style: TextStyle(color: tokens.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              d.uncertaintyStatement,
              style: TextStyle(
                color: tokens.textTertiary,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTherapistSummaryCard(
    BuildContext context,
    WeeklySummaryReport report,
    List<CaseModel> cases,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return MindCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.weeklySummaryTitle.toUpperCase(),
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MindBadge(label: report.weekRange),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.whatChangedSummary,
            style: TextStyle(color: tokens.textPrimary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            report.sleepTrend,
            style: TextStyle(color: tokens.textSecondary, fontSize: 12.5),
          ),
          if (report.topSymptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${strings.recordedSymptomsPrefix}: ${report.topSymptoms.join(', ')}',
              style: TextStyle(color: tokens.textTertiary, fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            strings.suggestedTherapyLabel,
            style: TextStyle(
              color: tokens.accent,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          ...report.suggestedTherapyTopics.map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('— ', style: TextStyle(color: tokens.accent, fontSize: 12)),
                    Expanded(
                      child: Text(
                        topic,
                        style: TextStyle(color: tokens.textPrimary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          MindButton(
            text: strings.exportSummaryButton,
            variant: MindButtonVariant.secondary,
            isFullWidth: true,
            leadingIcon: Icons.description_outlined,
            onPressed: () {
              HapticFeedback.lightImpact();
              ClinicalExportPreviewSheet.show(context, cases);
            },
          ),
        ],
      ),
    );
  }
}
