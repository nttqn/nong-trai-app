import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/village.dart';

/// A save written by the 24x24 version (no 'map' key, 4 lots per side).
Map<String, dynamic> legacySave() {
  final f = Farm.fresh(now: () => 1000);
  final j = f.toJson()..remove('map');
  // renumber lots the old way and drop everything outside the old map
  j['lots'] = [for (final l in f.lots) (l % lotsPerSide) + (l ~/ lotsPerSide) * 4];
  j['objs'] = [
    for (final o in f.objs)
      if (o.x < legacyMapSize && o.y < legacyMapSize) o.toJson(),
  ];
  return j;
}

void main() {
  test('old saves keep their land and get obstacles on the new lots', () {
    final j = legacySave();
    expect(j['lots'], containsAll([5, 6])); // (1,1) and (2,1) on the 4-wide grid
    final f = Farm.fromJson(j, now: () => 1000);
    expect(f.lots, {Farm.lotIndex(1, 1), Farm.lotIndex(2, 1)});
    expect(f.owned(6, 6), isTrue); // the house is still on owned land
    final outer = f.objs.where((o) => o.x >= legacyMapSize || o.y >= legacyMapSize).toList();
    expect(outer.length, greaterThan(40));
    expect(outer.every((o) => o.def.kind == BKind.obstacle), isTrue);
    // nothing overlaps, nothing in water
    final seen = <int>{};
    for (final o in f.objs) {
      for (var dx = 0; dx < o.w; dx++) {
        for (var dy = 0; dy < o.h; dy++) {
          expect(seen.add((o.x + dx) + (o.y + dy) * mapSize), isTrue, reason: '${o.type} overlaps');
          if (Farm.spansRoad(o.type)) continue;
          expect(Farm.terrain(o.x + dx, o.y + dy), 'grass');
        }
      }
    }
    // saved again: migrated once only
    final again = Farm.fromJson(f.toJson(), now: () => 1000);
    expect(again.objs.length, f.objs.length);
    expect(again.lots, f.lots);
  });

  test('neighbour snapshots from old versions are moved over too', () {
    final j = legacySave();
    final snap = {'v': 1, 'name': 'X', 'level': 3, 'lots': j['lots'], 'objs': j['objs'], 'projects': const []};
    final f = farmFromVillage(snap, now: () => 1000);
    expect(f.lots, {Farm.lotIndex(1, 1), Farm.lotIndex(2, 1)});
    final g = farmFromVillage(villageSnapshot(f), now: () => 1000);
    expect(g.lots, f.lots);
    expect(g.objs.length, f.objs.length);
  });

  test('outer lots open from level 21 and can be bought next to owned land', () {
    final f = Farm.fresh(now: () => 1000);
    expect(lotLevel(16), 21);
    expect(lotPrice(35), greaterThan(lotPrice(34)));
    // own the whole old 4x4 block, then the ring next to it is buyable
    for (var ly = 0; ly < 4; ly++) {
      for (var lx = 0; lx < 4; lx++) {
        f.lots.add(Farm.lotIndex(lx, ly));
      }
    }
    f.level = 21;
    f.coins = 1 << 30;
    expect(f.canBuyLot(Farm.lotIndex(4, 0)), isNull);
    expect(f.canBuyLot(Farm.lotIndex(5, 0)), isNotNull); // not adjacent yet
    expect(f.buyLot(Farm.lotIndex(4, 0)), isNull);
    expect(f.owned(26, 3), isTrue);
  });

  test('the lake is water, its shore is farmland', () {
    expect(Farm.terrain(29, 29), 'water');
    expect(Farm.terrain(25, 25), 'grass');
    expect(Farm.terrain(11, 33), 'road');
  });
}
