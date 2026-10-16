import 'package:flutter/services.dart';

class HapticFeedbackUtils {
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> successFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> errorFeedback() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
