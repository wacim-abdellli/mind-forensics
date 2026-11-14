import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mind_forensics/app/localization/app_strings.dart';
import 'package:mind_forensics/app/localization/locale_controller.dart';
import 'package:mind_forensics/app/router/app_router.dart';
import 'package:mind_forensics/app/router/scaffold_with_nav_bar.dart';
import 'package:mind_forensics/app/theme/lab_theme.dart';
import 'package:mind_forensics/core/safety/support_button.dart';
import 'package:mind_forensics/features/home/presentation/home_screen.dart';
import 'package:mind_forensics/features/insights/domain/personal_baseline_model.dart';
import 'package:mind_forensics/features/insights/presentation/insights_screen.dart';
import 'package:mind_forensics/features/investigation/presentation/flash_case_screen.dart';
import 'package:mind_forensics/features/mind_trace/controllers/mind_trace_controller.dart';
import 'package:mind_forensics/features/mind_trace/domain/mind_trace_model.dart';
import 'package:mind_forensics/features/observatory/presentation/inner_observatory_screen.dart';
import 'package:mind_forensics/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mind_forensics/features/settings/presentation/settings_screen.dart';
import 'package:mind_forensics/features/tools/presentation/tools_screen.dart';
import 'package:mind_forensics/features/track/presentation/track_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _vqaOutDir = String.fromEnvironment('VQA_OUT_DIR');

Future<void> _loadBundledInterFonts() async {
  Future<void> loadFamily(String family) async {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
    await loader.load();
  }

  await loadFamily('Inter');
  await loadFamily('Inter_regular');
  await loadFamily('Inter_500');
  await loadFamily('Inter_600');
  await loadFamily('Inter_700');

  try {
    final iconData = await rootBundle.load('assets/fonts/MaterialIcons-Regular.otf');
    final materialLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(iconData));
    await materialLoader.load();
  } catch (_) {}
}

Future<void> _settleFrame(WidgetTester tester) async {
  await tester.pump();
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _maybeCapture(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  if (_vqaOutDir.isEmpty) return;
  await _settleFrame(tester);
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final dir = Directory(_vqaOutDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final file = File('${dir.path}${Platform.pathSeparator}$filename');
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
  });
}

