import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/widgets/mind_segmented.dart';
import 'package:mind_forensics/core/widgets/smooth_spline_chart.dart';
import 'package:mind_forensics/features/insights/data/pattern_awareness_service.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/controllers/investigation_providers.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';
import 'package:mind_forensics/features/investigation/domain/label_type.dart';
import 'package:mind_forensics/features/journal/controllers/journal_memory_controller.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/observatory/presentation/inner_observatory_screen.dart';
import 'package:mind_forensics/features/profile/controllers/profile_controller.dart';
import 'package:mind_forensics/features/progress/data/progress_analytics_service.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/tools/presentation/tools_screen.dart';
import 'package:mind_forensics/features/tools/presentation/widgets/reframe_drill_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  List<MindTraceModel> buildSteadyTraces() {
    final now = DateTime.now();
    return [
      for (int i = 0; i < 4; i++)
        MindTraceModel(
          id: 'trace_$i',
          date: now.subtract(Duration(days: i)),
          overallMood: 'calm',
          moodIntensity: 6,
          sleepHours: 7.0,
          energyLevel: 7,
          createdAt: now.subtract(Duration(days: i)),
          updatedAt: now.subtract(Duration(days: i)),
        ),
    ];
  }

  group('Step 8 Zero-Delta & Baseline Copy', () {
    test('describeDeltaVsBaseline & WeeklySummaryReport use Steady copy for near-zero deltas', () {
      const en = AppStrings('en');
      const fr = AppStrings('fr');
      const ar = AppStrings('ar');

      final posTiny = ProgressAnalyticsCalculator.describeDeltaVsBaseline(
        recentAverage: 7.04,
        baselineAverage: 7.0,
        unit: 'h',
        strings: en,
      );
      final negTiny = ProgressAnalyticsCalculator.describeDeltaVsBaseline(
        recentAverage: 6.96,
        baselineAverage: 7.0,
        unit: 'h',
        strings: en,
      );
      expect(posTiny, contains('Steady with your baseline'));
      expect(negTiny, contains('Steady with your baseline'));
      expect(negTiny, isNot(contains('-0.0')));
      expect(posTiny, isNot(contains('up by 0.0')));

      expect(
        ProgressAnalyticsCalculator.describeDeltaVsBaseline(
          recentAverage: 7.0,
          baselineAverage: 7.0,
          unit: 'h',
          strings: fr,
        ),
        contains(fr.steadyWithBaseline),
      );
      expect(
        ProgressAnalyticsCalculator.describeDeltaVsBaseline(
          recentAverage: 7.0,
          baselineAverage: 7.0,
          unit: 'h',
          strings: ar,
        ),
        contains(ar.steadyWithBaseline),
      );

      final traces = buildSteadyTraces();
      final baseline = PersonalBaseline.fromTraces(traces);
      final report = WeeklySummaryReport.generate(
        traces: traces,
        baseline: baseline,
        strings: en,
      );
      expect(report.sleepTrend, contains('Steady with your baseline'));
      expect(report.sleepTrend, isNot(contains('-0.0')));
    });
  });

  group('Step 8 Tools & Observatory Consolidation', () {
    testWidgets('InnerObservatoryScreen embeds ReframeDrillCard, Quick Calm sheet & passes a11y guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(900, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: LabTheme.nightTheme,
              home: const InnerObservatoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const strings = AppStrings('en');
        expect(find.byType(ReframeDrillCard), findsOneWidget);
        expect(find.text(strings.quickCalmTitle), findsOneWidget);
        expect(find.textContaining('1 / '), findsOneWidget);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        // Interact with drill chip and advance
        await tester.tap(find.text(strings.localizedLabelName(LabelType.assumption)));
        await tester.pumpAndSettle();
        expect(find.text(strings.nextDrill), findsOneWidget);

        await tester.tap(find.text(strings.nextDrill));
        await tester.pumpAndSettle();
        expect(find.textContaining('2 / '), findsOneWidget);

        // Open Quick Calm breathing sheet cleanly
        await tester.tap(find.text(strings.quickCalmTitle));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text(strings.startPacer), findsOneWidget);
        expect(find.text(strings.pacerSub), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('ToolsScreen removes v1 SCOPE micro-badge & passes tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(900, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: LabTheme.daylightTheme,
              home: const ToolsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('v1 SCOPE'), findsNothing);
        expect(find.byType(ReframeDrillCard), findsOneWidget);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    });
  });

  group('Step 8 Insights Chart, Distinct-Day Calibration & Steady Deltas', () {
    testWidgets('InsightsScreen shows calibrating curve when multiple traces fall on same day', (tester) async {
      final now = DateTime.now();
      final sameDay = DateTime(now.year, now.month, now.day, 10);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(mindTraceRepositoryProvider);
      await repo.saveTrace(MindTraceModel(
        id: 'same_1',
        date: sameDay,
        moodIntensity: 4,
        createdAt: sameDay,
        updatedAt: sameDay,
      ));
      await repo.saveTrace(MindTraceModel(
        id: 'same_2',
        date: sameDay.add(const Duration(hours: 3)),
        moodIntensity: 7,
        createdAt: sameDay,
        updatedAt: sameDay,
      ));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: LabTheme.daylightTheme,
            home: const InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mood rhythm calibrating'), findsOneWidget);
      expect(find.byType(SmoothSplineChart), findsNothing);
    });

    testWidgets('InsightsScreen renders text Y labels, MindSegmented, steady baseline copy & passes a11y guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(900, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repo = container.read(mindTraceRepositoryProvider);
        for (final t in buildSteadyTraces()) {
          await repo.saveTrace(t);
        }

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: LabTheme.nightTheme,
              home: const InsightsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MindSegmented), findsOneWidget);
        expect(find.byType(SmoothSplineChart), findsOneWidget);
        expect(find.text('High'), findsOneWidget);
        expect(find.text('Mid'), findsOneWidget);
        expect(find.text('Low'), findsOneWidget);
        expect(find.textContaining('Steady with your baseline'), findsWidgets);
        expect(find.textContaining('-0.0'), findsNothing);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.tap(find.text('1W'));
        await tester.pumpAndSettle();
        expect(find.byType(SmoothSplineChart), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });

  group('Step 8 Settings 4 Grouped Cards, Preferred Name & Double-Confirm Reset', () {
    testWidgets('SettingsScreen renders 4 groups, edits preferred name, executes double-confirm reset & passes a11y guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        SharedPreferences.setMockInitialValues({
          'mf_gentle_notifications': true,
          'mf_settings_ai_history': false,
          'mf_notification_freq': 'weekly',
        });

        tester.view.physicalSize = const Size(900, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final now = DateTime.now();
        await container.read(mindTraceRepositoryProvider).saveTrace(
              MindTraceModel(
                id: 'wipe_t1',
                date: now,
                moodIntensity: 6,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await container.read(caseRepositoryProvider).saveCase(
              CaseModel(
                id: 'wipe_c1',
                caseNumber: 'CASE-01',
                title: 'Test entry',
                currentStage: CaseStage.incident,
                incidentDescription: 'Brief description',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: LabTheme.nightTheme,
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('YOU'), findsOneWidget);
        expect(find.text('DISPLAY & LANGUAGE'), findsOneWidget);
        expect(find.text('AI GUIDE & SECURITY'), findsOneWidget);
        expect(find.text('DATA & CRISIS'), findsOneWidget);
        expect(find.byType(MindSegmented), findsNWidgets(2));
        expect(find.text('Support & Crisis Helplines'), findsOneWidget);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        // Preferred name dialog updates profile
        await tester.tap(find.text('Preferred name'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Yasmine');
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(
          container.read(profileControllerProvider).value?.preferredName,
          'Yasmine',
        );
        expect(find.text('Yasmine'), findsWidgets);

        // Step 1 -> Step 2 double-confirm local reset
        final wipeFinder = find.text('Purge All Records');
        await tester.ensureVisible(wipeFinder);
        await tester.tap(wipeFinder);
        await tester.pumpAndSettle();
        expect(find.text('Start full local data reset?'), findsOneWidget);

        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Final confirmation?'), findsOneWidget);

        await tester.tap(find.text('Erase Everything'));
        await tester.pumpAndSettle();

        final remainingTraces =
            await container.read(mindTraceRepositoryProvider).getAllTraces();
        final remainingCases =
            await container.read(caseRepositoryProvider).getAllCases();
        final remainingMemories =
            await container.read(journalMemoryRepositoryProvider).getAllMemories();
        final prefs = await SharedPreferences.getInstance();

        expect(remainingTraces, isEmpty);
        expect(remainingCases, isEmpty);
        expect(remainingMemories, isEmpty);
        expect(prefs.containsKey('mf_gentle_notifications'), isFalse);
        expect(prefs.containsKey('mf_settings_ai_history'), isFalse);
        expect(prefs.containsKey('mf_notification_freq'), isFalse);
      } finally {
        handle.dispose();
      }
    });
  });
}
