import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics: how far players get and where they stop. No user ID
/// is set, so events stay tied to an app-instance ID only. A no-op on web,
/// in tests, and before Firebase is configured (no google-services.json).
class Analytics {
  Analytics._();
  static final Analytics instance = Analytics._();

  FirebaseAnalytics? get _fa {
    if (kIsWeb) return null;
    try {
      return Firebase.apps.isEmpty ? null : FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  void log(String name, [Map<String, Object>? params]) {
    try {
      _fa?.logEvent(name: name, parameters: params).catchError((Object e) => debugPrint('analytics $name: $e'));
    } catch (e) {
      debugPrint('analytics $name: $e');
    }
  }

  void levelUp(int level) {
    try {
      _fa?.logLevelUp(level: level).catchError((_) {});
    } catch (_) {}
  }
}
