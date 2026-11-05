import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/farm.dart';
import 'cloud.dart';
import 'neighbors.dart';

enum LbBoard { level, orders, village }

extension LbBoardInfo on LbBoard {
  String get field => switch (this) {
        LbBoard.level => 'score',
        LbBoard.orders => 'orders',
        LbBoard.village => 'village',
      };
  String get label => switch (this) {
        LbBoard.level => 'Cấp độ',
        LbBoard.orders => 'Đơn hàng',
        LbBoard.village => 'Nông thôn mới',
      };
}

/// One public row: a signed-in player's farm.
class LbEntry {
  final String uid, name;
  final int level, score, orders, village, house;
  const LbEntry(this.uid, this.name, this.level, this.score, this.orders, this.village, this.house);

  int projects() => village ~/ 1000;

  int valueOf(LbBoard b) => switch (b) {
        LbBoard.level => score,
        LbBoard.orders => orders,
        LbBoard.village => village,
      };

  static LbEntry? fromDoc(String id, Map<String, dynamic> m) {
    try {
      return LbEntry(
        id,
        m['name'] as String,
        (m['level'] as num).toInt(),
        (m['score'] as num).toInt(),
        (m['orders'] as num?)?.toInt() ?? 0,
        (m['village'] as num?)?.toInt() ?? 0,
        (m['house'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The row a farm puts on the board.
Map<String, Object> lbRow(Farm f) => {
      'name': f.name.length > 24 ? f.name.substring(0, 24) : f.name,
      'level': f.level,
      'score': f.level * 1000000 + f.xp.clamp(0, 999999),
      'orders': f.stats['order'] ?? 0,
      // Projects first, level breaks ties.
      'village': f.projects.length * 1000 + f.level.clamp(0, 999),
      'house': f.houseLevel,
    };

/// Public leaderboard in Firestore (`leaderboard/{uid}`), fed by the cloud
/// uploads of signed-in players who named their farm and did not hide.
class Leaderboard extends ChangeNotifier {
  Leaderboard._();
  static final Leaderboard instance = Leaderboard._();

  static const _hiddenKey = 'lb_hidden';
  bool hidden = false;
  String? _sent;

  CloudSave get _cloud => CloudSave.instance;
  String? get myUid => _cloud.user?.uid;
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance.collection('leaderboard');

  Future<void> load() async {
    try {
      hidden = (await SharedPreferences.getInstance()).getBool(_hiddenKey) ?? false;
    } catch (_) {}
  }

  /// This player's own row, if any.
  Future<LbEntry?> mine() async {
    final uid = myUid;
    if (!_cloud.available || uid == null) return null;
    try {
      final d = await _col.doc(uid).get().timeout(const Duration(seconds: 10));
      final m = d.data();
      return m == null ? null : LbEntry.fromDoc(uid, m);
    } catch (_) {
      return null;
    }
  }

  /// Writes this farm's row when something on it changed (or [force]).
  Future<void> submit(Farm f, {bool force = false}) async {
    final uid = myUid;
    if (!_cloud.available || uid == null || hidden || f.name.trim().isEmpty) return;
    final row = lbRow(f);
    final key = row.toString();
    if (!force && key == _sent) return;
    try {
      await _col.doc(uid).set({...row, 'updated': FieldValue.serverTimestamp()}).timeout(const Duration(seconds: 10));
      _sent = key;
    } catch (e) {
      debugPrint('leaderboard submit failed: $e');
    }
  }

  Future<List<LbEntry>> top(LbBoard b, {int limit = 50}) async {
    final snap = await _col.orderBy(b.field, descending: true).limit(limit).get().timeout(const Duration(seconds: 12));
    return [
      for (final d in snap.docs) ?LbEntry.fromDoc(d.id, d.data()),
    ];
  }

  /// 1-based place of [value] on [b] (players strictly ahead + 1).
  Future<int?> rankOf(LbBoard b, int value) async {
    try {
      final agg = await _col.where(b.field, isGreaterThan: value).count().get().timeout(const Duration(seconds: 10));
      return (agg.count ?? 0) + 1;
    } catch (e) {
      debugPrint('rank failed: $e');
      return null;
    }
  }

  /// Removes this player's row (hiding, wiping, deleting the account).
  Future<void> withdraw() async {
    final uid = myUid;
    _sent = null;
    if (!_cloud.available || uid == null) return;
    try {
      await _col.doc(uid).delete().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('leaderboard withdraw failed: $e');
    }
  }

  Future<void> setHidden(bool v, Farm f) async {
    hidden = v;
    try {
      await (await SharedPreferences.getInstance()).setBool(_hiddenKey, v);
    } catch (_) {}
    notifyListeners();
    if (v) {
      await withdraw();
    } else {
      await submit(f, force: true);
    }
    await Neighbors.instance.publish(f);
  }
}
