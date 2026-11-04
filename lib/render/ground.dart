// Static ground layer: grass, river, road, land lots, bamboo hedges.
// Recorded once per farm revision into a Picture.

import 'dart:math' as math;
import 'dart:ui';

import '../core/defs.dart';
import '../core/farm.dart';
import 'iso.dart';
import 'plants.dart';

double hash2(int x, int y, [int s = 0]) {
  var h = x * 374761393 + y * 668265263 + s * 2147483647;
  h = (h ^ (h >> 13)) * 1274126177;
  return ((h ^ (h >> 16)) & 0xFFFF) / 0xFFFF;
}

const grassA = Color(0xFF8CC152), grassB = Color(0xFF7FB847);
const dirtRoad = Color(0xFFCFA772), concrete = Color(0xFFBFC3C0);
const waterDeep = Color(0xFF3F8FC4), waterLight = Color(0xFF63B3DD);

void drawGround(Canvas c, Iso iso, Farm farm) {
  final concreteRoad = farm.has('duong_be_tong');
  // Surrounding countryside outside the map: distant paddies.
  for (var x = -6; x < mapSize + 6; x++) {
    for (var y = -6; y < mapSize + 6; y++) {
      final inside = x >= 0 && y >= 0 && x < mapSize && y < mapSize;
      if (inside) continue;
      final d = diamond(iso, x.toDouble(), y.toDouble(), 1, 1);
      if (y <= 1 && y >= -1) {
        fillPoly(c, d, waterDeep);
      } else if (y < -1) {
        fillPoly(c, d, hash2(x, y) < .5 ? const Color(0xFF9CC95E) : const Color(0xFF93C257));
      } else {
        // far paddies in a checker of greens
        final k = ((x + 100) ~/ 3 + (y + 100) ~/ 3) % 3;
        fillPoly(c, d, [const Color(0xFF9FCB63), const Color(0xFFA9D16B), const Color(0xFFB7D36A)][k]);
      }
    }
  }
  // tiles
  for (var x = 0; x < mapSize; x++) {
    for (var y = 0; y < mapSize; y++) {
      final t = Farm.terrain(x, y);
      final d = diamond(iso, x.toDouble(), y.toDouble(), 1, 1);
      if (t == 'water' && Farm.isLake(x, y)) {
        // drawn later, over the lot borders
      } else if (t == 'water') {
        fillPoly(c, d, y == 0 ? waterDeep : Color.lerp(waterDeep, waterLight, .45)!);
      } else if (t == 'road') {
        fillPoly(c, d, concreteRoad ? concrete : dirtRoad);
        if (concreteRoad) {
          line(c, iso.p(x + .5, y.toDouble()), iso.p(x + .5, y + 1.0), const Color(0xFFDADDD9), 1);
          line(c, iso.p(x.toDouble(), y.toDouble()), iso.p(x.toDouble(), y + 1.0), const Color(0xFF9EA39F), 1.2);
          line(c, iso.p(x + 1.0, y.toDouble()), iso.p(x + 1.0, y + 1.0), const Color(0xFF9EA39F), 1.2);
        } else {
          for (var i = 0; i < 3; i++) {
            final px = x + .2 + hash2(x, y, i) * .6, py = y + hash2(y, x, i + 7) * 1.0;
            circle(c, iso.p(px, py), 1.2, const Color(0xFFB08A58));
          }
        }
      } else {
        final zone = groundZone(x, y);
        fillPoly(c, d, switch (zone) {
          Zone.flats => hash2(x, y) < .5 ? const Color(0xFFB9C86C) : const Color(0xFFB0C264),
          Zone.tea => hash2(x, y) < .5 ? const Color(0xFF6FAE45) : const Color(0xFF68A740),
          Zone.plain => hash2(x, y) < .5 ? grassA : grassB,
        });
        if (zone == Zone.tea && (x + y) % 2 == 0) {
          // terraced tea rows along the hill
          line(c, iso.p(x.toDouble(), y + .5), iso.p(x + 1.0, y + .5), const Color(0x3326501A), 2.2);
        } else if (zone == Zone.flats && hash2(x, y, 6) < .3) {
          // silt ripples left by the river
          final at = iso.p(x + .5, y + .5);
          line(c, at - const Offset(5, 1), at + const Offset(5, -1), const Color(0x40FFFFFF), 1.2);
        }
        // grass tufts
        if (hash2(x, y, 3) < .55) {
          final at = iso.p(x + .2 + hash2(x, y, 4) * .6, y + .2 + hash2(x, y, 5) * .6);
          for (var k = -1; k <= 1; k++) {
            line(c, at, at + Offset(k * 2.2, -4.5 + k.abs().toDouble()), const Color(0xFF6A9F3A), 1.1);
          }
        }
        if (hash2(x, y, 9) < .06) {
          circle(c, iso.p(x + .5, y + .4), 1.6, const Color(0xFFFFF59D));
          circle(c, iso.p(x + .6, y + .6), 1.4, const Color(0xFFFFFFFF));
        }
      }
    }
  }
  // river bank
  for (var x = -6; x < mapSize + 6; x++) {
    fillPoly(c, [iso.p(x.toDouble(), 2), iso.p(x + 1.0, 2), iso.p(x + 1.0, 2.0, -0.0) + const Offset(0, 4), iso.p(x.toDouble(), 2) + const Offset(0, 4)],
        const Color(0xFF9C7A4D));
    fillPoly(c, [iso.p(x.toDouble(), -1), iso.p(x + 1.0, -1), iso.p(x + 1.0, -1) + const Offset(0, -3), iso.p(x.toDouble(), -1) + const Offset(0, -3)],
        const Color(0xFF8BB653));
  }
  // road continues out of the map both ways, with a little bridge over the river
  for (var y = -6; y < 2; y++) {
    if (y >= -1) continue;
    fillPoly(c, diamond(iso, 11, y.toDouble(), 1, 1), concreteRoad ? concrete : dirtRoad);
  }
  for (var y = mapSize; y < mapSize + 6; y++) {
    fillPoly(c, diamond(iso, 11, y.toDouble(), 1, 1), concreteRoad ? concrete : dirtRoad);
  }
  _bridge(c, iso, concreteRoad);

  // unowned land: darker, with lot borders
  for (var x = 0; x < mapSize; x++) {
    for (var y = 0; y < mapSize; y++) {
      if (Farm.terrain(x, y) == 'water') continue;
      if (!farm.owned(x, y)) {
        fillPoly(c, diamond(iso, x.toDouble(), y.toDouble(), 1, 1), const Color(0x38223311));
      }
    }
  }
  for (var lot = 0; lot < lotsPerSide * lotsPerSide; lot++) {
    final lx = (lot % lotsPerSide) * lotSize.toDouble(), ly = (lot ~/ lotsPerSide) * lotSize.toDouble();
    final own = farm.lots.contains(lot);
    if (own) continue;
    final y0 = math.max(ly, 2.0);
    strokePoly(c, diamond(iso, lx + .06, y0 + .06, lotSize - .12, ly + lotSize - y0 - .12),
        const Color(0x55FFFFFF), 1.2);
  }
  // owned boundary: little wooden fence posts along the edge of owned land
  for (var x = 0; x < mapSize; x++) {
    for (var y = 0; y < mapSize; y++) {
      if (!farm.owned(x, y) || Farm.terrain(x, y) == 'water') continue;
      final edges = [
        (x, y - 1, iso.p(x.toDouble(), y.toDouble()), iso.p(x + 1.0, y.toDouble())),
        (x - 1, y, iso.p(x.toDouble(), y.toDouble()), iso.p(x.toDouble(), y + 1.0)),
        (x, y + 1, iso.p(x.toDouble(), y + 1.0), iso.p(x + 1.0, y + 1.0)),
        (x + 1, y, iso.p(x + 1.0, y.toDouble()), iso.p(x + 1.0, y + 1.0)),
      ];
      for (final (nx, ny, a, b) in edges) {
        final out = nx < 0 || ny < 0 || nx >= mapSize || ny >= mapSize ||
            !farm.owned(nx, ny);
        if (out && Farm.terrain(nx.clamp(0, mapSize - 1), ny.clamp(0, mapSize - 1)) != 'water') {
          line(c, a, b, const Color(0xAAF5E6B8), 1.6);
        }
      }
    }
  }
  // the lotus lake, over the lot lines
  for (var x = 0; x < mapSize; x++) {
    for (var y = 0; y < mapSize; y++) {
      if (Farm.isLake(x, y)) _lakeTile(c, iso, x, y, diamond(iso, x.toDouble(), y.toDouble(), 1, 1));
    }
  }
  for (var x = 0; x < mapSize; x++) {
    for (var y = 0; y < mapSize; y++) {
      if (Farm.isLake(x, y)) _lakeDeco(c, iso, x, y);
    }
  }
  // bamboo hedge (lũy tre) beyond the river and along the far-left edge
  for (var x = -5; x < mapSize + 5; x += 1) {
    if (x == 11 || x == 10 || x == 12) continue;
    if (hash2(x, 99) < .75) drawBamboo(c, iso.p(x + .5, -2.5), 0.8 + hash2(x, 98) * .5, seed: x);
  }
  for (var y = 3; y < mapSize + 5; y += 1) {
    if (hash2(-3, y) < .6) drawBamboo(c, iso.p(-1.6, y + .5), 0.7 + hash2(y, 97) * .5, seed: y + 50);
  }
}

