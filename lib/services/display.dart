// Display settings kept on the phone: how dark the night scene gets.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/daynight.dart';

class DisplayService {
  DisplayService._();
  static final instance = DisplayService._();

  /// 0 = no night look, 1 = soft (default), 2 = deep (the 1.1.0 look).
  final ValueNotifier<int> nightMode = ValueNotifier<int>(1);

  static const names = ['Tắt', 'Dịu', 'Đậm'];

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apply(prefs.getInt('night_mode') ?? 1);
    } catch (_) {}
  }

  Future<void> setNightMode(int m) async {
    _apply(m);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('night_mode', m);
    } catch (_) {}
  }

  void _apply(int m) {
    m = m.clamp(0, 2);
    nightMode.value = m;
    nightLook = const [0.0, .45, 1.0][m];
  }
}
