import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported application languages with clean typographic badges (no emojis).
enum AppLanguage {
  english(code: 'en', displayName: 'English', shortCode: 'EN'),
  french(code: 'fr', displayName: 'Français', shortCode: 'FR'),
  arabic(code: 'ar', displayName: 'العربية', shortCode: 'AR');

  const AppLanguage({
    required this.code,
    required this.displayName,
    required this.shortCode,
  });

  final String code;
  final String displayName;
  final String shortCode;
}

/// Notifier managing active language with persistence.
class LocaleController extends Notifier<Locale> {
  static const String _keyLocale = 'mind_forensics_locale';
  bool _hasExplicitSelection = false;

  @override
  Locale build() {
    _hasExplicitSelection = false;
    _loadSavedLocale();
    return const Locale('en');
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    if (_hasExplicitSelection) return;
    final saved = prefs.getString(_keyLocale);
    if (saved != null && !_hasExplicitSelection) {
      state = Locale(saved);
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _hasExplicitSelection = true;
    state = Locale(language.code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, language.code);
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