/// Ground looks of the outer ring (purely visual; all of it is farmland).
enum Zone { plain, flats, tea }

Zone groundZone(int x, int y) {
  if (x >= legacyMapSize && y < 12) return Zone.flats; // bãi bồi by the river
  if (y >= legacyMapSize + 2 && x < 10) return Zone.tea; // đồi chè
  return Zone.plain;
}

void _lakeTile(Canvas c, Iso iso, int x, int y, List<Offset> d) {
  bool lake(int a, int b) => Farm.isLake(a, b);
  final shore = !lake(x - 1, y) || !lake(x + 1, y) || !lake(x, y - 1) || !lake(x, y + 1);
  fillPoly(c, d, shore ? const Color(0xFF5FB0C8) : const Color(0xFF3F92BC));
  // muddy bank on the land side
  for (final (nx, ny, a, b) in [
    (x, y + 1, iso.p(x.toDouble(), y + 1.0), iso.p(x + 1.0, y + 1.0)),
    (x + 1, y, iso.p(x + 1.0, y.toDouble()), iso.p(x + 1.0, y + 1.0)),
  ]) {
    if (!lake(nx, ny)) {
      fillPoly(c, [a, b, b + const Offset(0, 3), a + const Offset(0, 3)], const Color(0xFF9C7A4D));
    }
  }
}

