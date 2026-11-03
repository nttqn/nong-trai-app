// Crops, trees, bamboo and other plants. All positions are screen-space
// "foot" points; sizes are in pixels at zoom 1.

import 'dart:math' as math;
import 'dart:ui';

import 'iso.dart';

const leaf = Color(0xFF4E9A2E), leafDark = Color(0xFF3B7A22), leafLight = Color(0xFF7CC04A);

void drawBamboo(Canvas c, Offset foot, double s, {int seed = 0, double t = 0}) {
  shadow(c, foot, 14 * s, 5 * s);
  final rnd = math.Random(seed);
  for (var i = 0; i < 6; i++) {
    final dx = (rnd.nextDouble() - .5) * 14 * s;
    final hgt = (48 + rnd.nextDouble() * 26) * s;
    final lean = (rnd.nextDouble() - .5) * 18 * s + math.sin(t * .8 + seed + i) * 1.5;
    final a = foot + Offset(dx, 0), b = foot + Offset(dx + lean, -hgt);
    line(c, a, b, const Color(0xFF7FA43A), 2.2 * s);
    for (var k = 1; k < 4; k++) {
      final p = Offset.lerp(a, b, k / 4)!;
      line(c, p - const Offset(1.5, 0), p + const Offset(1.5, 0), const Color(0xFF5C7D27), 1);
    }
    // feathery leaf clusters
    for (var k = 0; k < 4; k++) {
      final p = Offset.lerp(a, b, .45 + k * .17)!;
      final dir = k.isEven ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(p.dx + dir * 8 * s, p.dy - 4 * s, p.dx + dir * 14 * s, p.dy + 2 * s)
        ..quadraticBezierTo(p.dx + dir * 7 * s, p.dy + 1 * s, p.dx, p.dy);
      pathFill(c, path, k.isEven ? const Color(0xFF6BA83A) : const Color(0xFF5A9630));
    }
  }
  oval(c, foot + Offset(0, -55 * s), 15 * s, 13 * s, const Color(0x8869A93A));
}

/// Rice clump. g: 0..1 growth; ripe turns it golden and drooping.
void drawRice(Canvas c, Offset base, double g, bool ripe, double t, int seed) {
  final h = 4 + g * 13;
  final sway = math.sin(t * 1.5 + seed) * (0.6 + g);
  final col = ripe ? const Color(0xFFE2B940) : Color.lerp(const Color(0xFF9BD25B), const Color(0xFF4F9B2D), g)!;
  for (var i = -2; i <= 2; i++) {
    final tip = base + Offset(i * (1.4 + g * 1.3) + sway, -h + i.abs() * 1.5);
    line(c, base, tip, col, 1.3);
    if (ripe) {
      final droop = tip + Offset(i >= 0 ? 3 : -3, 3);
      line(c, tip, droop, const Color(0xFFC9962A), 2);
    }
  }
}

