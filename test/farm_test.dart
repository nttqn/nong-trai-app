import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/calendar.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';

void main() {
  // a day with none of the tested crops in season (summer: ngô, dưa, mía, ớt)
  setUp(() => calendarOverride = DateTime(2026, 7, 1));
  tearDown(() => calendarOverride = null);
  late int t;
  late Farm f;
  setUp(() {
    t = 1000000;
    f = Farm.fresh(now: () => t, seed: 3);
  });

  Obj first(String type) => f.objs.firstWhere((o) => o.type == type);

  test('fresh farm has house, paddies, orders and no overlaps', () {
    expect(f.house, isNotNull);
    expect(f.objs.where((o) => o.type == 'ruong').length, 4);
    expect(f.orders.length, f.orderSlots);
    final seen = <int>{};
    for (final o in f.objs) {
      for (var dx = 0; dx < o.w; dx++) {
        for (var dy = 0; dy < o.h; dy++) {
          expect(seen.add((o.x + dx) + (o.y + dy) * mapSize), isTrue, reason: '${o.type} overlaps');
          expect(Farm.terrain(o.x + dx, o.y + dy), 'grass');
        }
      }
    }
  });

  test('plant, wait, harvest rice gives thóc + rơm and xp', () {
    final p = first('ruong');
    expect(f.plant(p, 'rau'), isNotNull); // wrong plot type
    expect(f.plant(p, 'lua'), isNull);
    expect(f.harvest(p), isNull);
    expect(f.countOf('thoc'), 6); // not ready yet: nothing gained
    t += 120 * 1000;
    expect(f.isReady(p), isTrue);
    f.harvest(p);
    expect(f.countOf('thoc'), 8);
    expect(f.countOf('rom'), 1);
    expect(f.xp, greaterThan(0));
    expect(p.crop, isNull);
  });

  test('chicken coop: build, buy, feed, collect eggs', () {
    f.coins = 5000;
    f.level = 3;
    final spot = _findSpot(f, 'chuong_ga');
    expect(f.build('chuong_ga', spot.$1, spot.$2), isNull);
    final pen = first('chuong_ga');
    expect(f.feed(pen), isNotNull); // empty
    f.buyAnimal(pen);
    f.buyAnimal(pen);
    expect(f.feed(pen), isNull);
    expect(f.countOf('thoc'), 4);
    t += 600 * 1000;
    expect(f.collect(pen), isNull);
    expect(f.countOf('trung'), 2);
  });

  test('factory queue runs jobs back to back', () {
    f.coins = 5000;
    f.level = 5;
    final spot = _findSpot(f, 'may_xay');
    f.build('may_xay', spot.$1, spot.$2);
    final m = first('may_xay');
    f.inv['thoc'] = 6;
    expect(f.startJob(m, 'gao'), isNull);
    expect(f.startJob(m, 'gao'), isNull);
    expect(f.startJob(m, 'gao'), isNotNull); // out of thóc
    t += 180 * 1000;
    expect(f.readyJobs(m), 1);
    t += 180 * 1000;
    f.collectJobs(m);
    expect(f.countOf('gao'), 2);
  });

  test('storage cap blocks harvest', () {
    f.inv['rom'] = f.storageCap - f.stored;
    final p = first('ruong');
    f.plant(p, 'lua');
    t += 200 * 1000;
    expect(f.harvest(p), isNotNull);
    expect(p.crop, 'lua');
  });

  test('orders only ask for producible goods and pay out', () {
    for (final o in f.orders) {
      for (final id in o.need.keys) {
        expect(f.producible(), contains(id));
      }
    }
    final o = f.orders.first;
    o.need.forEach((k, v) => f.inv[k] = (f.inv[k] ?? 0) + v);
    final before = f.coins;
    expect(f.deliver(o), isNull);
    expect(f.coins, before + o.coins);
    expect(f.orders.first.waitUntil, greaterThan(0));
    t += 21 * 1000;
    f.tickOrders();
    expect(f.orders.first.waitUntil, 0);
  });

  test('buying land needs adjacency, level and coins', () {
    final far = Farm.lotIndex(3, 3);
    expect(f.canBuyLot(far), isNotNull);
    final near = Farm.lotIndex(1, 2);
    expect(f.canBuyLot(near), 'Cần đạt cấp 2');
    f.level = 5;
    f.coins = 100;
    expect(f.canBuyLot(near), 'Không đủ xu');
    f.coins = 10000;
    f.level = 5;
    expect(f.buyLot(near), isNull);
    expect(f.owned(6, 12), isTrue);
  });

  test('projects consume goods and grant bonuses', () {
    f.coins = 10000;
    f.level = 3;
    f.inv['thoc'] = 10;
    final spot = _findSpot(f, 'gieng');
    expect(f.build('gieng', spot.$1, spot.$2), isNull);
    expect(f.has('gieng'), isTrue);
    expect(f.countOf('thoc'), 0);
    expect(f.canBuy('gieng'), 'Đã xây rồi');
    expect(f.cropMs(crops['rau']!), (240 * 1000 * .9).round());
  });

  test('quest chain advances with baseline', () {
    final p = f.objs.where((o) => o.type == 'ruong').toList();
    for (final x in p) {
      f.plant(x, 'lua');
    }
    expect(f.questDone, isTrue);
    f.claimQuest();
    expect(f.quest, 1);
    expect(f.questDone, isFalse);
  });

  test('json round trip keeps everything', () {
    final p = first('ruong');
    f.plant(p, 'lua');
    final j = jsonDecode(jsonEncode(f.toJson()));
    final g = Farm.fromJson(j, now: () => t);
    expect(jsonEncode(g.toJson()), jsonEncode(f.toJson()));
  });
}

(int, int) _findSpot(Farm f, String type) {
  for (var y = 0; y < mapSize; y++) {
    for (var x = 0; x < mapSize; x++) {
      if (f.canPlace(type, x, y)) return (x, y);
    }
  }
  throw StateError('no spot for $type');
}
