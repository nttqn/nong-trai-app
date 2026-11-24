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

  int _sentWeek = 0;
  DateTime? _sentAt;

  /// Writes this week's points when they changed: at most every
  /// [Leaderboard.quiet] within a week unless [force]d (the board opened).
  Future<void> submit(Farm f, {bool force = false}) async {
    final uid = myUid;
    final week = _week(f), pts = _pts(f);
    if (!canSubmit || uid == null || f.name.trim().isEmpty || pts <= 0 || week != f.weekNow) return;
    final key = '$week|$pts|${f.level}|${f.name}';
    if (key == _sent) return;
    final at = _sentAt;
    if (!force && week == _sentWeek && at != null && DateTime.now().difference(at) < Leaderboard.quiet) return;
    try {
      await _rows(week).doc(uid).set({
        'name': f.name.length > 24 ? f.name.substring(0, 24) : f.name,
        'level': f.level,
        'pts': pts,
        'updated': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      _sent = key;
      _sentWeek = week;
      _sentAt = DateTime.now();
    } catch (e) {
      debugPrint('$collection board submit failed: $e');
    }
  }

  /// Rows per page of [top].
  static const int pageSize = 50;

  /// One page of [week]'s board from the top, or the rows after [after]
  /// (the `next` of the page before; null at the end).
  Future<(List<WeekRow> rows, Object? next)> top(int week, {Object? after, int limit = pageSize}) async {
    Query<Map<String, dynamic>> q = _rows(week).orderBy('pts', descending: true);
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);
    final snap = await q.limit(limit).get().timeout(const Duration(seconds: 12));
    return (
      [for (final d in snap.docs) ?WeekRow.fromDoc(d.id, d.data())],
      snap.docs.length == limit ? snap.docs.last : null,
    );
  }

  /// The rows around [pts] in [week]: up to [span] above, then it and up to
  /// [span] below. The caller numbers them from its place.
  Future<(List<WeekRow> above, List<WeekRow> rest)> around(int week, int pts, {int span = 10}) async {
    final up = await _rows(week)
        .where('pts', isGreaterThan: pts)
        .orderBy('pts')
        .limit(span)
        .get()
        .timeout(const Duration(seconds: 12));
    final down = await _rows(week)
        .where('pts', isLessThanOrEqualTo: pts)
        .orderBy('pts', descending: true)
        .limit(span + 1)
        .get()
        .timeout(const Duration(seconds: 12));
    return (
      [for (final d in up.docs.reversed) ?WeekRow.fromDoc(d.id, d.data())],
      [for (final d in down.docs) ?WeekRow.fromDoc(d.id, d.data())],
    );
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
    _sentAt = null;
    if (!_cloud.available || uid == null || week == 0) return;
    try {
      await _rows(week).doc(uid).delete().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('week board withdraw failed: $e');
    }
  }
}
