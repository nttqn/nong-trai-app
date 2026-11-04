import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/quests.dart';
import 'package:nong_trai/core/sync_plan.dart';
import 'package:nong_trai/render/farm_painter.dart';


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

  test('a village project built before its quest still counts', () {
    final f = Farm.fresh(now: () => 1000, seed: 3);
    f.stats['project:gieng'] = 1;
    f.quest = questChain.indexWhere((q) => q.key == 'project:gieng');
    f.questBase = 1; // baseline taken when the quest came up
    expect(f.questDone, isTrue);
  });

  test('the village gate only stands across the road; old saves move onto it', () {
    final f = Farm.fresh(now: () => 1000, seed: 3);
    f.objs.removeWhere((o) => o.def.kind == BKind.obstacle);
    // Starting lots cover rows 6-11 on both sides of the road.
    expect(f.canPlace('cong_lang', 12, 8), isFalse); // off the road
    expect(f.canPlace('cong_lang', 10, 8), isTrue); // pillars at x 10 and 12
    expect(Farm.snapX('cong_lang', 7), 10);
    expect(Farm.snapX('chuong_ga', 7), 7);
    // A gate saved on plain grass is moved onto the road when loaded.
    final j = f.toJson();
    (j['objs'] as List).add({'i': 999, 't': 'cong_lang', 'x': 13, 'y': 9});
    final g = Farm.fromJson(jsonDecode(jsonEncode(j)) as Map<String, dynamic>);
    final gate = g.objs.firstWhere((o) => o.type == 'cong_lang');
    expect(gate.x, 10);
    expect(g.canPlace('cong_lang', gate.x, gate.y, ignore: gate.id), isTrue);
  });

  test('a tap on a ready bubble selects its owner even behind a building', () {
    var t = 1000;
    final f = Farm.fresh(now: () => t, seed: 3);
    f.coins = 100000;
    f.level = 30;
    late Obj tree;
    outer:
    for (var y = 0; y < mapSize; y++) {
      for (var x = 0; x < mapSize; x++) {
        if (f.canPlace('cay_chuoi', x, y) && f.build('cay_chuoi', x, y) == null) {
          tree = f.objs.last;
          break outer;
        }
      }
    }
    t = tree.end + 1; // ripe
    expect(bubbleIcon(f, tree), isNotNull);
    expect(hitTest(f, bubbleAt(worldIso, tree) + const Offset(6, 4)), same(tree));
  });
}
