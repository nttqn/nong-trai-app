import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/core/memories.dart';

void main() {
  test('memory ids are unique', () {
    expect(memories.map((m) => m.id).toSet().length, memories.length);
  });

  test('old progress opens quietly; new milestones get a card; gift once', () {
    final f = Farm.fresh(now: () => 1000);
    f.stats['harvest:lua'] = 5; // reached before this version
    f.tickOrders();
    expect(f.mem['mua_dau'], 1);
    expect(f.memFresh, isEmpty);
    expect(f.memNewCount, 1);
    // a new milestone while playing
    f.stats['order'] = 1;
    f.tickOrders();
    expect(f.memFresh, ['don_dau']);
    final coins = f.coins;
    expect(f.readMemory('don_dau'), isNull);
    expect(f.coins, coins + memoryById('don_dau')!.coins);
    f.readMemory('don_dau');
    expect(f.coins, coins + memoryById('don_dau')!.coins); // only once
    expect(f.mem['don_dau'], 2);
    final g = Farm.fromJson(f.toJson(), now: () => 1000);
    expect(g.mem, f.mem);
    g.tickOrders();
    expect(g.memFresh, isEmpty);
  });
}
