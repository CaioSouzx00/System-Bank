import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeModeNotifier(this._ref) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final cache = _ref.read(cacheStorageProvider);
    final saved = cache.getThemeMode();
    switch (saved) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'system':
      default:
        state = ThemeMode.system;
        break;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    final cache = _ref.read(cacheStorageProvider);
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    cache.setThemeMode(modeStr);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});
