import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/quests.dart';

void main() {
  test('village projects upgrade and scale their bonus', () {
    final f = Farm.fresh(now: () => 1000, seed: 3);
    f.projects.add('tram_bom');
    expect(f.projectLevel('tram_bom'), 1);
    final base = f.cropMs(crops['lua']!);
    f.level = 30;
    f.coins = 1000000;
    for (final e in f.nextProjectUpgrade('tram_bom')!.goods.entries) {
      f.inv[e.key] = e.value;
    }
    expect(f.upgradeProject('tram_bom'), isNull);
    expect(f.projectLevel('tram_bom'), 2);
    expect(f.cropMs(crops['lua']!), lessThan(base)); // 30% instead of 20%
    expect(projectEffect('tram_bom', 2), contains('30%'));
    expect(f.canUpgradeProject('tram_bom'), isNotNull); // goods used up
    final g = Farm.fromJson(jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>);
    expect(g.projectLevel('tram_bom'), 2);
  });

  test('daily special orders: three a day, all-done bonus, new set tomorrow', () {
    var t = DateTime(2026, 11, 4, 9).millisecondsSinceEpoch;
    final f = Farm.fresh(now: () => t, seed: 3);
    f.level = 5;
    f.tickOrders();
    expect(f.daily, isEmpty); // locked below level 6
    f.level = 12;
    f.tickOrders();
    expect(f.daily.length, 3);
    final first = f.daily.map((o) => o.id).toList();
    for (final o in f.daily) {
      for (final e in o.need.entries) {
        f.inv[e.key] = (f.inv[e.key] ?? 0) + e.value;
      }
    }
    final c0 = f.coins;
    var paid = 0;
    for (final o in f.daily) {
      paid += o.coins;
      expect(f.deliverDaily(o), isNull);
    }
    expect(f.dailyAllDone, isTrue);
    expect(f.coins, greaterThanOrEqualTo(c0 + paid + f.dailyAllBonus));
    expect(f.deliverDaily(f.daily.first), isNotNull); // already delivered
    f.tickOrders();
    expect(f.daily.map((o) => o.id).toList(), first); // same day
    final saved = Farm.fromJson(jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>, now: () => t);
    expect(saved.dailyAllDone, isTrue);
    t += const Duration(days: 1).inMilliseconds;
    f.tickOrders();
    expect(f.daily.every((o) => o.waitUntil == 0), isTrue);
    expect(f.daily.map((o) => o.id).toList(), isNot(first));
  });

  test('late content is wired: recipes, pens, trees, crops, upgrades', () {
    for (final r in recipes.values) {
      expect(buildings.containsKey(r.building), isTrue, reason: r.id);
      for (final i in [...r.inputs.keys, r.product]) {
        expect(items.containsKey(i), isTrue, reason: '${r.id}: $i');
      }
    }
    for (final a in animals.values) {
      expect(buildings[a.pen]?.kind, BKind.pen, reason: a.id);
      expect(items.containsKey(a.feed) && items.containsKey(a.product), isTrue);
    }
    for (final t in trees.keys) {
      expect(buildings[t]?.kind, BKind.tree);
    }
    for (final c in crops.values) {
      expect(items.containsKey(c.product), isTrue);
    }
    for (final id in projectOrder) {
      expect(projectUpgrades[id]!.length, 2);
      for (final u in projectUpgrades[id]!) {
        for (final g in u.goods.keys) {
          expect(items.containsKey(g), isTrue, reason: '$id: $g');
        }
      }
    }
  });

  test('every quest key is one the farm records', () {
    const prefixes = ['plant:', 'harvest:', 'build:', 'project:', 'project_lv:', 'buy:', 'feed:', 'get:', 'stock:'];
    const plain = {'clear', 'order', 'level', 'lot', 'house', 'fertilize', 'daily', 'project_up'};
    for (final q in questChain) {
      expect(plain.contains(q.key) || prefixes.any(q.key.startsWith), isTrue, reason: q.key);
    }
  });

  test('fmtShort keeps the HUD short', () {
    expect(fmtShort(99999), '99.999');
    expect(fmtShort(296400), '296k');
    expect(fmtShort(2967158), '2,97tr');
    expect(fmtShort(12000000), '12tr');
    expect(fmtShort(1500000000), '1,5tỷ');
  });
}
