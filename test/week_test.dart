// 1.8.0: Sự kiện tuần, câu cá ngoài sông, Thu hết / Gieo lại, new decos.

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/weekly.dart';

int at(int y, int m, int d, [int h = 10]) => DateTime(y, m, d, h).millisecondsSinceEpoch;

/// A time inside the first week from 16 Nov 2026 whose theme earns [kind].
int weekOf(WeekKind kind) {
  for (var w = 0; w < 12; w++) {
    final t = at(2026, 11, 18 + 7 * w);
    if (weekThemeOf(weekKeyOf(t)).kind == kind) return t;
  }
  throw StateError('no week for $kind');
}

(int, int) _free(Farm f, String type) {
  for (var y = 0; y < mapSize; y++) {
    for (var x = 0; x < mapSize; x++) {
      if (f.canPlace(type, x, y)) return (x, y);
    }
  }
  throw StateError('no room');
}

void main() {
  group('weekly event', () {
    test('weeks start on Monday and every theme comes round in six weeks', () {
      expect(weekKeyOf(at(2026, 11, 20)), 20261116); // Friday
      expect(weekKeyOf(at(2026, 11, 22, 23)), 20261116); // Sunday night
      expect(weekKeyOf(at(2026, 11, 23, 0)), 20261123); // Monday
      expect(weekEndMs(at(2026, 11, 20)), DateTime(2026, 11, 23).millisecondsSinceEpoch);
      final seen = {for (var w = 0; w < 6; w++) weekThemeOf(weekKeyOf(at(2026, 11, 16 + 7 * w))).id};
      expect(seen.length, weekThemes.length);
      expect(eventDecos.every(buildings.containsKey), isTrue);
    });

    test('harvests earn points only in their theme week, from level 3', () {
      var t = weekOf(WeekKind.field);
      final f = Farm.fresh(now: () => t);
      final paddy = f.objs.firstWhere((o) => o.type == 'ruong');
      f.plant(paddy, 'lua');
      t += 200 * 1000;
      f.harvest(paddy);
      expect(f.weekPts, 0, reason: 'level 1: not open yet');
      f.level = 5;
      f.plant(paddy, 'lua');
      t += 200 * 1000;
      f.harvest(paddy);
      expect(f.weekPts, 2);
      // another theme's week: no points for rice
      t = weekOf(WeekKind.order);
      f.plant(paddy, 'lua');
      t += 200 * 1000;
      f.harvest(paddy);
      expect(f.weekPts, 0, reason: 'a new week starts from zero');
    });

    test('milestones are claimed in order; the last one gives the deco', () {
      final t = weekOf(WeekKind.animal);
      final f = Farm.fresh(now: () => t)..level = 10;
      f.rollWeek();
      final th = f.weekTheme;
      expect(f.claimWeek(), 'Chưa đủ điểm');
      f.weekPts = th.targets.last;
      expect(f.weekReady, 5);
      final c0 = f.coins, t0 = f.tickets;
      for (var i = 0; i < 5; i++) {
        expect(f.claimWeek(), isNull);
      }
      expect(f.claimWeek(), 'Đã nhận hết quà tuần này');
      expect(f.coins, greaterThan(c0 + weekCoins(4, 10)));
      expect(f.tickets, t0 + 3);
      expect(f.giftCount(th.deco), 1);
      // the gift is placed for free and goes back to the bag when removed
      expect(f.canBuy(th.deco), isNull);
      final (x, y) = _free(f, th.deco);
      final coins = f.coins;
      expect(f.build(th.deco, x, y), isNull);
      expect(f.coins, coins);
      expect(f.giftCount(th.deco), 0);
      expect(f.canBuy(th.deco), 'Quà sự kiện tuần: đạt mốc cuối để nhận');
      f.remove(f.objs.last);
      expect(f.giftCount(th.deco), 1);
    });

    test('unclaimed milestones are given at the week roll-over', () {
      var t = weekOf(WeekKind.fruit);
      final f = Farm.fresh(now: () => t)..level = 8;
      f.rollWeek();
      f.weekPts = f.weekTheme.targets[1];
      final c0 = f.coins;
      t += 7 * 24 * 3600 * 1000;
      f.tickOrders();
      expect(f.weekPts, 0);
      expect(f.weekCarried, 2);
      expect(f.coins, c0 + weekCoins(0, 8) + weekCoins(1, 8));
    });

    test('week state, river casts and last crops survive a save', () {
      final t = weekOf(WeekKind.fish);
      final f = Farm.fresh(now: () => t)..level = 6;
      f.rollWeek();
      f.weekPts = 33;
      f.weekClaimed = 1;
      f.cast();
      f.objs.firstWhere((o) => o.type == 'ruong').last = 'lua';
      final g = Farm.fromJson(f.toJson(), now: () => t);
      expect(g.weekKey, f.weekKey);
      expect(g.weekPts, 33);
      expect(g.weekClaimed, 1);
      expect(g.riverCasts, f.riverCasts);
      expect(g.objs.firstWhere((o) => o.type == 'ruong').last, 'lua');
    });
  });

  group('river fishing', () {
    test('casts per day: free ones, card, ads; a new day starts over', () {
      var t = at(2026, 11, 20);
      final f = Farm.fresh(now: () => t);
      expect(f.cast().$2, 'Câu cá mở ở cấp 3');
      f.level = 5;
      expect(f.riverCasts, FarmRiver.riverFree);
      for (var i = 0; i < FarmRiver.riverFree; i++) {
        expect(f.cast().$1, isNotNull);
      }
      expect(f.riverFun, isTrue);
      expect(f.cast().$1!.fun, isTrue, reason: 'past the daily casts the line still goes in (1.9.0)');
      expect(f.riverAdLeft, isTrue);
      for (var i = 0; i < FarmRiver.riverAdMax; i++) {
        f.riverAdGranted();
      }
      expect(f.riverAdLeft, isFalse);
      expect(f.riverCasts, FarmRiver.riverAdMax * FarmRiver.riverAdCasts);
      t = at(2026, 11, 21);
      expect(f.riverCasts, FarmRiver.riverFree);
      expect(f.riverAdLeft, isTrue);
      f.cardUntil = 20261230;
      expect(f.riverCasts, FarmRiver.riverFree + FarmRiver.riverCardCasts);
    });

    test('only fish the farm has reached bite; landing pays out', () {
      var t = weekOf(WeekKind.fish);
      final f = Farm.fresh(now: () => t)..level = 5;
      final seen = <String>{};
      for (var i = 0; i < 300; i++) {
        f.riverUsed = 0;
        t += 7777;
        final (b, err) = f.cast();
        expect(err, isNull);
        if (b!.kind == BiteKind.fish) seen.add(b.item!);
        expect(b.zone, inInclusiveRange(.1, .4));
      }
      expect(seen, {'caro'}, reason: 'cá trắm opens at 9');
      const fish = RiverBite(BiteKind.fish, 'caro', 2, .3, .5, 'Cá rô phi', '🐟');
      final n = f.countOf('caro');
      expect(f.landBite(fish), isNull);
      expect(f.countOf('caro'), n + 2);
      expect(f.weekPts, 2, reason: 'fish week counts river fish');
      final c = f.coins;
      f.landBite(const RiverBite(BiteKind.junk, null, 0, .3, .5, 'Dép', '🩴'));
      expect(f.coins, c + f.junkCoins);
      final tk = f.tickets;
      f.landBite(const RiverBite(BiteKind.ticket, null, 1, .14, 1, 'Hộp', '🎫'));
      expect(f.tickets, tk + 1);
    });

    test('a full storage lets the fish go', () {
      final t = at(2026, 11, 20);
      final f = Farm.fresh(now: () => t)..level = 5;
      f.inv['thoc'] = f.storageCap;
      expect(f.landBite(const RiverBite(BiteKind.fish, 'caro', 1, .3, .5, 'Cá', '🐟')), contains('Kho đầy'));
    });
  });

  group('Thu hết / Gieo lại', () {
    test('harvests everything ripe, then sows the same crops again', () {
      var t = at(2026, 11, 20);
      final f = Farm.fresh(now: () => t)..level = 5;
      f.coins = 1000;
      final paddies = f.objs.where((o) => o.type == 'ruong').toList();
      for (final p in paddies) {
        f.plant(p, 'lua');
      }
      expect(f.readyCount, 0);
      expect(f.redoCount, 0);
      t += 300 * 1000;
      expect(f.readyCount, paddies.length);
      final thoc = f.countOf('thoc');
      final (n, err) = f.harvestAll();
      expect(err, isNull);
      expect(n, paddies.length);
      expect(f.countOf('thoc'), thoc + 2 * paddies.length);
      expect(f.readyCount, 0);
      expect(f.redoCount, paddies.length);
      final coins = f.coins;
      final (sown, stocked, fed, e2) = f.redoAll();
      expect((sown, stocked, fed, e2), (paddies.length, 0, 0, null));
      expect(f.coins, coins - paddies.length * crops['lua']!.seed);
      expect(paddies.every((p) => p.crop == 'lua'), isTrue);
    });

    test('stops at a full storage and keeps what is left', () {
      var t = at(2026, 11, 20);
      final f = Farm.fresh(now: () => t)..level = 5;
      for (final p in f.objs.where((o) => o.type == 'ruong')) {
        f.plant(p, 'lua');
      }
      t += 300 * 1000;
      f.inv['rau'] = f.storageCap - f.stored - 5; // room for one paddy only
      final (n, err) = f.harvestAll();
      expect(n, 1);
      expect(err, contains('Kho đầy'));
      expect(f.readyCount, greaterThan(0));
    });

    test('pens are fed and ponds restocked; no money, no seed', () {
      final t = at(2026, 11, 20);
      final f = Farm.fresh(now: () => t)..level = 8;
      f.coins = 5000;
      final (px, py) = _free(f, 'chuong_ga');
      f.build('chuong_ga', px, py);
      final pen = f.objs.last;
      f.buyAnimal(pen);
      f.buyAnimal(pen);
      f.inv['thoc'] = 10;
      final (ax, ay) = _free(f, 'ao');
      f.build('ao', ax, ay);
      final pond = f.objs.last..last = 'caro';
      final paddy = f.objs.firstWhere((o) => o.type == 'ruong')..last = 'lua';
      f.coins = 0;
      final (sown, stocked, fed, err) = f.redoAll();
      expect(fed, 1);
      expect(sown + stocked, 0);
      expect(err, isNotNull);
      expect(pen.end, greaterThan(0));
      expect(pond.crop, isNull);
      expect(paddy.crop, isNull);
    });

    test('a waiting order slot can be called in at once', () {
      final t = at(2026, 11, 20);
      final f = Farm.fresh(now: () => t);
      final o = f.orders.first;
      f.discard(o);
      final w = f.orders.first;
      expect(w.waitUntil, greaterThan(0));
      f.callOrder(w);
      expect(f.orders.first.waitUntil, 0);
      expect(f.orders.first.need, isNotEmpty);
    });
  });

  test('new decorations are sold by level; event ones are not for sale', () {
    final t = at(2026, 11, 20);
    final f = Farm.fresh(now: () => t)..level = 20;
    f.coins = 100000;
    for (final id in ['hang_rao', 'duong_gach', 'chong_tre', 'cong_ngo', 'gian_hoa', 'cot_den', 'ao_sen', 'cay_mai', 'hon_non_bo']) {
      expect(f.canBuy(id), isNull, reason: id);
      expect(isGiftDeco(id), isFalse);
    }
    for (final id in eventDecos) {
      expect(f.canBuy(id), isNotNull, reason: id);
      expect(isGiftDeco(id), isTrue);
    }
    f.level = 1;
    expect(f.canBuy('hon_non_bo'), 'Cần đạt cấp 18');
  });
}
