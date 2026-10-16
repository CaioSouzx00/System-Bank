import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheStorageService {
  final SharedPreferences _prefs;

  CacheStorageService(this._prefs);

  static const String _keyCachedAccounts = 'sb_cached_accounts';
  static const String _keyCachedTransactions = 'sb_cached_transactions';
  static const String _keyThemeMode = 'sb_theme_mode';
  static const String _keyCustomBaseUrl = 'sb_custom_base_url';
  static const String _keyHideBalance = 'sb_hide_balance';

  // Accounts cache (JSON string)
  Future<void> cacheAccountsJson(String jsonString) async {
    await _prefs.setString(_keyCachedAccounts, jsonString);
  }

  String? getCachedAccountsJson() {
    return _prefs.getString(_keyCachedAccounts);
  }

  // Transactions cache
  Future<void> cacheTransactionsJson(String jsonString) async {
    await _prefs.setString(_keyCachedTransactions, jsonString);
  }

  String? getCachedTransactionsJson() {
    return _prefs.getString(_keyCachedTransactions);
  }

  // Theme mode: 'light', 'dark', 'system'
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  // Custom Base URL
  Future<void> setCustomBaseUrl(String url) async {
    await _prefs.setString(_keyCustomBaseUrl, url);
  }

  String? getCustomBaseUrl() {
    return _prefs.getString(_keyCustomBaseUrl);
  }

  // Hide/Show balance preference
  Future<void> setHideBalance(bool hide) async {
    await _prefs.setBool(_keyHideBalance, hide);
  }

  bool isBalanceHidden() {
    return _prefs.getBool(_keyHideBalance) ?? false;
  }

  Future<void> clearCache() async {
    await _prefs.remove(_keyCachedAccounts);
    await _prefs.remove(_keyCachedTransactions);
  }
}
