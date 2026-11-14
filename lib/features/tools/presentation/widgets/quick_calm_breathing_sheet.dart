import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/mind_tokens.dart';
import '../../../../core/widgets/mind_button.dart';
import '../../../investigation/presentation/widgets/vagal_breathing_visualizer.dart';

/// Opens a focused Quick Calm 4-4-4-4 box breathing modal bottom sheet with a
/// non-pressuring "stop anytime" control.
Future<void> showQuickCalmBreathingSheet(
  BuildContext context,
  AppStrings strings,
) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tokens.background.withValues(alpha: 0.0),
    builder: (_) => _QuickCalmBreathingSheet(strings: strings),
  );
}

class _QuickCalmBreathingSheet extends StatefulWidget {
  const _QuickCalmBreathingSheet({required this.strings});

  final AppStrings strings;

  @override
  State<_QuickCalmBreathingSheet> createState() =>
      _QuickCalmBreathingSheetState();
}

class _QuickCalmBreathingSheetState extends State<_QuickCalmBreathingSheet> {
  bool _isActive = false;
  int _phase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Rest
  int _secondsLeft = 4;
  Timer? _timer;

  void _toggle() {
    HapticFeedback.mediumImpact();
    if (_isActive) {
      _stop();
    } else {
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _isActive = true;
      _phase = 0;
      _secondsLeft = 4;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _phase = (_phase + 1) % 4;
          _secondsLeft = 4;
          HapticFeedback.lightImpact();
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _phase = 0;
      _secondsLeft = 4;
    });
  }

  String _phaseLabel() {
    switch (_phase) {
      case 0:
        return widget.strings.breatheIn;
      case 1:
        return widget.strings.breatheHold;
      case 2:
        return widget.strings.breatheOut;
      case 3:
      default:
        return widget.strings.breatheRest;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(tokens.cardRadius)),
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.quickCalmTitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.quickCalmSub,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            VagalBreathingVisualizer(
              phase: _phase,
              secondsLeft: _secondsLeft,
              phaseText: _phaseLabel(),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Text(
              s.pacerSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            MindButton(
              text: _isActive ? s.stopPacer : s.startPacer,
              leadingIcon:
                  _isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
              variant: _isActive
                  ? MindButtonVariant.secondary
                  : MindButtonVariant.primary,
              isFullWidth: true,
              onPressed: _toggle,
            ),
          ],
        ),
      ),
    );
  }
}