/// Crop on a dry bed. id: crop id; g growth 0..1.
void drawBedCrop(Canvas c, String id, Offset b, double g, bool ripe, double t, int seed) {
  final s = 0.35 + 0.65 * g;
  final sway = math.sin(t * 1.3 + seed) * 0.8;
  switch (id) {
    case 'rau':
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + (i - 2) * 0.5;
        final tip = b + Offset(math.cos(a) * 7 * s + sway, math.sin(a) * 7 * s);
        line(c, b, tip, const Color(0xFF6FAE48), 1.2);
        oval(c, tip, 3.2 * s, 1.8 * s, i.isEven ? const Color(0xFF5DAF3A) : const Color(0xFF79C24E));
      }
    case 'ngo':
      final h = 26 * s;
      line(c, b, b + Offset(sway, -h), const Color(0xFF7DAA3D), 2);
      for (var k = 0; k < 3; k++) {
        final p = b + Offset(sway * k / 3, -h * (0.3 + k * .22));
        final dir = k.isEven ? 1.0 : -1.0;
        final path = Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(p.dx + dir * 7 * s, p.dy - 6 * s, p.dx + dir * 11 * s, p.dy + 1);
        pathStroke(c, path, const Color(0xFF6A9F36), 2.2);
      }
      line(c, b + Offset(sway, -h), b + Offset(sway, -h - 5), const Color(0xFFD9C27A), 1.5);
      if (ripe) {
        oval(c, b + Offset(3 + sway * .5, -h * .55), 2.6, 5, const Color(0xFFF2C94C));
        line(c, b + Offset(3 + sway * .5, -h * .55 - 5), b + Offset(5, -h * .55 - 9), const Color(0xFFB8860B), 1);
      }
    case 'khoai':
      if (ripe) {
        oval(c, b + const Offset(-3, 1), 4, 2.6, const Color(0xFFA8466A));
        oval(c, b + const Offset(3, 2), 3.5, 2.2, const Color(0xFFB65477));
      }
      for (var i = 0; i < 4; i++) {
        final p = b + Offset((i - 1.5) * 4 * s + sway * .3, -3 - (i % 2) * 3 * s);
        _heartLeaf(c, p, 3.4 * s, i.isEven ? const Color(0xFF5E8F3A) : const Color(0xFF6E5A8A));
      }
    case 'lac':
      oval(c, b + Offset(0, -3 * s), 6 * s, 4 * s, const Color(0xFF5C9E3C));
      oval(c, b + Offset(-2 * s, -5 * s), 3.5 * s, 2.5 * s, const Color(0xFF79BB52));
      if (ripe) {
        for (var i = 0; i < 3; i++) {
          oval(c, b + Offset(-4 + i * 4.0, 2), 1.8, 1.2, const Color(0xFFC79A5B));
        }
      } else if (g > .6) {
        circle(c, b + Offset(2, -6 * s), 1.2, const Color(0xFFFFD54F));
      }
    case 'dau':
      oval(c, b + Offset(0, -4 * s), 6 * s, 5 * s, const Color(0xFF4F9A34));
      oval(c, b + Offset(2 * s, -7 * s), 4 * s, 3 * s, const Color(0xFF68B347));
      if (ripe) {
        for (var i = 0; i < 3; i++) {
          line(c, b + Offset(-4 + i * 3.5, -5), b + Offset(-3 + i * 3.5, 0), const Color(0xFF2E6B1E), 1.8);
        }
      }
    case 'mia':
      for (var i = -1; i <= 1; i++) {
        final h = 32 * s;
        final top = b + Offset(i * 3.0 + sway, -h);
        line(c, b + Offset(i * 3.0, 0), top, const Color(0xFF7B3F8C), 2.4);
        for (var k = 1; k < 4; k++) {
          final p = Offset.lerp(b + Offset(i * 3.0, 0), top, k / 4)!;
          line(c, p - const Offset(1.4, 0), p + const Offset(1.4, 0), const Color(0xFF4E2459), 1);
        }
        final path = Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(top.dx + i * 6 + 4, top.dy - 2, top.dx + i * 9 + 6, top.dy + 6);
        pathStroke(c, path, const Color(0xFF7DB043), 1.6);
        final path2 = Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(top.dx - 5, top.dy - 3, top.dx - 8, top.dy + 5);
        pathStroke(c, path2, const Color(0xFF6A9F36), 1.6);
      }
    case 'ot':
      oval(c, b + Offset(0, -5 * s), 6 * s, 5.5 * s, const Color(0xFF3E8A2C));
      oval(c, b + Offset(-2 * s, -8 * s), 4 * s, 3 * s, const Color(0xFF59A53D));
      final n = ripe ? 5 : (g > .5 ? 2 : 0);
      for (var i = 0; i < n; i++) {
        final p = b + Offset(-4 + i * 2.2, -4 - (i % 2) * 4.0);
        line(c, p, p + const Offset(0.6, 3.6), ripe ? const Color(0xFFE53935) : const Color(0xFF8BC34A), 1.8);
      }
    case 'dua':
      for (var i = 0; i < 4; i++) {
        _heartLeaf(c, b + Offset(-7 + i * 4.5, -1 - (i % 2) * 2.0), 3 * s, const Color(0xFF4F8F33));
      }
      if (g > .4) {
        final r = ripe ? 5.5 : 3.2;
        final p = b + const Offset(1, 0);
        oval(c, p, r, r * .8, const Color(0xFF2F7D32));
        for (var k = -1; k <= 1; k++) {
          line(c, p + Offset(k * r * .5, -r * .7), p + Offset(k * r * .5, r * .7), const Color(0xFF8BC34A), 0.9);
        }
      }
    case 'cuc':
      oval(c, b + Offset(0, -5 * s), 7 * s, 5 * s, const Color(0xFF4B8F30));
      if (g > .5 || ripe) {
        final n = ripe ? 6 : 3;
        for (var i = 0; i < n; i++) {
          final p = b + Offset(-6 + (i % 3) * 6.0 + sway * .4, -7 - (i ~/ 3) * 4.0);
          for (var k = 0; k < 6; k++) {
            final a = k * math.pi / 3;
            circle(c, p + Offset(math.cos(a) * 2, math.sin(a) * 1.4), 1.5,
                ripe ? const Color(0xFFFFC107) : const Color(0xFFDCE775));
          }
          circle(c, p, 1.1, const Color(0xFFE65100));
        }
      }
    default:
      oval(c, b + Offset(0, -4 * s), 5 * s, 4 * s, leaf);
  }
}

