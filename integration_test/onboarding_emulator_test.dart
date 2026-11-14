import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/core/safety/support_button.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:mind_forensics/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End 4-Step Options-First Onboarding & Navigation Scenarios', () {
    testWidgets('Scenario 1: Complete 4-step onboarding, handoff to Home, and 5-tab navigation',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppRouter.enableFirstLaunchGating = true;
      AppRouter.router.go(AppRouter.onboarding);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          child: const MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Welcome + Live EN / FR / AR switch + calm SupportButton shield
      expect(find.text('Every thought leaves a trace.'), findsOneWidget);
      expect(find.byType(SupportButton), findsOneWidget);
      expect(find.text('Crisis Support'), findsNothing);

      await tester.tap(find.text('AR'));
      await tester.pumpAndSettle();
      expect(find.text('كل فكرة تترك أثراً.'), findsOneWidget);

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('Every thought leaves a trace.'), findsOneWidget);

      // Step 1 -> Step 2 (Focus choices, zero mandatory typing)
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4'), findsOneWidget);

      await tester.tap(find.text('Ease stress & anxiety'));
      await tester.tap(find.text('Understand mood patterns'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Comfort & safety + Under-18 safeguard
      expect(find.text('Step 3 of 4'), findsOneWidget);
      final strings = const AppStrings('en');
      await tester.tap(find.text('Under 18'));
      await tester.pumpAndSettle();
      expect(find.text(strings.minorSupportNotice), findsOneWidget);

      await tester.tap(find.text('25-34'));
      await tester.pumpAndSettle();
      expect(find.text(strings.minorSupportNotice), findsNothing);
      await tester.tap(find.text('Seeing a specialist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: First daily check-in -> Save & Enter App
      expect(find.text('Step 4 of 4'), findsOneWidget);
      await tester.tap(find.text('Anxious'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & Enter App'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate across Track & Insights tabs
      await tester.tap(find.text('Track'));
      await tester.pumpAndSettle();
      expect(find.byType(TrackScreen), findsOneWidget);

      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.byType(InsightsScreen), findsOneWidget);

      // Open one-tap SupportModalSheet from shield badge
      await tester.tap(find.byType(SupportButton));
      await tester.pumpAndSettle();
      expect(find.byType(SupportModalSheet), findsOneWidget);
      expect(find.textContaining('80 10 50 50'), findsOneWidget);
    });

    testWidgets('Scenario 2: Skip optional onboarding steps without forced check-in',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      AppRouter.enableFirstLaunchGating = true;
      AppRouter.router.go(AppRouter.onboarding);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          child: const MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 4'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 4'), findsOneWidget);

      await tester.tap(find.text('Skip & Enter App'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Scenario 3: Returning user lands directly on HomeScreen',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'mf_onboarding_completed': true,
      });
      AppRouter.enableFirstLaunchGating = true;
      AppRouter.router.go(AppRouter.home);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          child: const MindForensicsApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Every thought leaves a trace.'), findsNothing);
    });
  });
}
