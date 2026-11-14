import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/mind_tokens.dart';
import '../../../core/safety/safety_model.dart';
import '../../../core/safety/support_button.dart';
import '../../../core/widgets/mind_button.dart';
import '../../../core/widgets/mind_card.dart';
import '../../../core/widgets/mind_pressable.dart';
import '../../investigation/presentation/widgets/vagal_breathing_visualizer.dart';
import 'widgets/quick_calm_breathing_sheet.dart';
import 'widgets/reframe_drill_card.dart';

/// Nervous System Regulation & Perspective Practice Tools Screen.
///
/// Embodies MindTokens, shared [ReframeDrillCard] & [showQuickCalmBreathingSheet],
/// inline 4-4-4-4 vagal pacing with stop-anytime control, and localized crisis lines.
class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  bool _isBreathing = false;
  int _phaseIndex = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Rest
  int _secondsLeft = 4;
  Timer? _breathTimer;

  @override
  void dispose() {
    _breathTimer?.cancel();
    super.dispose();
  }

  void _toggleBreathing() {
    HapticFeedback.selectionClick();
    if (_isBreathing) {
      _breathTimer?.cancel();
      setState(() {
        _isBreathing = false;
        _phaseIndex = 0;
        _secondsLeft = 4;
      });
    } else {
      setState(() {
        _isBreathing = true;
        _phaseIndex = 0;
        _secondsLeft = 4;
      });
      _breathTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_secondsLeft > 1) {
            _secondsLeft--;
          } else {
            _secondsLeft = 4;
            _phaseIndex = (_phaseIndex + 1) % 4;
          }
        });
      });
    }
  }

  Future<void> _dialHotline(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _localizedPhase(AppStrings strings) {
    switch (_phaseIndex) {
      case 0:
        return strings.breatheIn;
      case 1:
        return strings.breatheHold;
      case 2:
        return strings.breatheOut;
      case 3:
      default:
        return strings.breatheRest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          strings.toolsTitle.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: 0.8,
            color: tokens.textPrimary,
          ),
        ),
        actions: const [
          SupportButton(),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          _buildQuickCalmCard(context, tokens, strings),
          const SizedBox(height: 16),
          const ReframeDrillCard(),
          const SizedBox(height: 16),
          _buildBreathingCard(tokens, strings, isDark),
          const SizedBox(height: 16),
          _buildCrisisHubCard(tokens, strings),
        ],
      ),
    );
  }

  Widget _buildQuickCalmCard(
    BuildContext context,
    MindTokens tokens,
    AppStrings strings,
  ) {
    return Semantics(
      button: true,
      label: '${strings.quickCalmTitle}. ${strings.quickCalmSub}',
      child: MindPressable(
        onPressed: () {
          HapticFeedback.lightImpact();
          showQuickCalmBreathingSheet(context, strings);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.air_rounded, color: tokens.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.quickCalmTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.quickCalmSub,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: tokens.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingCard(
    MindTokens tokens,
    AppStrings strings,
    bool isDark,
  ) {
    return MindCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.waves_rounded,
                  color: tokens.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.breathingTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.breathingDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: VagalBreathingVisualizer(
              phase: _isBreathing ? _phaseIndex : 0,
              secondsLeft: _secondsLeft,
              phaseText: _localizedPhase(strings),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              strings.pacerSub,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          MindButton(
            text: _isBreathing ? strings.stopPacer : strings.startPacer,
            variant: _isBreathing
                ? MindButtonVariant.secondary
                : MindButtonVariant.primary,
            leadingIcon: _isBreathing
                ? Icons.stop_rounded
                : Icons.play_arrow_rounded,
            isFullWidth: true,
            onPressed: _toggleBreathing,
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisHubCard(MindTokens tokens, AppStrings strings) {
    final lines =
        CrisisResource.tunisianResources.where((r) => r.phone.isNotEmpty);

    return MindCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: tokens.surface,
      borderColor: tokens.safetyWarmth.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.safetyWarmthSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.health_and_safety_outlined,
                  color: tokens.safetyWarmth,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.tunisianHotlinesTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.tunisianHotlinesDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lines.map(
            (resource) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          resource.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  MindPressable(
                    onPressed: () => _dialHotline(resource.phone),
                    borderRadius: BorderRadius.circular(12),
                    semanticLabel: '${resource.name} ${resource.phone}',
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 72,
                        minHeight: 48,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.safetyWarmthSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tokens.safetyWarmth.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.call_rounded,
                            size: 16,
                            color: tokens.safetyWarmth,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            resource.phone,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: tokens.safetyWarmth,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
