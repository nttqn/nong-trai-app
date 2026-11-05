import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/defs.dart';
import 'package:nong_trai/core/farm.dart';

void main() {
  test('a lost farm is rebuilt from its leaderboard row', () {
    final f = Farm.fresh(now: () => 1000);
    f.recoverFrom(lvl: 19, houseLv: 4, projectCount: 8, orders: 57, farmName: 'Trang trại nhà Win');
    expect(f.level, 19);
    expect(f.houseLevel, 4);
    expect(f.projects.length, 8);
    expect(f.projects, containsAll(projectOrder.take(8)));
    expect(f.lots.length, [for (var n = 0; n < 36; n++) lotLevel(n)].where((l) => l <= 19).length);
    expect(f.lots.every((l) => l % lotsPerSide < 4 && l ~/ lotsPerSide < 4), isTrue);
    expect(f.name, 'Trang trại nhà Win');
    expect(f.coins, greaterThan(4000000));
    expect(f.stats['order'], 57);
    expect(f.recovered, isTrue);
    expect(f.currentQuest?.text ?? '', isNot('Gieo lúa trên 4 ô ruộng'));
    // every placed project sits on owned grass, nothing overlaps
    final seen = <int>{};
    for (final o in f.objs) {
      for (var dx = 0; dx < o.w; dx++) {
        for (var dy = 0; dy < o.h; dy++) {
          expect(seen.add((o.x + dx) + (o.y + dy) * mapSize), isTrue, reason: '${o.type} overlaps');
        }
      }
    }
    for (final id in projectOrder.take(8)) {
      if (bdef(id).w > 0) expect(f.objs.any((o) => o.type == id), isTrue, reason: id);
    }
    final g = Farm.fromJson(f.toJson());
    expect(g.level, 19);
    expect(g.recovered, isTrue);
  });
}
