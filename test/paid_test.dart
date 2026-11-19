import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';

void main() {
  var clock = DateTime(2026, 11, 20, 9).millisecondsSinceEpoch;
  Farm farm() => Farm.fresh(now: () => clock);
  Farm reload(Farm f) => Farm.fromJson(jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>, now: () => clock);

  test('Gói khởi đầu: once per farm, survives a save', () {
    final f = farm();
    final cap = f.storageCap, coins = f.coins;
    expect(f.grantPaid(skuStarter), isNotNull);
    expect(f.coins, coins + starterCoins(f.level));
    expect(f.storageCap, cap + starterStorage);
    expect(f.tickets, starterTickets);
    expect(f.giftCount('chau_sen'), 1);
    expect(f.grantPaid(skuStarter), isNull); // restored again: nothing twice
    final g = reload(f);
    expect(g.starterTaken, isTrue);
    expect(g.storageCap, cap + starterStorage);
    expect(g.tickets, starterTickets);
  });

  test('Hầm chứa: locked until bought, storage while it stands, stays put', () {
    final f = farm()..coins = 100000;
    expect(f.canBuy('ham_chua'), isNotNull);
    f.grantPaid(skuHamChua);
    expect(f.canBuy('ham_chua'), isNull);
    final cap = f.storageCap;
    // somewhere free on the owned land
    var placed = false;
    for (var y = 0; y < mapSize && !placed; y++) {
      for (var x = 0; x < mapSize && !placed; x++) {
        if (f.canPlace('ham_chua', x, y)) placed = f.build('ham_chua', x, y) == null;
      }
    }
    expect(placed, isTrue);
    expect(f.storageCap, cap + hamChuaStorage);
    expect(f.canRemove(f.objs.firstWhere((o) => o.type == 'ham_chua')), isFalse);
    expect(f.canBuy('ham_chua'), isNotNull); // only one
    expect(reload(f).storageCap, cap + hamChuaStorage);

    // 1.7.0: upgrades with xu, gated by level, kept in the save
    final h = f.objs.firstWhere((o) => o.type == 'ham_chua');
    f.level = 9;
    expect(f.upgradeHamChua(h), isNotNull);
    f.level = 30;
    f.coins = 1000000;
    for (final want in [500, 1000, 3000]) {
      expect(f.upgradeHamChua(h), isNull);
      expect(f.storageCap, cap + want);
    }
    expect(f.upgradeHamChua(h), isNotNull); // max
    expect(f.coins, 1000000 - 20000 - 80000 - 300000);
    expect(reload(f).storageCap, cap + 3000);
  });

  test('pens and ponds can be demolished', () {
    final f = farm()..coins = 100000..level = 10;
    for (final t in ['chuong_ga', 'ao']) {
      var placed = false;
      for (var y = 0; y < mapSize && !placed; y++) {
        for (var x = 0; x < mapSize && !placed; x++) {
          if (f.canPlace(t, x, y)) placed = f.build(t, x, y) == null;
        }
      }
      expect(placed, isTrue, reason: t);
      final o = f.objs.lastWhere((o) => o.type == t);
      expect(f.canRemove(o), isTrue, reason: t);
      f.remove(o);
      expect(f.objs.any((e) => e.type == t), isFalse);
    }
  });

  test('Thẻ Nhà Nông: 30 days, stacks, 5 free Xong ngay a day, then tickets', () {
    final f = farm();
    expect(f.cardActive, isFalse);
    f.grantPaid(skuCard);
    expect(f.cardDaysLeft, 30);
    f.grantPaid(skuCard);
    expect(f.cardDaysLeft, 60);
    expect(f.orderBonus, greaterThanOrEqualTo(cardOrderBonus));

    final field = f.objs.firstWhere((o) => o.type == 'ruong');
    var uses = 0;
    for (var i = 0; i < 8; i++) {
      expect(f.plant(field, 'lua'), isNull);
      if (f.speedUpPaid(field) == null) uses++;
      f.harvest(field);
    }
    expect(uses, cardSpeedUps);
    expect(f.cardSpeedUpsLeft, 0);
    // next day: the card's uses come back
    clock += const Duration(days: 1).inMilliseconds;
    expect(f.cardSpeedUpsLeft, cardSpeedUps);
    // the card runs out after its last day
    clock += const Duration(days: 60).inMilliseconds;
    expect(f.cardActive, isFalse);
    f.harvest(field);
    f.tickets = 1;
    expect(f.plant(field, 'lua'), isNull);
    expect(f.speedUpPaid(field), isNull);
    expect(f.tickets, 0);
  });
}
