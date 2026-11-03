import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../core/farm.dart';

class SaveService {
  static const _key = 'farm_v1', _bakKey = 'farm_v1_bak';
  SharedPreferences? _prefs;
  Timer? _debounce;

  Future<Farm> load() async {
    try {
      _prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 6));
      for (final k in [_key, _bakKey]) {
        final s = _prefs!.getString(k);
        if (s == null) continue;
        try {
          return Farm.fromJson(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {
          // corrupt: fall back to the backup copy
        }
      }
    } catch (_) {
      // prefs unavailable: play without saving
    }
    return Farm.fresh(seed: math.Random().nextInt(1 << 30));
  }

  void schedule(Farm f) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () => saveNow(f));
  }

  Future<void> saveNow(Farm f) async {
    _debounce?.cancel();
    final p = _prefs;
    if (p == null) return;
    final s = jsonEncode(f.toJson());
    final old = p.getString(_key);
    if (old != null) await p.setString(_bakKey, old);
    await p.setString(_key, s);
  }

  Future<void> reset() async {
    await _prefs?.remove(_key);
    await _prefs?.remove(_bakKey);
  }
}
