import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/theme/lab_colors.dart';
import 'package:mind_forensics/app/theme/mind_tokens.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_active_case_card.dart';
import 'package:mind_forensics/features/home/presentation/widgets/home_daily_check_in_card.dart';
import 'package:mind_forensics/features/investigation/domain/case_model.dart';
import 'package:mind_forensics/features/investigation/domain/case_stage.dart';

void main() {
  group('Home Extracted Components Unit & Widget Tests', () {
    const tokens = MindTokens.dark;
    const strings = AppStrings('en');

    final moodOptions = const [
      (key: 'calm', icon: Icons.spa_outlined),
      (key: 'anxious', icon: Icons.bolt_outlined),
      (key: 'frustrated', icon: Icons.local_fire_department_outlined),
    ];

    testWidgets('HomeDailyCheckInCard renders options-first check-in controls and triggers callbacks', (tester) async {
      int selectedIdx = 0;
      double intensity = 5.0;
      bool saved = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HomeDailyCheckInCard(
                  tokens: tokens,
                  strings: strings,
                  isDark: true,
                  todayTrace: null,
                  traces: const [],
                  selectedMoodIndex: selectedIdx,
                  moodIntensity: intensity,
                  todayNoteController: controller,
                  moodOptions: moodOptions,
                  onMoodSelected: (idx) => setState(() => selectedIdx = idx),
                  onIntensityChanged: (val) => setState(() => intensity = val),
                  onSave: () => saved = true,
                  getMoodLabel: (key, str) => key.toUpperCase(),
                  getMoodColor: (key) => LabColors.moodCalm,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify emotion pills, intensity scale, and feeling word
      expect(find.text('${strings.moodIntensityLabel.toUpperCase()}: 5/10'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('CALM'), findsOneWidget);
      expect(find.text('ANXIOUS'), findsOneWidget);

      // Select 'ANXIOUS'
      await tester.tap(find.text('ANXIOUS'));
      await tester.pumpAndSettle();
      expect(selectedIdx, equals(1));

      // Tap intensity level 8 cleanly (zero bar dragging)
      await tester.tap(find.byKey(const ValueKey<String>('intensity-level-8')));
      await tester.pumpAndSettle();
      expect(intensity, equals(8.0));
      expect(find.text('${strings.moodIntensityLabel.toUpperCase()}: 8/10'), findsOneWidget);
      expect(find.text('Strong'), findsOneWidget);

      // Enter optional text note
      await tester.enterText(find.byType(TextField), 'Calibrated evening walk');
      await tester.pumpAndSettle();
      expect(controller.text, equals('Calibrated evening walk'));

      // Tap Save Check-in
      await tester.tap(find.text(strings.saveCheckInButton));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
    });

    testWidgets('HomeActiveCaseCard renders case progress and invokes onResume', (tester) async {
      bool resumed = false;
      final testCase = CaseModel(
        id: 'c1',
        caseNumber: 'CASE 07',
        title: 'Workplace presentation tension',
        incidentDescription: 'High somatic pressure during presentation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStage: CaseStage.evidence,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeActiveCaseCard(
              caseModel: testCase,
              tokens: tokens,
              strings: strings,
              isDark: true,
              onResume: () => resumed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workplace presentation tension'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(strings.resumeInvestigation), findsOneWidget);

      await tester.tap(find.text(strings.resumeInvestigation));
      await tester.pumpAndSettle();
      expect(resumed, isTrue);
    });

    testWidgets('HomeDailyCheckInCard mood pills keep invariant layout geometry when selection changes', (tester) async {
      final allMoods = const [
        (key: 'calm', icon: Icons.spa_outlined),
        (key: 'anxious', icon: Icons.bolt_outlined),
        (key: 'frustrated', icon: Icons.local_fire_department_outlined),
        (key: 'heavy', icon: Icons.grain_outlined),
        (key: 'restless', icon: Icons.air_outlined),
      ];
      String labelFor(String key) => switch (key) {
        'calm' => 'Calm',
        'anxious' => 'Anxious',
        'frustrated' => 'Frustrated',
        'heavy' => 'Heavy',
        'restless' => 'Restless',
        _ => key,
      };
      int selectedIdx = 4; // Start on 'Restless'

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, extensions: const [MindTokens.light]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 340,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return HomeDailyCheckInCard(
                      tokens: MindTokens.light,
                      strings: strings,
                      isDark: false,
                      todayTrace: null,
                      traces: const [],
                      selectedMoodIndex: selectedIdx,
                      moodIntensity: 5.0,
                      todayNoteController: TextEditingController(),
                      moodOptions: allMoods,
                      onMoodSelected: (idx) => setState(() => selectedIdx = idx),
                      onIntensityChanged: (_) {},
                      onSave: () {},
                      getMoodLabel: (key, _) => labelFor(key),
                      getMoodColor: (_) => LabColors.moodCalm,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Map<String, Rect> captureRects() => {
        for (final m in allMoods)
          m.key: tester.getRect(find.text(labelFor(m.key))),
      };

      final initialRects = captureRects();

      // Selecting any pill (including 'Anxious' on Row 1) must not reflow sibling pills.
      for (final m in allMoods) {
        await tester.tap(find.text(labelFor(m.key)));
        await tester.pumpAndSettle();
        expect(captureRects(), equals(initialRects), reason: 'Reflow after selecting ${m.key}');
      }
    });
  });
}
