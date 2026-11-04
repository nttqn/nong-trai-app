import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';

(int, int)? spot(Farm f, String type) {
  for (var y = 0; y < mapSize; y++) {
    for (var x = 0; x < mapSize; x++) {
      if (f.canPlace(type, x, y)) return (x, y);
    }
  }
  return null;
}

void main() {
  test('extra houses: unlock by level, rising price, storage + order bonus, max 3', () {
    final f = Farm.fresh(now: () => 1000);
    f.lots.addAll([for (var i = 0; i < lotsPerSide * lotsPerSide; i++) i]);
    f.coins = 10000000;
    f.level = 19;
    expect(f.canBuy('nha_phu'), contains('20'));
    f.level = 20;
    final cap0 = f.storageCap, bonus0 = f.orderBonus;
    expect(f.buildCost('nha_phu'), extraHouseBuildCost[0]);
    var p = spot(f, 'nha_phu')!;
    expect(f.build('nha_phu', p.$1, p.$2), isNull);
    expect(f.storageCap, cap0 + (houseLevels[0].storage * extraHouseStorage).round());
    expect(f.orderBonus, closeTo(bonus0 + extraHouseOrderBonus, 1e-9));
    // the second one waits for level 26 and costs more
    expect(f.canBuy('nha_phu'), contains('26'));
    f.level = 32;
    expect(f.buildCost('nha_phu'), extraHouseBuildCost[1]);
    for (var i = 0; i < 2; i++) {
      p = spot(f, 'nha_phu')!;
      expect(f.build('nha_phu', p.$1, p.$2), isNull);
    }
    expect(f.extraHouseCount, 3);
    expect(f.canBuy('nha_phu'), contains('Tối đa'));
    // not removable; upgrades follow the main house
    final o = f.extraHouses.first;
    expect(f.canRemove(o), isFalse);
    expect(f.upgradeExtraHouse(o), contains('nhà chính'));
    expect(f.upgradeHouse(), isNull);
    final before = f.storageCap;
    expect(f.upgradeExtraHouse(o), isNull);
    expect(o.level, 1);
    expect(f.storageCap, greaterThan(before));
    // saved and loaded
    final g = Farm.fromJson(f.toJson(), now: () => 1000);
    expect(g.extraHouseCount, 3);
    expect(g.storageCap, f.storageCap);
  });
}
