import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';

const wave2 = ['tram_nuoc', 'khuyen_nong', 'den_duong', 'htx', 'san_bong', 'buu_dien'];

/// The level at which a good can first be produced.
int unlockOf(String id) {
  var lv = 999;
  for (final c in crops.values) {
    if (c.product == id || c.bonus == id) lv = math.min(lv, c.level);
  }
  for (final t in trees.values) {
    if (t.product == id) lv = math.min(lv, bdef(t.id).level);
  }
  for (final a in animals.values) {
    if (a.product == id) lv = math.min(lv, a.level);
  }
  for (final x in fishes.values) {
    if (x.product == id) lv = math.min(lv, x.level);
  }
  for (final r in recipes.values) {
    if (r.product == id) lv = math.min(lv, r.level);
  }
  return lv;
}

void main() {
  test('wave 2 projects ask only for goods the player can make by then', () {
    for (final id in wave2) {
      final d = bdef(id);
      for (final g in d.goods.keys) {
        expect(unlockOf(g), lessThanOrEqualTo(d.level - 2), reason: '$id: $g ${unlockOf(g)}');
      }
      for (final u in projectUpgrades[id]!) {
        for (final g in u.goods.keys) {
          expect(unlockOf(g), lessThanOrEqualTo(u.level - 1), reason: '$id up ${u.level}: $g ${unlockOf(g)}');
        }
      }
    }
  });

  test('wave 2 bonuses', () {
    final f = Farm.fresh(now: () => DateTime(2026, 11, 27, 9).millisecondsSinceEpoch, seed: 5);
    final fish = f.fishMs(fishes['caro']!);
    final tree = f.treeMs(trees['cay_chuoi']!);
    final market = f.marketBonus;
    final slots = f.stallSlots;
    final catching = f.catchChance;
    f.projects.addAll(wave2);
    expect(f.fishMs(fishes['caro']!), lessThan(fish));
    expect(f.treeMs(trees['cay_chuoi']!), lessThan(tree));
    expect(f.marketBonus, closeTo(market + .1, 1e-9));
    expect(f.stallSlots, slots + 1);
    expect(f.catchChance, closeTo(catching + .1, 1e-9));
    expect(f.traderBonus, closeTo(.1, 1e-9));
    expect(f.dailyBonus, closeTo(.2, 1e-9));
    expect(villageTitle(16), 'Làng quê đáng sống');
  });

  test('building the sports ground raises today\'s special orders', () {
    final t = DateTime(2026, 11, 27, 9).millisecondsSinceEpoch;
    final f = Farm.fresh(now: () => t, seed: 5);
    f.level = 35;
    f.rollDaily();
    final before = [for (final o in f.daily) o.coins];
    f.coins = 1 << 30;
    for (final e in bdef('san_bong').goods.entries) {
      f.inv[e.key] = e.value;
    }
    f.lots.addAll(List.generate(lotsPerSide * lotsPerSide, (i) => i));
    f.objs.removeWhere((o) => o.def.kind == BKind.obstacle);
    String? err = 'no spot';
    for (var i = 0; i < mapSize * mapSize && err != null; i++) {
      if (f.canPlace('san_bong', i % mapSize, i ~/ mapSize)) err = f.build('san_bong', i % mapSize, i ~/ mapSize);
    }
    expect(err, isNull);
    for (var i = 0; i < before.length; i++) {
      expect(f.daily[i].coins, greaterThan(before[i]));
    }
    final g = Farm.fromJson(jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>);
    expect(g.has('san_bong'), isTrue);
  });

  test('a save naming a project this version does not know still loads', () {
    final f = Farm.fresh(now: () => 1000, seed: 5);
    final j = jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>;
    (j['projects'] as List).add('cong_trinh_moi');
    (j['objs'] as List).add({'i': 999, 't': 'cong_trinh_moi', 'x': 3, 'y': 3});
    final g = Farm.fromJson(j);
    expect(g.objs.any((o) => o.type == 'cong_trinh_moi'), isFalse);
    expect(g.catchChance, greaterThanOrEqualTo(0));
  });
}
