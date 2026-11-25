// Thương lái (from a 5★ review, 1.10.0): every two hours the trader's
// sampan ties up at the landing by the bridge for an hour and asks for a
// few of the farm's dearer goods, paying better than the market and the
// usual orders. Each line is sold on its own; once all are sold, or the
// hour is up, the boat goes on downriver. A part of farm.dart.

part of 'farm.dart';

extension FarmTrader on Farm {
  static const traderLevel = 5;

  /// The boat docks at every even local hour and stays the whole hour.
  static const traderLines = 3;

  DateTime get _tNow => DateTime.fromMillisecondsSinceEpoch(now());

  /// Which visit it is now (day key × 100 + two-hour block), or 0 when
  /// the boat is away.
  int get traderVisitNow {
    final d = _tNow;
    if (d.hour.isOdd) return 0;
    return Farm.dayKey(now()) * 100 + d.hour ~/ 2;
  }

  /// The trader is at the landing and still has something to buy.
  bool get traderHere {
    if (level < traderLevel) return false;
    final v = traderVisitNow;
    if (v == 0) return false;
    if (traderVisit != v) return true; // not rolled yet: fresh lines
    return trader.any((o) => o.waitUntil >= 0);
  }

  /// Ms until the boat leaves (while docked) or next ties up (while away).
  int get traderMs {
    final d = _tNow;
    final next = d.hour.isOdd || !traderHere
        ? DateTime(d.year, d.month, d.day, d.hour.isOdd ? d.hour + 1 : d.hour + 2)
        : DateTime(d.year, d.month, d.day, d.hour + 1);
    return next.millisecondsSinceEpoch - now();
  }

  /// Lines the player can sell right now (for the HUD badge).
  int get traderReady {
    if (!traderHere || traderVisit != traderVisitNow) return 0;
    return trader.where((o) => o.waitUntil >= 0 && o.need.entries.every((e) => countOf(e.key) >= e.value)).length;
  }

  /// New lines when a new visit starts.
  void rollTrader() {
    if (level < traderLevel) return;
    final v = traderVisitNow;
    if (v == 0 || v == traderVisit) return;
    traderVisit = v;
    trader.clear();
    final rng = math.Random(seed * 131 + v);
    final pool = producible()..sort((a, b) => item(a).price.compareTo(item(b).price));
    if (pool.isEmpty) pool.add('thoc');
    // the dearer half of what the farm makes, never the same thing twice
    final top = pool.sublist((pool.length * .4).floor().clamp(0, pool.length - 1));
    final pick = <String>[];
    while (pick.length < math.min(traderLines, top.length)) {
      final id = top[rng.nextInt(top.length)];
      if (!pick.contains(id)) pick.add(id);
    }
    // a small farm may have fewer kinds than lines: fill from the rest
    for (final id in pool.reversed) {
      if (pick.length >= traderLines || pick.length >= pool.length) break;
      if (!pick.contains(id)) pick.add(id);
    }
    for (final id in pick) {
      final p = item(id).price;
      final base = p < 10 ? 8 : p < 30 ? 6 : p < 90 ? 4 : p < 200 ? 3 : 2;
      final q = base + rng.nextInt(base);
      final value = p * q;
      final pay = (value * (1.9 + rng.nextDouble() * .4) * (1 + orderBonus)).round();
      trader.add(Order(nextId++, 'Thương lái', {id: q}, pay, math.max(3, (value / 6).round())));
    }
    _changed();
  }

  /// Sells one line to the trader.
  String? sellTrader(Order o) {
    if (!traderHere || !trader.contains(o)) return 'Ghe thương lái đã rời bến';
    if (o.waitUntil < 0) return 'Đã bán rồi';
    if (!_spend(o.need)) return 'Chưa đủ hàng';
    coins += o.coins;
    addXp(o.xp);
    o.waitUntil = -1;
    _stat('trader');
    _weekAdd(WeekKind.order, 1);
    _snd('cash');
    _ev('trader_sell', {'level': level, 'count': stats['trader']!});
    _changed();
    return null;
  }
}
