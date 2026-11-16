import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:nong_trai/core/daynight.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/quests.dart';
import 'package:nong_trai/core/weather.dart';

int at(int h, [int m = 0]) => DateTime(2026, 11, 15, h, m).millisecondsSinceEpoch;

void main() {
  test('night follows the local clock', () {
    expect(nightAt(at(12)), 0);
    expect(nightAt(at(16)), 0);
    expect(nightAt(at(18, 20)), inExclusiveRange(0, 1));
    expect(nightAt(at(21)), 1);
    expect(nightAt(at(2)), 1);
    expect(nightAt(at(5, 30)), inExclusiveRange(0, 1));
    expect(nightAt(at(7)), 0);
  });

  test('moon phase by lunar day', () {
    expect(moonPhase(1).$1, lessThan(.03));
    expect(moonPhase(15).$1, greaterThan(.97));
    expect(moonPhase(8).$1, closeTo(.5, .1));
    expect(moonPhase(8).$2, isTrue);
    expect(moonPhase(23).$2, isFalse);
    expect(moonName(15), 'Trăng tròn');
    expect(lunarDayName(15), 'rằm');
  });

  test('after midnight it is still the evening moon', () {
    // 15/11/2026 is 7/10 âm lịch (Bính Ngọ)
    expect(moonDayAt(at(21)), 7);
    expect(moonDayAt(at(2)), 6);
  });

  test('old saves keep their quest across the 1.1 inserts', () {
    expect(questChain[questInsertAt].text, 'Đạt cấp 4');
    expect(questChain[questInsertAt + 1].key, 'build:bu_nhin');
    Farm load(int quest, {bool old = true}) {
      final j = jsonDecode(jsonEncode(Farm.fresh(now: () => at(10)).toJson())) as Map<String, dynamic>;
      j['quest'] = quest;
      if (old) j.remove('qv');
      return Farm.fromJson(j, now: () => at(10));
    }

    // an old save on "Góp công xây giếng làng" (old index 14) stays on it
    expect(load(14).currentQuest!.key, 'project:gieng');
    expect(load(13).currentQuest!.key, 'get:gao');
    // new saves are not shifted again
    expect(load(16, old: false).currentQuest!.key, 'project:gieng');
  });

  test('full-moon gift once per lunar month, at night, not in rain', () {
    // 23/11/2026 is rằm tháng 10
    var t = at(21);
    final f = Farm.fresh(now: () => t)..level = 5;
    weatherOverride = Weather.sunny;
    addTearDown(() => weatherOverride = null);
    expect(moonDateAt(DateTime(2026, 11, 23, 21).millisecondsSinceEpoch).day, 15);
    t = DateTime(2026, 11, 23, 12).millisecondsSinceEpoch;
    expect(f.moonGiftReady, isFalse); // daytime
    t = DateTime(2026, 11, 23, 21).millisecondsSinceEpoch;
    weatherOverride = Weather.rain;
    expect(f.moonGiftReady, isFalse);
    weatherOverride = Weather.sunny;
    expect(f.moonGiftReady, isTrue);
    final coins = f.coins;
    expect(f.claimMoon(), isTrue);
    expect(f.coins, coins + f.moonCoins);
    expect(f.stats['moon'], 1);
    // the next night of the same full moon: already admired
    t = DateTime(2026, 11, 24, 22).millisecondsSinceEpoch;
    expect(f.moonGiftReady, isFalse);
    // survives a save
    final g = Farm.fromJson(jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>, now: () => t);
    expect(g.moonKey, f.moonKey);
    // next lunar month's full moon
    t = DateTime(2026, 12, 23, 21).millisecondsSinceEpoch;
    expect(f.moonGiftReady, isTrue);
  });
}
