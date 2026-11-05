import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../core/farm.dart';

class SaveService {
  static const _key = 'farm_v1', _bakKey = 'farm_v1_bak';
  /// Saves that could not be read are parked here and never overwritten,
  /// so a bug in a new version can be fixed and the farm still recovered.
  static const _brokenKey = 'farm_broken', _brokenBakKey = 'farm_broken_bak', _brokenErrKey = 'farm_broken_err';

  /// Why the saved farm could not be loaded (shown to the player), or null.
  String? loadError;
  SharedPreferences? _prefs;
  Timer? _debounce;

  /// The farm on screen. Saves of any other Farm object are ignored, so a
  /// screen closing after a cloud restore cannot write the old farm back.
  Farm? active;

  /// Called after every save that changed something (cloud upload queue).
  static void Function()? onSaved;

  Future<Farm> load() async {
    try {
      _prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 6));
      final p = _prefs!;
      // a parked save from an earlier failed load comes first: once a
      // version can read it again, the farm is back
      for (final k in [_brokenKey, _brokenBakKey, _key, _bakKey]) {
        final s = p.getString(k);
        if (s == null) continue;
        try {
          final f = Farm.fromJson(jsonDecode(s) as Map<String, dynamic>);
          if (k == _brokenKey || k == _brokenBakKey) {
            final cur = _levelOf(p.getString(_key));
            if (cur != null && cur > f.level) continue; // played on past it
            await p.setString(_key, s);
            await p.remove(_brokenKey);
            await p.remove(_brokenBakKey);
            await p.remove(_brokenErrKey);
          }
          return f;
        } catch (e) {
          if (k == _key || k == _bakKey) {
            loadError = '$e';
            // park it before anything can overwrite it
            if (p.getString(k == _key ? _brokenKey : _brokenBakKey) == null) {
              await p.setString(k == _key ? _brokenKey : _brokenBakKey, s);
              await p.setString(_brokenErrKey, '$e');
            }
          }
        }
      }
    } catch (_) {
      // prefs unavailable: play without saving
    }
    return Farm.fresh(seed: math.Random().nextInt(1 << 30));
  }

  static int? _levelOf(String? s) {
    if (s == null) return null;
    try {
      return ((jsonDecode(s) as Map)['level'] as num).toInt();
    } catch (_) {
      return null;
    }
  }

  void schedule(Farm f) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () => saveNow(f));
  }

  /// Writes [f]. [Farm.savedAt] is stamped only when something changed, so
  /// merely opening the game never makes this copy look newer than the
  /// cloud's. [keepStamp]: write as-is (a farm restored from the cloud).
  Future<void> saveNow(Farm f, {bool keepStamp = false}) async {
    _debounce?.cancel();
    final p = _prefs;
    if (p == null || _wiped || (active != null && !identical(f, active))) return;
    final old = p.getString(_key);
    if (!keepStamp) {
      if (old != null && jsonEncode(f.toJson()) == old) return;
      f.savedAt = math.max(DateTime.now().millisecondsSinceEpoch, f.savedAt + 1);
    }
    final s = jsonEncode(f.toJson());
    if (s == old) return;
    if (old != null) await p.setString(_bakKey, old);
    await p.setString(_key, s);
    if (!keepStamp) onSaved?.call();
  }

  /// After [reset] nothing is saved again until the app restarts (the
  /// closing screen would otherwise write the old farm back).
  bool _wiped = false;

  Future<void> reset() async {
    _wiped = true;
    _debounce?.cancel();
    await _prefs?.remove(_key);
    await _prefs?.remove(_bakKey);
  }
}