void _heartLeaf(Canvas c, Offset p, double r, Color col) {
  final path = Path()
    ..moveTo(p.dx, p.dy + r)
    ..cubicTo(p.dx - r * 1.6, p.dy - r * .2, p.dx - r * .6, p.dy - r * 1.4, p.dx, p.dy - r * .5)
    ..cubicTo(p.dx + r * .6, p.dy - r * 1.4, p.dx + r * 1.6, p.dy - r * .2, p.dx, p.dy + r)
    ..close();
  pathFill(c, path, col);
}

/// Fruit trees. fruit: 0..1 how laden it is.
void drawTree(Canvas c, String type, Offset f, double fruit, double t, int seed) {
  final sway = math.sin(t * .9 + seed) * 1.2;
  switch (type) {
    case 'cay_chuoi':
      shadow(c, f, 13, 5);
      line(c, f, f + Offset(sway * .3, -26), const Color(0xFF8DA65A), 5);
      for (var i = 0; i < 6; i++) {
        final a = -math.pi / 2 + (i - 2.5) * 0.55;
        final top = f + Offset(sway * .3, -26);
        final tip = top + Offset(math.cos(a) * 22 + sway, math.sin(a) * 14 + 8);
        final ctrl = top + Offset(math.cos(a) * 12, math.sin(a) * 14 - 6);
        final path = Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy - 3, tip.dx, tip.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy + 3, top.dx, top.dy);
        pathFill(c, path, i.isEven ? const Color(0xFF6DB33F) : const Color(0xFF58A033));
        line(c, top, tip, const Color(0xFF9CCB6B), 0.8);
      }
      if (fruit > .3) {
        final p = f + const Offset(5, -18);
        line(c, p + const Offset(0, -6), p, const Color(0xFF6B8E23), 1.5);
        final ripe = fruit >= 1;
        for (var k = 0; k < (2 + fruit * 3).round(); k++) {
          oval(c, p + Offset(k.isEven ? -2 : 2, k * 2.2), 3.2, 1.6,
              ripe ? const Color(0xFFFFD93B) : const Color(0xFF9CCC65));
        }
        oval(c, p + const Offset(0, 12), 2, 3, const Color(0xFF8E2B4E));
      }
    case 'cay_dua':
      shadow(c, f, 12, 4);
      final top = f + Offset(8 + sway, -46);
      final trunk = Path()
        ..moveTo(f.dx, f.dy)
        ..quadraticBezierTo(f.dx + 1, f.dy - 26, top.dx, top.dy);
      pathStroke(c, trunk, const Color(0xFF8B6B47), 4.5);
      for (var i = 0; i < 4; i++) {
        final p = Offset.lerp(f, top, i / 4)!;
        line(c, p - const Offset(2, 0), p + const Offset(2, 0), const Color(0xFF6E5236), 1);
      }
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + .2;
        final tip = top + Offset(math.cos(a) * 22, math.sin(a) * 9 + 6);
        final path = Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo((top.dx + tip.dx) / 2, top.dy - 7, tip.dx, tip.dy);
        pathStroke(c, path, i.isEven ? const Color(0xFF4E9A2E) : const Color(0xFF66AF3D), 3);
      }
      final n = (fruit * 4).round();
      for (var k = 0; k < n; k++) {
        circle(c, top + Offset(-4 + k * 2.6, 3 + (k % 2) * 2.0), 2.8,
            fruit >= 1 ? const Color(0xFF8D6E3F) : const Color(0xFF7CB342));
      }
    default:
      // round-canopy fruit trees: xoài, bưởi, vải
      final (canopy, fruitCol, r) = switch (type) {
        'cay_xoai' => (const Color(0xFF3F7F2A), const Color(0xFFFFB300), 17.0),
        'cay_buoi' => (const Color(0xFF5B9A36), const Color(0xFFD4E157), 16.0),
        'cay_vai' => (const Color(0xFF47852C), const Color(0xFFE53935), 16.0),
        _ => (leaf, const Color(0xFFFFC107), 15.0),
      };
      shadow(c, f, r * .9, r * .35);
      line(c, f, f + const Offset(0, -16), const Color(0xFF6D4C30), 4.5);
      line(c, f + const Offset(0, -12), f + const Offset(-6, -20), const Color(0xFF6D4C30), 2.5);
      final cc = f + Offset(sway * .5, -28);
      for (final (dx, dy, rr, col) in [
        (-9.0, 3.0, r * .7, shade(canopy, -.06)),
        (9.0, 3.0, r * .7, shade(canopy, -.08)),
        (0.0, -4.0, r * .85, canopy),
        (-5.0, -9.0, r * .55, shade(canopy, .06)),
        (6.0, -7.0, r * .5, shade(canopy, .04)),
      ]) {
        circle(c, cc + Offset(dx, dy), rr, col);
      }
      final rng = math.Random(seed * 13 + type.length);
      final n = (fruit * 7).round();
      for (var k = 0; k < n; k++) {
        final p = cc + Offset((rng.nextDouble() - .5) * r * 1.6, (rng.nextDouble() - .3) * r);
        final ripe = fruit >= 1;
        circle(c, p, type == 'cay_vai' ? 1.8 : 2.8,
            ripe ? fruitCol : Color.lerp(const Color(0xFF8BC34A), fruitCol, .3)!);
      }
  }
}

