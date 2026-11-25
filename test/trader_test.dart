// Thương lái: the trader's boat docks every even local hour for an hour.

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/farm.dart';

int at(int h, [int m = 0]) => DateTime(2026, 11, 26, h, m).millisecondsSinceEpoch;

void main() {
  late int t;
  Farm farm() {
    final f = Farm.fresh(now: () => t)..level = 12;
    f.tut = tutDone;
    return f;
  }

  test('docks on even hours, away on odd ones, locked below its level', () {
    t = at(10, 15);
    final f = farm();
    expect(f.traderHere, isTrue);
    expect(f.traderMs, at(11) - t);
    t = at(11, 30);
    expect(f.traderHere, isFalse);
    expect(f.traderMs, at(12) - t);
    t = at(23, 59);
    expect(f.traderMs, DateTime(2026, 11, 27).millisecondsSinceEpoch - t);
    t = at(12, 5);
    f.level = FarmTrader.traderLevel - 1;
    expect(f.traderHere, isFalse);
  });

  test('three different goods, paid above the market, sold line by line', () {
    t = at(14, 1);
    final f = farm();
    f.tickOrders();
    expect(f.trader.length, FarmTrader.traderLines);
    final ids = f.trader.map((o) => o.need.keys.single).toSet();
    expect(ids.length, FarmTrader.traderLines);
    for (final o in f.trader) {
      final e = o.need.entries.single;
      expect(o.coins, greaterThan(f.sellPrice(e.key) * e.value));
    }
    final o = f.trader.first;
    final e = o.need.entries.single;
    expect(f.sellTrader(o), 'Chưa đủ hàng');
    f.inv[e.key] = e.value;
    final c = f.coins;
    expect(f.sellTrader(o), isNull);
    expect(f.coins, c + o.coins);
    expect(f.countOf(e.key), 0);
    expect(f.sellTrader(o), isNotNull);
    // same visit: lines kept; the next visit brings new ones
    final first = f.trader.map((x) => x.id).toList();
    t = at(14, 40);
    f.tickOrders();
    expect(f.trader.map((x) => x.id).toList(), first);
    t = at(16, 2);
    f.tickOrders();
    expect(f.trader.any((x) => first.contains(x.id)), isFalse);
  });

  test('leaves early once everything is sold; survives a save', () {
    t = at(8, 10);
    final f = farm();
    f.tickOrders();
    for (final o in f.trader) {
      o.need.forEach((k, v) => f.inv[k] = (f.inv[k] ?? 0) + v);
      expect(f.sellTrader(o), isNull);
    }
    expect(f.traderHere, isFalse);
    expect(f.traderMs, at(10) - t);
    final g = Farm.fromJson(f.toJson(), now: () => t);
    expect(g.traderVisit, f.traderVisit);
    expect(g.trader.every((o) => o.waitUntil < 0), isTrue);
    expect(g.traderHere, isFalse);
    t = at(10, 0);
    expect(g.traderHere, isTrue);
  });
}
