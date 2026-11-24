// 1.9.0: câu giải trí past the daily casts, Đua top câu cá points, and
// place prizes on the weekly boards.

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/weekly.dart';

int at(int y, int m, int d, [int h = 10]) => DateTime(y, m, d, h).millisecondsSinceEpoch;

void main() {
  group('câu giải trí', () {
    test('past the daily casts: no storage, capped coins, no treasure, still points', () {
      var t = at(2026, 11, 25);
      final f = Farm.fresh(now: () => t)..level = 10;
      f.riverUsed = 99;
      f.riverDay = Farm.dayKey(t);
      expect(f.riverFun, isTrue);
      for (var i = 0; i < 400; i++) {
        t += 7777;
        final (b, err) = f.cast();
        expect(err, isNull);
        expect(b!.fun, isTrue);
        expect(b.kind, anyOf(BiteKind.fish, BiteKind.junk), reason: 'no coin jar or ticket box on fun casts');
      }
      final n = f.countOf('caro'), c = f.coins, xp = f.xp, wk = f.weekPts;
      const fish = RiverBite(BiteKind.fish, 'caro', 2, .3, .5, 'Cá rô phi', '🐟', pts: 1, fun: true);
      expect(f.landBite(fish), isNull);
      expect(f.countOf('caro'), n, reason: 'sold on the bank, not stored');
      expect(f.coins, c + 16 * 2 ~/ 5);
      expect(f.xp, xp);
      expect(f.weekPts, wk, reason: 'fun casts never feed the weekly event');
      expect(f.fishPts, 1);
      // the daily coin cap
      for (var i = 0; i < 500; i++) {
        f.landBite(fish);
      }
      expect(f.riverFunLeft, 0);
      final c2 = f.coins;
      f.landBite(fish);
      expect(f.coins, c2);
      expect(f.fishPts, 502, reason: 'points keep coming after the cap');
      // a new day: casts and the cap start over
      t = at(2026, 11, 26);
      expect(f.riverFun, isFalse);
      expect(f.riverFunLeft, f.riverFunCap);
    });

    test('daily casts give fishing points too', () {
      final t = at(2026, 11, 25);
      final f = Farm.fresh(now: () => t)..level = 5;
      f.landBite(const RiverBite(BiteKind.fish, 'caro', 1, .3, .5, 'Cá', '🐟', pts: 1));
      f.landBite(const RiverBite(BiteKind.coins, null, 100, .3, .5, 'Hũ', '🏺', pts: 2));
      expect(f.fishPts, 3);
      expect(f.fishWeek, weekKeyOf(t));
    });
  });

  group('place prizes', () {
    test('a finished week is queued once, settled once, and survives a save', () {
      var t = at(2026, 11, 25);
      final f = Farm.fresh(now: () => t)..level = 20;
      f.rollWeek();
      f.weekPts = 50;
      f.landBite(const RiverBite(BiteKind.fish, 'caro', 1, .3, .5, 'Cá', '🐟', pts: 1));
      final w = weekKeyOf(t);
      t = at(2026, 12, 2); // next Wednesday
      f.rollWeek();
      f.rollFish();
      expect(f.rankDue, [
        [0, w, 50],
        [1, w, 1],
      ]);
      final g = Farm.fromJson(f.toJson(), now: () => t);
      expect(g.rankDue, f.rankDue);
      final c = g.coins, tk = g.tickets;
      final msg = g.grantRank(0, w, 2);
      expect(msg, contains('Hạng 2'));
      expect(g.coins, c + rankCoins(1, 20));
      expect(g.tickets, tk + 2);
      expect(g.grantRank(0, w, 1), isNull, reason: 'one prize per week');
      expect(g.grantRank(1, w, 31), isNull, reason: 'no prize past 30');
      expect(g.rankDue, isEmpty);
      expect(g.rankDone, [w, w]);
      // an old save restored later does not queue the week again
      g.weekKey = w;
      g.weekPts = 50;
      g.rollWeek();
      expect(g.rankDue, isEmpty);
      final h = Farm.fromJson(g.toJson(), now: () => t);
      expect(h.rankDone, [w, w]);
    });

    test('tiers', () {
      expect([1, 2, 3, 4, 10, 11, 30, 31].map(rankTierOf), [0, 1, 1, 2, 2, 3, 3, null]);
      expect(rankLabel(0), 'Hạng 1');
      expect(rankLabel(3), 'Hạng 11–30');
    });

    test('a week without points queues nothing', () {
      var t = at(2026, 11, 25);
      final f = Farm.fresh(now: () => t)..level = 20;
      f.rollWeek();
      f.rollFish();
      t = at(2026, 12, 2);
      f.rollWeek();
      f.rollFish();
      expect(f.rankDue, isEmpty);
    });
  });
}
