import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/calendar.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/lunar.dart';
import 'package:nong_trai/core/reminders.dart';
import 'package:nong_trai/core/weather.dart';

(int, int)? spot(Farm f, String type) {
  for (var y = 0; y < mapSize; y++) {
    for (var x = 0; x < mapSize; x++) {
      if (f.canPlace(type, x, y)) return (x, y);
    }
  }
  return null;
}

const minute = 60 * 1000;

void main() {
  tearDown(() {
    calendarOverride = null;
    weatherOverride = null;
  });

  test('lunar calendar: Tết, can chi, tiết khí', () {
    final tet = LunarDate.of(DateTime(2026, 2, 17));
    expect((tet.day, tet.month, tet.year), (1, 1, 2026));
    expect(canChiYear(2026), 'Bính Ngọ');
    expect(canChiYear(2027), 'Đinh Mùi');
    final mid = LunarDate.of(DateTime(2026, 9, 25));
    expect((mid.day, mid.month), (15, 8));
    expect(solarTermOf(DateTime(2026, 3, 21)), 0); // Xuân phân
    expect(solarTermOf(DateTime(2026, 6, 22)), 6); // Hạ chí
    expect(solarTermOf(DateTime(2026, 12, 23)), 18); // Đông chí
    expect(seasonOf(DateTime(2026, 2, 10)), Season.xuan); // after Lập xuân
    expect(seasonOf(DateTime(2026, 7, 1)), Season.ha);
    expect(seasonOf(DateTime(2026, 9, 25)), Season.thu);
    expect(seasonOf(DateTime(2026, 12, 25)), Season.dong);
    expect(solarOf(15, 8, 2026), DateTime(2026, 9, 25));
  });

  test('festivals by lunar date, Tết spans the new year', () {
    expect(festivalOn(DateTime(2026, 9, 25))!.key, 'trung_thu-2026');
    final ongTao = festivalOn(DateTime(2026, 2, 10))!; // 23 tháng Chạp
    expect(ongTao.key, 'tet-2026');
    expect(festivalOn(DateTime(2026, 2, 17))!.key, 'tet-2026');
    expect(ongTao.start, DateTime(2026, 2, 10));
    expect(ongTao.end, DateTime(2026, 2, 23)); // mồng 7
    expect(festivalOn(DateTime(2026, 2, 24)), isNull);
    expect(festivalOn(DateTime(2026, 11, 6)), isNull);
    final next = upcomingFestivals(DateTime(2026, 11, 6));
    expect(next.first.def.id, 'com_moi');
    expect(next[1].def.id, 'tet');
    expect(next[1].key, 'tet-2027');
  });

  test('crops in season grow faster', () {
    final f = Farm.fresh(now: () => 1000);
    weatherOverride = Weather.sunny;
    calendarOverride = DateTime(2026, 9, 25); // thu: lúa in season
    final inSeason = f.cropMs(crops['lua']!);
    final ngoAutumn = f.cropMs(crops['ngo']!);
    calendarOverride = DateTime(2026, 7, 1); // hạ
    expect(inSeason, lessThan(f.cropMs(crops['lua']!)));
    expect(f.cropMs(crops['ngo']!), lessThan(ngoAutumn));
  });

  test('festival orders: roll once, deliver all for the decoration', () {
    var t = DateTime(2026, 9, 25, 9).millisecondsSinceEpoch;
    final f = Farm.fresh(now: () => t);
    f.level = 2;
    calendarOverride = DateTime(2026, 9, 25);
    f.tickOrders();
    expect(f.fest, isEmpty); // too low
    f.level = 12;
    f.tickOrders();
    expect(f.fest.length, 3);
    expect(f.festKey, 'trung_thu-2026');
    final ids = f.fest.map((o) => o.id).toList();
    f.tickOrders();
    expect(f.fest.map((o) => o.id).toList(), ids); // not re-rolled
    expect(f.canBuy('den_ong_sao'), isNotNull);
    for (final o in f.fest) {
      for (final e in o.need.entries) {
        f.inv[e.key] = (f.inv[e.key] ?? 0) + e.value;
      }
    }
    f.lots.addAll([for (var i = 0; i < lotsPerSide * lotsPerSide; i++) i]);
    final coins0 = f.coins;
    for (final o in f.fest) {
      expect(f.deliverFest(o), isNull);
    }
    expect(f.festAllDone, isTrue);
    expect(f.coins, greaterThan(coins0 + f.festAllBonus));
    expect(f.giftCount('den_ong_sao'), 1);
    expect(f.canBuy('den_ong_sao'), isNull);
    final p = spot(f, 'den_ong_sao')!;
    expect(f.build('den_ong_sao', p.$1, p.$2), isNull);
    expect(f.giftCount('den_ong_sao'), 0);
    expect(f.canBuy('den_ong_sao'), isNotNull);
    // removing it puts it back in the bag
    f.remove(f.objs.firstWhere((o) => o.type == 'den_ong_sao'));
    expect(f.giftCount('den_ong_sao'), 1);
    // saved and loaded
    final g = Farm.fromJson(f.toJson(), now: () => t);
    expect(g.festKey, f.festKey);
    expect(g.fest.length, 3);
    expect(g.giftCount('den_ong_sao'), 1);
    // after the festival its orders are gone from view
    calendarOverride = DateTime(2026, 10, 5);
    expect(f.activeFestival, isNull);
    expect(f.deliverFest(f.fest.first), isNotNull);
  });

  group('drying yard', () {
    late int t;
    late Farm f;
    late Obj field;
    setUp(() {
      t = DateTime(2026, 11, 6, 9).millisecondsSinceEpoch;
      f = Farm.fresh(now: () => t);
      f.level = 5;
      f.coins = 100000;
      f.lots.addAll([for (var i = 0; i < lotsPerSide * lotsPerSide; i++) i]);
      final p = spot(f, 'san_phoi')!;
      expect(f.build('san_phoi', p.$1, p.$2), isNull);
      expect(f.canBuy('san_phoi'), 'Đã xây rồi');
      field = f.objs.firstWhere((o) => o.type == 'ruong');
    });

    void reap() {
      f.plant(field, 'lua');
      t = field.end;
      expect(f.harvest(field), isNull);
    }

    test('sun dries the grain for a bonus', () {
      weatherOverride = Weather.sunny;
      final thoc0 = f.countOf('thoc');
      reap();
      expect(f.countOf('thoc'), thoc0 + 2); // the harvest itself is unchanged
      expect(f.yard['thoc'], 2);
      expect(f.collectYard(), 'Thóc chưa khô');
      t += 89 * minute;
      f.settleYard();
      expect(f.yardDone, isFalse);
      t += 2 * minute;
      f.settleYard();
      expect(f.yardDone, isTrue);
      expect(f.collectYard(), isNull);
      expect(f.countOf('thoc'), thoc0 + 3);
      expect(f.yard, isEmpty);
    });

    test('a dry spell dries twice as fast; rain soaks uncovered grain', () {
      weatherOverride = Weather.drought;
      reap();
      t += 46 * minute;
      f.settleYard();
      expect(f.yardDone, isTrue);
      f.collectYard();
      // spread 8, then it rains on it
      weatherOverride = Weather.sunny;
      for (var i = 0; i < 4; i++) {
        reap();
      }
      expect(f.yard['thoc'], 8);
      t += 30 * minute;
      f.settleYard();
      expect(f.yardDry, greaterThan(0));
      weatherOverride = Weather.rain;
      t += minute;
      f.settleYard();
      expect(f.yard['thoc'], 6);
      expect(f.yardDry, 0);
      t += minute;
      f.settleYard();
      expect(f.yard['thoc'], 6); // once per shower
      expect(f.coverYard(false), isNull); // already uncovered
    });

    test('the tarp keeps rain off and pauses drying', () {
      weatherOverride = Weather.sunny;
      reap();
      reap();
      expect(f.coverYard(true), isNull);
      final dry = f.yardDry;
      weatherOverride = Weather.rain;
      t += 60 * minute;
      f.settleYard();
      expect(f.yard['thoc'], 4);
      expect(f.yardDry, dry);
      expect(f.coverYard(false), contains('mưa'));
      weatherOverride = Weather.sunny;
      expect(f.coverYard(false), isNull);
      t += 91 * minute;
      f.settleYard();
      expect(f.yardDone, isTrue);
      // reaped in the rain: spread under the tarp
      f.collectYard();
      weatherOverride = Weather.rain;
      reap();
      expect(f.yardCover, isTrue);
      expect(f.yard['thoc'], 2);
      final g = Farm.fromJson(f.toJson(), now: () => t);
      expect(g.yard, f.yard);
      expect(g.yardCover, isTrue);
    });

    test('reminder before rain, or when dry', () {
      weatherOverride = Weather.sunny;
      reap();
      final r = planReminders(f).where((r) => r.id == 6).single;
      expect(r.at, f.yardReadyAt);
      expect(r.title, contains('khô'));
    });
  });
}