GoRouter _buildShellRouter({String initialLocation = AppRouter.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.track,
                builder: (_, _) => const TrackScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.companion,
                builder: (_, _) => const FlashCaseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.insights,
                builder: (_, _) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.profile,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<void> _seedSteadyTraces(ProviderContainer container) async {
  final now = DateTime.now();
  final repo = container.read(mindTraceRepositoryProvider);
  for (int i = 0; i < 6; i++) {
    await repo.saveTrace(
      MindTraceModel(
        id: 'vqa_trace_$i',
        userId: 'vqa_user',
        date: now.subtract(Duration(days: i)),
        overallMood: i.isEven ? 'calm' : 'anxious',
        moodIntensity: 5 + (i % 3),
        energyLevel: 6 + (i % 2),
        anxietyLevel: 3 + (i % 2),
        sleepHours: 7.0 + (i % 2) * 0.5,
        createdAt: now.subtract(Duration(days: i)),
        updatedAt: now.subtract(Duration(days: i)),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadBundledInterFonts();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'mf_onboarding_completed': true});
  });

  group('Step 9 Pre-Launch Visual & Responsive QA Matrix', () {
    testWidgets('Captures Light/Dark 5-tab shell, Tools, Observatory, and Settings',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _seedSteadyTraces(container);

      final router = _buildShellRouter();
      addTearDown(router.dispose);
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: repaintKey,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: LabTheme.daylightTheme,
              locale: const Locale('en'),
              supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: router,
            ),
          ),
        ),
      );
      await _settleFrame(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SupportButton), findsOneWidget);
      expect(find.text('Crisis Support'), findsNothing);
      await _maybeCapture(tester, repaintKey, 'qa_01_shell_home_light_en.png');

      // Tab 1: Track
      router.go(AppRouter.track);
      await _settleFrame(tester);
      expect(tester.takeException(), isNull);
      await _maybeCapture(tester, repaintKey, 'qa_02_shell_track_light_en.png');

      // Tab 2: AI Guide
      router.go(AppRouter.companion);
      await _settleFrame(tester);
      expect(tester.takeException(), isNull);
      await _maybeCapture(tester, repaintKey, 'qa_03_shell_guide_light_en.png');

      // Tab 3: Insights
      router.go(AppRouter.insights);
      await _settleFrame(tester);
      expect(tester.takeException(), isNull);
      await _maybeCapture(tester, repaintKey, 'qa_04_shell_insights_light_en.png');

      // Tab 4: Settings / Profile
      router.go(AppRouter.profile);
      await _settleFrame(tester);
      expect(tester.takeException(), isNull);
      await _maybeCapture(tester, repaintKey, 'qa_05_shell_settings_light_en.png');

      // Switch to Dark Mode and capture Settings + Insights + Track
      final darkContainer = ProviderContainer();
      addTearDown(darkContainer.dispose);
      await _seedSteadyTraces(darkContainer);
      final darkRouter = _buildShellRouter(initialLocation: AppRouter.profile);
      addTearDown(darkRouter.dispose);
      final darkKey = GlobalKey();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: darkContainer,
          child: RepaintBoundary(
            key: darkKey,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: LabTheme.nightTheme,
              locale: const Locale('en'),
              supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: darkRouter,
            ),
          ),
        ),
      );
      await _settleFrame(tester);
      expect(tester.takeException(), isNull);
      await _maybeCapture(tester, darkKey, 'qa_06_shell_settings_dark_en.png');

      darkRouter.go(AppRouter.insights);
      await _settleFrame(tester);
      expect(tester.takeException(), isNull);
      await _maybeCapture(tester, darkKey, 'qa_07_shell_insights_dark_en.png');

      // Capture InnerObservatoryScreen & ToolsScreen
      final toolKey = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: RepaintBoundary(
            key: toolKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: LabTheme.daylightTheme,
              home: const InnerObservatoryScreen(),
            ),
          ),
        ),
      );
      await _settleFrame(tester);
      expect(tester.takeException(), isNull);
      await _maybeCapture(tester, toolKey, 'qa_08_observatory_light_en.png');

      final toolsOnlyKey = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: RepaintBoundary(
            key: toolsOnlyKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: LabTheme.nightTheme,
              home: const ToolsScreen(),
            ),
          ),
        ),
      );
      await _settleFrame(tester);
      expect(tester.takeException(), isNull);
      await _maybeCapture(tester, toolsOnlyKey, 'qa_09_tools_dark_en.png');
    });

    testWidgets('Captures FR and AR (RTL) Home, Insights, Settings & Onboarding without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      for (final appLang in [AppLanguage.french, AppLanguage.arabic]) {
        final lang = appLang.code;
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(localeControllerProvider.notifier).setLanguage(appLang);
        await _seedSteadyTraces(container);

        final router = _buildShellRouter(initialLocation: AppRouter.home);
        addTearDown(router.dispose);
        final key = GlobalKey();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(
              key: key,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: LabTheme.daylightTheme,
                locale: Locale(lang),
                supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: router,
              ),
            ),
          ),
        );
        await _settleFrame(tester);
        expect(tester.takeException(), isNull);

        if (lang == 'ar') {
          final arStrings = const AppStrings('ar');
          expect(
            Directionality.of(tester.element(find.text(arStrings.updateCheckInButton))),
            TextDirection.rtl,
          );
        }
        await _maybeCapture(tester, key, 'qa_10_home_$lang.png');

        router.go(AppRouter.insights);
        await _settleFrame(tester);
        expect(tester.takeException(), isNull);
        if (lang == 'fr') {
          expect(find.text('Calme'), findsWidgets);
          expect(find.text('Observations préliminaires (6j)'), findsOneWidget);
        }
        await _maybeCapture(tester, key, 'qa_11_insights_$lang.png');

        router.go(AppRouter.profile);
        await _settleFrame(tester);
        expect(tester.takeException(), isNull);
        await _maybeCapture(tester, key, 'qa_12_settings_$lang.png');
      }

      // Onboarding dark & Arabic RTL capture
      final onboardingContainer = ProviderContainer();
      addTearDown(onboardingContainer.dispose);
      await onboardingContainer
          .read(localeControllerProvider.notifier)
          .setLanguage(AppLanguage.arabic);
      final onboardingKey = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: onboardingContainer,
          child: RepaintBoundary(
            key: onboardingKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: LabTheme.nightTheme,
              locale: const Locale('ar'),
              supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const OnboardingScreen(),
            ),
          ),
        ),
      );
      await _settleFrame(tester);
      expect(tester.takeException(), isNull);
      await _maybeCapture(tester, onboardingKey, 'qa_13_onboarding_dark_ar.png');
    });

    testWidgets('320px narrow mobile audit across 5-tab shell and Observatory without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final appLang in AppLanguage.values) {
        final lang = appLang.code;
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(localeControllerProvider.notifier).setLanguage(appLang);
        await _seedSteadyTraces(container);

        final router = _buildShellRouter(initialLocation: AppRouter.home);
        addTearDown(router.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: LabTheme.daylightTheme,
              locale: Locale(lang),
              supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: router,
            ),
          ),
        );
        for (final route in [
          AppRouter.home,
          AppRouter.track,
          AppRouter.companion,
          AppRouter.insights,
          AppRouter.profile,
        ]) {
          router.go(route);
          await _settleFrame(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow or layout error on $route ($lang) at 320px',
          );
        }
      }
    });

    test('PersonalBaseline.localizedStatusLabel covers EN, FR, and AR cleanly', () {
      const empty = PersonalBaseline(totalRecordedDays: 0, hasSufficientData: false);
      const early = PersonalBaseline(totalRecordedDays: 6, hasSufficientData: false);
      const ready = PersonalBaseline(totalRecordedDays: 14, hasSufficientData: true);

      expect(
        early.localizedStatusLabel(const AppStrings('fr')),
        'Observations préliminaires (6j)',
      );

      for (final baseline in [empty, early, ready]) {
        final labels = AppLanguage.values
            .map((l) => baseline.localizedStatusLabel(AppStrings(l.code)).trim())
            .toSet();
        expect(labels.every((s) => s.isNotEmpty), isTrue);
        expect(labels.length, 3);
      }
    });
  });
}
