import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/farm.dart';
import 'package:nong_trai/render/farm_painter.dart';
import 'package:nong_trai/render/life.dart';

void main() {
  test('village life: hens by the house, nobody at night', () {
    final farm = Farm.fresh();
    var hens = 0;
    for (var t = 0.0; t < 120; t += 3.1) {
      final a = villageLife(farm, worldIso, t, night: 0, rain: false);
      // the hen and chicks keep near the house (6..9, 6..9)
      hens += a.where((x) {
        final (gx, gy) = worldIso.toGrid(x.at);
        return (gx - 7.5).abs() < 5.5 && (gy - 7.5).abs() < 5.5 && (gx - Farm.roadX - .5).abs() > .5;
      }).length;
    }
    expect(hens, greaterThan(0));
    expect(villageLife(farm, worldIso, 50, night: 1, rain: false), isEmpty);
  });
}
