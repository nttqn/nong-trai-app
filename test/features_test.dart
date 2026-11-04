import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/achievements.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/reminders.dart';
import 'package:nong_trai/core/weather.dart';
import 'package:nong_trai/core/demo.dart';
import 'package:nong_trai/render/farm_painter.dart';

int at(int y, int m, int d, [int h = 10]) => DateTime(y, m, d, h).millisecondsSinceEpoch;

void main() {
  group('login gift', () {
    test('streak counts up day by day, restarts after a gap, wraps after 7', () {
      var t = at(2026, 11, 1);
      final f = Farm.fresh(now: () => t);
      final c0 = f.coins;
      final r1 = f.claimLogin()!;
      expect(r1.day, 1);
      expect(f.coins, c0 + r1.coins);
      expect(f.claimLogin(), isNull, reason: 'once a day');
      for (var d = 2; d <= 7; d++) {
        t = at(2026, 11, d);
        expect(f.loginNextDay, d);
        expect(f.claimLogin()!.day, d);
      }
      expect(f.countOf('banhchung'), 2, reason: 'day 7 gift');
      t = at(2026, 11, 8);
      expect(f.loginNextDay, 1, reason: 'a new week');
      f.claimLogin();
      t = at(2026, 11, 10); // missed the 9th
      expect(f.loginNextDay, 1);
      expect(f.stats['login'], 8);
    });

    test('double gives the same again; saves keep the streak', () {
      final t = at(2026, 11, 4);
      final f = Farm.fresh(now: () => t);
      f.claimLogin();
      f.claimLogin(); // no-op
      final g = Farm.fromJson(f.toJson(), now: () => t);
      expect(g.loginClaimed, isTrue);
      expect(g.loginStreak, 1);
      final c = g.coins;
      g.doubleLogin(loginReward(1, g.level));
      expect(g.coins, c + loginReward(1, g.level).coins);
    });
  });

  group('guard dog', () {
    test('fed dog adds to the catch chance until it is hungry again', () {
      var t = at(2026, 11, 4);
      final f = Farm.fresh(now: () => t);
      f.level = 6;
      f.coins = 10000;
      f.inv['gao'] = 4;
      final (x, y) = _free(f, 'cho');
      expect(f.build('cho', x, y), isNull);
      expect(f.canBuy('cho'), 'Đã xây rồi');
      final d = f.dog!;
      expect(f.catchChance, 0);
      expect(f.feedDog(d), isNull);
      expect(f.countOf('gao'), 2);
      expect(f.catchChance, closeTo(.25, 1e-9));
      expect(f.feedDog(d), 'Chó vẫn còn no');
      t += 25 * 3600 * 1000;
      expect(f.catchChance, 0);
    });
  });

  test('the dog beside the house can be tapped', () {
    for (final stage in [1, 2]) {
      final f = demoFarm(stage);
      final d = f.dog!;
      final got = hitTest(f, worldIso.p(d.x + .5, d.y + .5));
      expect(got, same(d), reason: 'stage $stage: dog ${d.x},${d.y} got ${got?.type} ${got?.x},${got?.y} lv${got?.level}');
    }
  });

  group('weather', () {
    test('is the same for everyone and changes in 3-hour blocks', () {
      final t = at(2026, 11, 4, 9);
      final start = t ~/ weatherBlockMs * weatherBlockMs;
      expect(weatherAt(start), weatherAt(start + weatherBlockMs - 1));
      expect(weatherEndsAt(start + 5), start + weatherBlockMs);
      final seen = {for (var i = 0; i < 400; i++) weatherAt(i * weatherBlockMs)};
      expect(seen, Weather.values.toSet());
    });

    test('rain speeds crops up, a dry spell slows them unless irrigated', () {
      int blockOf(Weather w) {
        for (var i = 0;; i++) {
          if (weatherAt(i * weatherBlockMs) == w) return i * weatherBlockMs + 1000;
        }
      }

      final lua = crops['lua']!;
      var t = blockOf(Weather.sunny);
      final f = Farm.fresh(now: () => t);
      final base = f.cropMs(lua);
      t = blockOf(Weather.rain);
      expect(f.cropMs(lua), (base * .8).round());
      t = blockOf(Weather.drought);
      expect(f.cropMs(lua), (base * 1.25).round());
      f.projects.add('tram_bom');
      final pumped = f.cropMs(lua);
      t = blockOf(Weather.sunny);
      expect(pumped, f.cropMs(lua), reason: 'pump station: no slowdown');
    });
  });

  group('market stall', () {
    test('list, sell, withdraw, buy', () {
      final t = at(2026, 11, 4);
      final f = Farm.fresh(now: () => t);
      f.inv['ngo'] = 10;
      expect(f.canListStall('ngo', 5, 45), contains('cấp'));
      f.level = FarmMore.marketLevel;
      final (lo, hi) = f.stallPriceRange('ngo', 5);
      expect((lo, hi), (23, 90));
      expect(f.canListStall('ngo', 5, hi + 1), isNotNull);
      expect(f.canListStall('ngo', 11, 50), isNotNull);
      final s = f.listStall('ngo', 5, 60)!;
      expect(f.countOf('ngo'), 5, reason: 'goods leave storage');
      final c = f.coins;
      expect(f.stallSold(s.slot), isTrue);
      expect(f.coins, c + 60);
      expect(f.stallSold(s.slot), isFalse, reason: 'paid once');

      final s2 = f.listStall('ngo', 5, 45)!;
      expect(f.countOf('ngo'), 0);
      expect(f.withdrawStall(s2.slot), isTrue);
      expect(f.countOf('ngo'), 5);

      for (var i = 0; i < f.stallSlots; i++) {
        f.inv['ngo'] = 1;
        f.listStall('ngo', 1, 9);
      }
      f.inv['ngo'] = 1;
      expect(f.canListStall('ngo', 1, 9), 'Sạp đã đầy hàng');
      final g = Farm.fromJson(f.toJson(), now: () => t);
      expect(g.stalls.length, f.stallSlots);

      f.coins = 100;
      expect(f.canBuyStall(1, 200), 'Không đủ xu');
      f.boughtStall('dua', 2, 100);
      expect(f.coins, 0);
      expect(f.countOf('dua'), 2);
    });
  });

  group('achievements', () {
    test('claim tiers in order, earn a title, show it', () {
      final f = Farm.fresh(now: () => 1000);
      final a = achById('order')!;
      expect(f.achReady(a), isFalse);
      expect(f.setTitle('order'), isNotNull);
      f.stats['order'] = 25;
      expect(f.achReady(a), isTrue);
      expect(f.achReadyCount, greaterThanOrEqualTo(1));
      final c = f.coins;
      expect(f.claimAch(a), isNull);
      expect(f.coins, greaterThanOrEqualTo(c + achCoins[0]));
      expect(f.achReady(a), isFalse, reason: 'tier 2 needs 150');
      expect(f.setTitle('order'), isNull);
      expect(f.titleText, 'Thương lái');
      final g = Farm.fromJson(f.toJson(), now: () => 1000);
      expect(g.achTier(a), 1);
      expect(g.title, 'order');
      expect(achievements.map((a) => a.id).toSet().length, achievements.length);
      for (final a in achievements) {
        expect(a.tiers.length, 3);
        expect(a.tiers[0] < a.tiers[1] && a.tiers[1] < a.tiers[2], isTrue, reason: a.id);
      }
    });

    test('product counters read from stats', () {
      final f = Farm.fresh(now: () => 1000);
      f.stats['get:trung'] = 10;
      f.stats['get:sua'] = 5;
      f.stats['harvest:lua'] = 7;
      f.stats['harvest:ngo'] = 3;
      expect(achById('animal')!.value(f), 15);
      expect(achById('harvest')!.value(f), 10);
    });
  });

  group('tutorial', () {
    test('new farms start it, old saves skip it, steps follow play', () {
      var t = at(2026, 11, 4);
      final f = Farm.fresh(now: () => t);
      expect(f.tutStep, Tut.plant);
      final old = Farm.fromJson({...f.toJson()}..remove('tut'), now: () => t);
      expect(old.tutActive, isFalse);

      final field = f.tutTarget!;
      expect(field.def.kind, BKind.paddy);
      expect(f.plant(field, 'lua'), isNull);
      expect(f.tutCheck(), isTrue);
      expect(f.tutStep, Tut.harvest);
      expect(f.tutTarget, same(field));
      t = field.end + 1;
      expect(f.harvest(field), isNull);
      f.tutCheck();
      expect(f.tutStep, Tut.order);
      f.stats['order'] = 1;
      f.tutCheck();
      expect(f.tutStep, Tut.build);
      f.stats['build:ruong'] = 1;
      f.tutCheck();
      expect(f.tutStep, Tut.end);
      expect(f.tutCheck(), isFalse);
      f.tutFinish();
      expect(f.tutActive, isFalse);
      expect(Farm.fromJson(f.toJson(), now: () => t).tutActive, isFalse);
    });
  });

  group('reminders', () {
    test('first ripe field, animals, workshop, gift; nothing already ready', () {
      final t = at(2026, 11, 4, 10);
      final f = Farm.fresh(now: () => t);
      final fields = f.objs.where((o) => o.def.kind == BKind.paddy).toList();
      f.plant(fields[0], 'lua');
      f.plant(fields[1], 'lua');
      fields[1].end = fields[0].end + 60000;
      final r = planReminders(f);
      final crop = r.firstWhere((x) => x.id == 1);
      expect(crop.at, fields[0].end);
      final gift = r.firstWhere((x) => x.id == 5);
      expect(gift.at, at(2026, 11, 4, 19), reason: 'today\'s gift still waiting');
      f.claimLogin();
      expect(planReminders(f).firstWhere((x) => x.id == 5).at, at(2026, 11, 5, 8));
      fields[0].end = t - 1;
      fields[1].end = t + 1000; // too soon to notify
      expect(planReminders(f).where((x) => x.id == 1), isEmpty);
    });
  });
}

(int, int) _free(Farm f, String type) {
  for (var y = 0; y < mapSize; y++) {
    for (var x = 0; x < mapSize; x++) {
      if (f.canPlace(type, x, y)) return (x, y);
    }
  }
  throw StateError('no room');
}
