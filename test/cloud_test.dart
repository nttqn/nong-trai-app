import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/sync_plan.dart';

void main() {
  group('planSync', () {
    const a = SaveInfo(1000, 5, 10);
    test('no cloud copy: upload', () {
      expect(planSync(local: a, mine: false, syncedAt: 0, cloud: null), SyncAction.upload);
      expect(planSync(local: a, mine: true, syncedAt: 900, cloud: null), SyncAction.upload);
    });
    test('first sign-in on a new phone takes the account farm', () {
      const fresh = SaveInfo(50, 1, 0);
      expect(planSync(local: fresh, mine: false, syncedAt: 0, cloud: a), SyncAction.restore);
    });
    test('first sign-in with progress on both sides asks', () {
      const other = SaveInfo(2000, 8, 0);
      expect(planSync(local: other, mine: false, syncedAt: 0, cloud: a), SyncAction.ask);
    });
    test('same account: device ahead uploads, cloud ahead restores', () {
      const later = SaveInfo(1500, 6, 0);
      expect(planSync(local: later, mine: true, syncedAt: 1000, cloud: a), SyncAction.upload);
      const old = SaveInfo(800, 4, 0);
      expect(planSync(local: old, mine: true, syncedAt: 800, cloud: a), SyncAction.restore);
      expect(planSync(local: a, mine: true, syncedAt: 1000, cloud: a), SyncAction.none);
    });
    test('both changed since the last sync: ask', () {
      const here = SaveInfo(900, 4, 0); // played offline after syncing at 800
      expect(planSync(local: here, mine: true, syncedAt: 800, cloud: a), SyncAction.ask);
    });
  });

  test('speedUp finishes a crop; savedAt round-trips; build logs an event', () {
    var t = 1000000;
    final f = Farm.fresh(now: () => t, seed: 3);
    final p = f.objs.firstWhere((o) => o.type == 'ruong');
    expect(f.speedUpMs(p), 0);
    expect(f.speedUp(p), isNotNull);
    expect(f.plant(p, 'lua'), isNull);
    expect(f.speedUpMs(p), greaterThan(0));
    expect(f.speedUp(p), isNull);
    expect(f.isReady(p), isTrue);
    expect(f.harvest(p), isNull);

    f.savedAt = 123456;
    final g = Farm.fromJson(jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>);
    expect(g.savedAt, 123456);

    final events = <String>[];
    f.onEvent = (n, _) => events.add(n);
    f.coins = 100000;
    f.level = 30;
    f.lots.addAll(List.generate(30, (i) => i));
    // any buildable workshop on free grass
    expect(f.build('may_xay', 3, 3) == null || f.build('may_xay', 18, 3) == null || f.build('may_xay', 3, 18) == null, isTrue);
    expect(events, contains('build'));
  });
}