void drawPeach(Canvas c, Offset f, double t) {
  shadow(c, f, 12, 4);
  line(c, f, f + const Offset(-2, -14), const Color(0xFF5D3A26), 3.5);
  line(c, f + const Offset(-2, -14), f + const Offset(-9, -24), const Color(0xFF5D3A26), 2.2);
  line(c, f + const Offset(-2, -14), f + const Offset(6, -25), const Color(0xFF5D3A26), 2.2);
  line(c, f + const Offset(-2, -14), f + const Offset(-1, -30), const Color(0xFF5D3A26), 2);
  final rng = math.Random(4);
  for (var i = 0; i < 26; i++) {
    final p = f + Offset(-14 + rng.nextDouble() * 26, -34 + rng.nextDouble() * 18);
    circle(c, p, 2.4, i % 3 == 0 ? const Color(0xFFF8BBD0) : const Color(0xFFF06292));
  }
}

void drawBanyan(Canvas c, Offset f, double t) {
  shadow(c, f, 34, 13);
  final trunk = Path()
    ..moveTo(f.dx - 9, f.dy)
    ..quadraticBezierTo(f.dx - 4, f.dy - 20, f.dx - 6, f.dy - 34)
    ..lineTo(f.dx + 6, f.dy - 34)
    ..quadraticBezierTo(f.dx + 4, f.dy - 20, f.dx + 10, f.dy)
    ..close();
  pathFill(c, trunk, const Color(0xFF7A6248));
  for (var i = 0; i < 7; i++) {
    final x = -26 + i * 9.0;
    line(c, f + Offset(x, -40), f + Offset(x * .9, -6 + (i % 2) * 4.0), const Color(0xAA8A7158), 1);
  }
  for (final (dx, dy, r, col) in [
    (-22.0, -40.0, 17.0, const Color(0xFF2F6E25)),
    (22.0, -40.0, 17.0, const Color(0xFF2B6622)),
    (0.0, -50.0, 24.0, const Color(0xFF357A2A)),
    (-12.0, -60.0, 15.0, const Color(0xFF428A32)),
    (12.0, -58.0, 14.0, const Color(0xFF3E842F)),
  ]) {
    circle(c, f + Offset(dx, dy), r, col);
  }
}

void drawBush(Canvas c, Offset f) {
  shadow(c, f, 12, 4);
  circle(c, f + const Offset(-5, -5), 7, const Color(0xFF4F8A2E));
  circle(c, f + const Offset(5, -5), 7, const Color(0xFF477F29));
  circle(c, f + const Offset(0, -10), 8, const Color(0xFF5E9D37));
  circle(c, f + const Offset(-3, -12), 2, const Color(0xFFE57373));
  circle(c, f + const Offset(4, -8), 1.6, const Color(0xFFFFFFFF));
}
