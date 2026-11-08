import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/defs.dart';
import '../core/farm.dart';
import '../core/village.dart';
import 'analytics.dart';
import 'cloud.dart';
import 'leaderboard.dart';
import 'market.dart';

/// A village on the region map.
class VillageInfo {
  final String uid, name;
  final int level, house;
  final String title;
  const VillageInfo(this.uid, this.name, this.level, this.house, [this.title = '']);
}

/// Neighbours: each signed-in player's farm is published (layout only) to
/// `villages/{uid}`; visitors write what they did to
/// `visits/{owner}/events/{visitor_obj_start_kind}` (create-only, so one
/// action per visitor per harvest), and the owner applies them later.
class Neighbors extends ChangeNotifier {
  Neighbors._();
  static final Neighbors instance = Neighbors._();

  CloudSave get _cloud => CloudSave.instance;
  bool get available => _cloud.available && _cloud.user != null;
  String? get myUid => _cloud.user?.uid;

  CollectionReference<Map<String, dynamic>> get _villages => FirebaseFirestore.instance.collection('villages');
  CollectionReference<Map<String, dynamic>> _events(String owner) =>
      FirebaseFirestore.instance.collection('visits').doc(owner).collection('events');

  /// Lines for the "Hàng xóm ghé thăm" note, shown then cleared by the UI.
  final List<String> inbox = [];

  // ------------------------------------------------------------ publish

  String? _sent;

  /// Called with every cloud upload: the public copy of this farm.
  Future<void> publish(Farm f) async {
    final uid = myUid;
    if (!available || uid == null) return;
    // no name yet: just don't publish (an unnamed fresh farm used to
    // delete the player's village here)
    if (f.name.trim().isEmpty) return;
    if (Leaderboard.instance.hidden) {
      if (_sent != '') {
        _sent = '';
        try {
          await _villages.doc(uid).delete();
        } catch (_) {}
      }
      return;
    }
    final snap = villageSnapshot(f);
    final key = snap.toString();
    if (key == _sent) return;
    try {
      await _villages.doc(uid).set({...snap, 'updated': FieldValue.serverTimestamp()}).timeout(const Duration(seconds: 12));
      _sent = key;
    } catch (e) {
      debugPrint('village publish failed: $e');
    }
  }

  Future<void> withdraw() async {
    final uid = myUid;
    _sent = null;
    if (!available || uid == null) return;
    try {
      await _villages.doc(uid).delete();
    } catch (_) {}
    // visits other players left on this farm (help, steal, caught)
    try {
      final ev = await FirebaseFirestore.instance.collection('visits').doc(uid).collection('events').get();
      for (final d in ev.docs) {
        await d.reference.delete();
      }
    } catch (_) {}
  }

  // ------------------------------------------------------------ browse

  /// The most recently active villages (this player's own first if there).
  Future<List<VillageInfo>> nearby({int limit = 40}) async {
    final snap = await _villages.orderBy('updated', descending: true).limit(limit).get().timeout(const Duration(seconds: 12));
    final out = <VillageInfo>[];
    for (final d in snap.docs) {
      final m = d.data();
      final name = m['name'];
      if (name is! String || name.isEmpty) continue;
      out.add(VillageInfo(d.id, name, (m['level'] as num?)?.toInt() ?? 1, (m['house'] as num?)?.toInt() ?? 0,
          m['title'] is String ? m['title'] as String : ''));
    }
    out.sort((a, b) => (b.uid == myUid ? 1 : 0).compareTo(a.uid == myUid ? 1 : 0));
    return out;
  }

  Future<Farm?> load(String uid) async {
    final d = await _villages.doc(uid).get().timeout(const Duration(seconds: 12));
    final m = d.data();
    if (m == null) return null;
    try {
      return farmFromVillage(m);
    } catch (e) {
      debugPrint('village unreadable: $e');
      return null;
    }
  }

  // ------------------------------------------------------------ act

  /// Records an action on [owner]'s farm. False when this visitor already
  /// did it to this harvest (the event id exists) or the write failed.
  Future<bool> send(String owner, String kind, Obj o, String product, {int fine = 0}) async {
    final me = myUid;
    if (!available || me == null || me == owner) return false;
    final id = '${me}_${o.id}_${o.start}_$kind';
    try {
      await _events(owner).doc(id).set({
        'from': me,
        'name': _myName,
        'kind': kind,
        'obj': o.id,
        'start': o.start,
        'item': product,
        'fine': fine,
        'at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      Analytics.instance.log('neighbor_$kind', {'item': product});
      return true;
    } catch (e) {
      debugPrint('visit event failed: $e');
      return false;
    }
  }

  String _myName = 'Hàng xóm';
  String get myName => _myName;
  void setMyName(String n) => _myName = n.isEmpty ? 'Hàng xóm' : n;

  // ------------------------------------------------------------ inbox

  DateTime _lastPull = DateTime.fromMillisecondsSinceEpoch(0);

  /// Owner side: applies neighbours' actions to [f] and fills [inbox].
  Future<void> pull(Farm f, {bool force = false}) async {
    final uid = myUid;
    if (!available || uid == null) return;
    if (!force && DateTime.now().difference(_lastPull) < const Duration(minutes: 2)) return;
    _lastPull = DateTime.now();
    final sold = await Market.instance.collect(f);
    inbox.addAll(sold);
    if (sold.isNotEmpty) notifyListeners();
    try {
      final snap = await _events(uid).limit(100).get().timeout(const Duration(seconds: 12));
      if (snap.docs.isEmpty) return;
      final helped = <String, int>{}, stole = <String, Map<String, int>>{};
      var fines = 0;
      final fined = <String>{};
      for (final d in snap.docs) {
        final e = VisitEvent.fromDoc(d.id, d.data());
        if (e != null && f.applyVisit(e.kind, e.objId, e.start, fine: e.fine)) {
          switch (e.kind) {
            case 'help':
              helped[e.fromName] = (helped[e.fromName] ?? 0) + 1;
            case 'steal':
              (stole[e.fromName] ??= {})[e.product] = (stole[e.fromName]![e.product] ?? 0) + 1;
            case 'caught':
              fines += e.fine;
              fined.add(e.fromName);
          }
        }
        unawaited(d.reference.delete().catchError((_) {}));
      }
      helped.forEach((who, n) => inbox.add('🤝 $who đã thu hoạch hộ $n chỗ'));
      stole.forEach((who, m) => inbox.add(
          '🧺 $who đã hái trộm ${m.entries.map((e) => '${e.value} ${items[e.key]?.name.toLowerCase() ?? e.key}').join(', ')}'));
      if (fines > 0) inbox.add('🪧 Bù nhìn bắt quả tang ${fined.join(', ')}: bạn nhận ${fmtNum(fines)} xu tiền phạt');
      if (inbox.isNotEmpty) notifyListeners();
    } catch (e) {
      debugPrint('visit inbox failed: $e');
    }
  }

  /// A steal at a farm with [catchChance] gets caught.
  static bool caught(double catchChance, math.Random rng) => rng.nextDouble() < catchChance;
}
