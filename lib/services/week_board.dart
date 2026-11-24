// Weekly leaderboards: the event's (Firestore `weekly/{week}/rows/{uid}`)
// and, since 1.9.0, Đua top câu cá (`fishing/{week}/rows/{uid}`). One row
// per signed-in player with a farm name who has points this week. A new
// week is a new collection, so nothing has to be cleaned up.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/farm.dart';
import 'cloud.dart';
import 'leaderboard.dart';

class WeekRow {
  final String uid, name;
  final int level, pts;
  const WeekRow(this.uid, this.name, this.level, this.pts);

  static WeekRow? fromDoc(String id, Map<String, dynamic> m) {
    try {
      return WeekRow(id, m['name'] as String, (m['level'] as num).toInt(), (m['pts'] as num).toInt());
    } catch (_) {
      return null;
    }
  }
}

class WeekBoard {
  WeekBoard._(this.collection, this.board, this._week, this._pts);

  /// Sự kiện tuần.
  static final WeekBoard instance = WeekBoard._('weekly', 0, (f) => f.weekKey, (f) => f.weekPts);

  /// Đua top câu cá.
  static final WeekBoard fishing = WeekBoard._('fishing', 1, (f) => f.fishWeek, (f) => f.fishPts);

  final String collection;

  /// Index in Farm.rankDue / rankDone.
  final int board;
  final int Function(Farm) _week, _pts;
  int weekOf(Farm f) => _week(f);
  int ptsOf(Farm f) => _pts(f);

  CloudSave get _cloud => CloudSave.instance;
  String? get myUid => _cloud.user?.uid;
  String? _sent;

  CollectionReference<Map<String, dynamic>> _rows(int week) =>
      FirebaseFirestore.instance.collection(collection).doc('$week').collection('rows');

  bool get canSubmit => _cloud.available && myUid != null && !Leaderboard.instance.hidden;

  /// Writes this week's points when they changed.
  Future<void> submit(Farm f) async {
    final uid = myUid;
    final week = _week(f), pts = _pts(f);
    if (!canSubmit || uid == null || f.name.trim().isEmpty || pts <= 0 || week != f.weekNow) return;
    final key = '$week|$pts|${f.level}|${f.name}';
    if (key == _sent) return;
    try {
      await _rows(week).doc(uid).set({
        'name': f.name.length > 24 ? f.name.substring(0, 24) : f.name,
        'level': f.level,
        'pts': pts,
        'updated': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      _sent = key;
    } catch (e) {
      debugPrint('$collection board submit failed: $e');
    }
  }

  Future<List<WeekRow>> top(int week, {int limit = 30}) async {
    final snap = await _rows(week).orderBy('pts', descending: true).limit(limit).get().timeout(const Duration(seconds: 12));
    return [for (final d in snap.docs) ?WeekRow.fromDoc(d.id, d.data())];
  }

  /// 1-based place of [pts] this week.
  Future<int?> rankOf(int week, int pts) async {
    try {
      final agg = await _rows(week).where('pts', isGreaterThan: pts).count().get().timeout(const Duration(seconds: 10));
      return (agg.count ?? 0) + 1;
    } catch (e) {
      debugPrint('week rank failed: $e');
      return null;
    }
  }

  /// Removes this player's row of [week] (hiding, deleting the account).
  Future<void> withdraw(int week) async {
    final uid = myUid;
    _sent = null;
    if (!_cloud.available || uid == null || week == 0) return;
    try {
      await _rows(week).doc(uid).delete().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('week board withdraw failed: $e');
    }
  }
}