/// Lotus leaves, flowers and reeds on top of the water tiles.
void _lakeDeco(Canvas c, Iso iso, int x, int y) {
  bool lake(int a, int b) => Farm.isLake(a, b);
  final shore = !lake(x - 1, y) || !lake(x + 1, y) || !lake(x, y - 1) || !lake(x, y + 1);
  if (shore && hash2(x, y, 25) < .7) {
    // reeds at the edge
    final at = iso.p(x + .5, y + .5);
    for (var k = 0; k < 5; k++) {
      final dx = (k - 2) * 2.4 + hash2(x, y, 30 + k) * 1.5;
      line(c, at + Offset(dx, 2), at + Offset(dx * 1.3, -9 - hash2(x, y, 40 + k) * 6), const Color(0xFF5E8F2F), 1.4);
    }
    return;
  }
  for (var k = 0; k < 2; k++) {
    if (hash2(x, y, 21 + k * 7) > .6) continue;
    final at = iso.p(x + .2 + hash2(x, y, 22 + k * 7) * .6, y + .2 + hash2(x, y, 23 + k * 7) * .6);
    oval(c, at + const Offset(0, 1), 9, 4.6, const Color(0x33103040));
    oval(c, at, 9, 4.6, const Color(0xFF4E9A3A));
    oval(c, at - const Offset(.8, .8), 7.4, 3.4, const Color(0xFF6DB84E));
    line(c, at, at + const Offset(6, -2), const Color(0xFF4E9A3A), 1.2);
    if (hash2(x, y, 24 + k * 7) < .45) {
      final f = at - const Offset(1, 5);
      for (final dx in [-3.0, 0.0, 3.0]) {
        fillPoly(c, [f + Offset(dx * .9, 2), f + Offset(dx * 1.3, -3), f + Offset(dx * .3, -1)], const Color(0xFFF06292));
      }
      fillPoly(c, [f + const Offset(-1.6, 2), f + const Offset(0, -5), f + const Offset(1.6, 2)], const Color(0xFFF8BBD0));
      circle(c, f + const Offset(0, 1), 1.3, const Color(0xFFFFEB3B));
    }
  }
}

void _bridge(Canvas c, Iso iso, bool concreteRoad) {
  final deck = concreteRoad ? const Color(0xFFB4B8B5) : const Color(0xFF9B6B3D);
  final side = concreteRoad ? const Color(0xFF8E9390) : const Color(0xFF7A522C);
  box(c, iso, 11, -1, 1, 3, 4, 8, deck, side, shade(side, -.1));
  for (var i = 0; i <= 3; i++) {
    final a = iso.p(11, -1 + i.toDouble(), 8), b = iso.p(12, -1 + i.toDouble(), 8);
    line(c, a, a - const Offset(0, 7), side, 2);
    line(c, b, b - const Offset(0, 7), side, 2);
  }
  line(c, iso.p(11, -1, 15), iso.p(11, 2, 15), side, 2);
  line(c, iso.p(12, -1, 15), iso.p(12, 2, 15), side, 2);
}

/// Animated sparkle on the river.
void drawWaterAnim(Canvas c, Iso iso, double t) {
  for (var i = 0; i < 60; i++) {
    final x = (i * 2.37 + t * .25) % (mapSize + 12) - 6;
    final y = -1 + hash2(i, 3) * 2.8;
    final a = (math.sin(t * 2 + i) + 1) / 2;
    final p = iso.p(x, y);
    line(c, p, p + const Offset(7, 0), Color.fromRGBO(255, 255, 255, .25 + .4 * a), 1.3);
  }
}
