// Draws every placed object: plots, pens, ponds, workshops, the house,
// village projects, decorations and obstacles.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../core/defs.dart';
import '../core/farm.dart';
import 'animals.dart';
import 'ground.dart' show hash2;
import 'iso.dart';
import 'plants.dart';

const mudWall = Color(0xFFD9C29A), plaster = Color(0xFFF3DC8E), brick = Color(0xFFB5523B);
const wood = Color(0xFF8A5A33), woodDark = Color(0xFF6B4226);
const doorCol = Color(0xFF6D4126), windowCol = Color(0xFF3E5566);

void drawObj(Canvas c, Iso iso, Farm farm, Obj o, double t) {
  final x = o.x.toDouble(), y = o.y.toDouble();
  final foot = iso.p(x + o.w / 2, y + o.h / 2);
  switch (o.def.kind) {
    case BKind.paddy:
      _paddy(c, iso, farm, o, t);
    case BKind.bed:
      _bed(c, iso, farm, o, t);
    case BKind.pen:
      _pen(c, iso, farm, o, t);
    case BKind.pond:
      _pond(c, iso, farm, o, t);
    case BKind.tree:
      final fruit = farm.progress(o);
      drawTree(c, o.type, foot, fruit >= 1 ? 1 : fruit * .7, t, o.id);
    case BKind.factory:
      _factory(c, iso, farm, o, t);
    case BKind.house:
      drawHouse(c, iso, x, y, o.level, t);
    case BKind.project:
      _project(c, iso, o.type, x, y, t);
    case BKind.deco:
      _deco(c, iso, o.type, x, y, foot, t, o.id);
    case BKind.obstacle:
      _obstacle(c, o.type, foot, o.id);
  }
}

// ------------------------------------------------------------------ plots
void _paddy(Canvas c, Iso iso, Farm farm, Obj o, double t) {
  final x = o.x.toDouble(), y = o.y.toDouble();
  fillPoly(c, diamond(iso, x, y, 1, 1), const Color(0xFF9C7A4D)); // dike
  final inner = diamond(iso, x + .1, y + .1, .8, .8, -1);
  fillPoly(c, inner, const Color(0xFF6FA9A0));
  // sky reflection
  final r = (math.sin(t * .8 + o.id) + 1) / 2;
  line(c, iso.p(x + .25, y + .3, -1), iso.p(x + .5, y + .3, -1), Color.fromRGBO(255, 255, 255, .25 + .2 * r), 1.2);
  strokePoly(c, diamond(iso, x, y, 1, 1), const Color(0xFF8A6A40), 1);
  if (o.crop == null) return;
  final g = farm.progress(o);
  final ripe = farm.isReady(o);
  for (var j = 0; j < 3; j++) {
    for (var i = 0; i < 3; i++) {
      drawRice(c, iso.p(x + .22 + i * .28, y + .22 + j * .28, -1), g, ripe, t, o.id * 9 + i + j * 3);
    }
  }
}

void _bed(Canvas c, Iso iso, Farm farm, Obj o, double t) {
  final x = o.x.toDouble(), y = o.y.toDouble();
  fillPoly(c, diamond(iso, x + .04, y + .04, .92, .92), const Color(0xFF8B5E3C));
  for (var k = 0; k < 3; k++) {
    final yy = y + .2 + k * .3;
    fillPoly(c, [iso.p(x + .1, yy - .08, 1.5), iso.p(x + .9, yy - .08, 1.5), iso.p(x + .9, yy + .08, 1.5), iso.p(x + .1, yy + .08, 1.5)],
        const Color(0xFFA0714A));
    line(c, iso.p(x + .1, yy + .08, 1.5), iso.p(x + .9, yy + .08, 1.5), const Color(0xFF6E4A2C), 1);
  }
  if (o.crop == null) return;
  final g = farm.progress(o);
  final ripe = farm.isReady(o);
  for (var k = 0; k < 3; k++) {
    for (var i = 0; i < 2; i++) {
      drawBedCrop(c, o.crop!, iso.p(x + .3 + i * .4, y + .2 + k * .3, 1.5), g, ripe, t, o.id * 7 + k * 2 + i);
    }
  }
}

// ------------------------------------------------------------------ pens
void _pen(Canvas c, Iso iso, Farm farm, Obj o, double t) {
  final x = o.x.toDouble(), y = o.y.toDouble();
  final a = animalForPen(o.type)!;
  final ground = switch (a.id) {
    'lon' => const Color(0xFF9E7B57),
    'vit' => const Color(0xFFA9B76A),
    'trau' || 'bo' => const Color(0xFFB59B62),
    _ => const Color(0xFFD7BE7E),
  };
  fillPoly(c, diamond(iso, x + .05, y + .05, 1.9, 1.9), ground);
  for (var i = 0; i < 14; i++) {
    final p = iso.p(x + .2 + hash2(o.id, i) * 1.6, y + .2 + hash2(i, o.id) * 1.6);
    line(c, p, p + const Offset(3, -1), shade(ground, .12), 1);
  }
  if (a.id == 'vit' || a.id == 'trau') {
    // small pool / mud wallow
    final pc = iso.p(x + .55, y + 1.4);
    oval(c, pc, 16, 7, a.id == 'vit' ? const Color(0xFF5DA9CF) : const Color(0xFF7A6247));
    ovalStroke(c, pc, 16, 7, const Color(0x55FFFFFF), 1);
  }
  _fence(c, iso, x, y, 2, 2, back: true);
  // shed at the back corner
  final roof = a.id == 'ga' || a.id == 'vit' ? RoofStyle.thatch : RoofStyle.tile;
  wallBox(c, iso, x + .15, y + .15, .9, .75, 0, 16, const Color(0xFFC8A777));
  leftWallRect(c, iso, x + .4, y + .9, x + .75, 0, 11, const Color(0xFF4A3424));
  gableRoof(c, iso, x + .15, y + .15, .9, .75, 16, 11, roof, alongX: false, gableWall: const Color(0xFFC8A777));
  // trough
  {
    box(c, iso, x + 1.2, y + .2, .6, .25, 0, 4, const Color(0xFF7D5A3A), const Color(0xFF6B4A2E), const Color(0xFF5A3D25));
    if (o.end != 0 && !farm.isReady(o)) {
      fillPoly(c, diamond(iso, x + 1.25, y + .23, .5, .19, 4), a.feed == 'cam' ? const Color(0xFFBCAAA4) : const Color(0xFFE8C766));
    }
  }
  // animals wander
  final n = o.count;
  final producing = o.end != 0;
  for (var i = 0; i < n; i++) {
    final speed = producing ? .35 : .15;
    final px = x + 1 + math.cos(t * speed + i * 2.1) * .55 + (i % 3 - 1) * .18;
    final py = y + 1.15 + math.sin(t * speed * .8 + i * 1.3) * .5 + (i ~/ 3 - .5) * .25;
    final dir = -math.sin(t * speed + i * 2.1) >= 0 ? 1.0 : -1.0;
    drawAnimal(c, a.id, iso.p(px.clamp(x + .35, x + 1.7), py.clamp(y + .9, y + 1.8)), dir, t, i.toDouble());
  }
  // products on the ground
  if (farm.isReady(o)) {
    for (var i = 0; i < math.min(n, 6); i++) {
      final p = iso.p(x + .4 + (i % 3) * .5, y + 1.75 - (i ~/ 3) * .3);
      if (a.product == 'trung' || a.product == 'trungvit') {
        oval(c, p, 2.6, 3.2, a.product == 'trung' ? const Color(0xFFF3E3C3) : const Color(0xFFCFE8DF));
      }
    }
  }
  _fence(c, iso, x, y, 2, 2, gateFront: true, back: false);
}

void _fence(Canvas c, Iso iso, double x, double y, double w, double h, {bool gateFront = false, required bool back}) {
  const post = Color(0xFF7A5230), rail = Color(0xFFA67A4A);
  void run(double x0, double y0, double x1, double y1, int n, {bool front = false}) {
    for (var i = 0; i <= n; i++) {
      final f = i / n;
      final p = iso.p(x0 + (x1 - x0) * f, y0 + (y1 - y0) * f);
      if (front && gateFront && i > n / 2 - 1 && i < n / 2 + 1) continue;
      line(c, p, p - const Offset(0, 9), post, 2);
    }
    for (final z in [4.0, 8.0]) {
      if (front && gateFront) {
        line(c, iso.p(x0, y0, z), iso.p(x0 + (x1 - x0) * .38, y0 + (y1 - y0) * .38, z), rail, 1.4);
        line(c, iso.p(x0 + (x1 - x0) * .62, y0 + (y1 - y0) * .62, z), iso.p(x1, y1, z), rail, 1.4);
      } else {
        line(c, iso.p(x0, y0, z), iso.p(x1, y1, z), rail, 1.4);
      }
    }
  }
  if (back) {
    run(x, y, x + w, y, 6);
    run(x, y, x, y + h, 6);
  } else {
    run(x + w, y, x + w, y + h, 6);
    run(x, y + h, x + w, y + h, 6, front: true);
  }
}

// ------------------------------------------------------------------ pond
void _pond(Canvas c, Iso iso, Farm farm, Obj o, double t) {
  final x = o.x.toDouble(), y = o.y.toDouble();
  final cx = iso.p(x + 1, y + 1);
  oval(c, cx, 54, 27, const Color(0xFF8A6A42));
  oval(c, cx + const Offset(0, 2), 50, 24, const Color(0xFF3B86B0));
  oval(c, cx + const Offset(0, 4), 44, 20, const Color(0xFF4A9CC6));
  for (var i = 0; i < 3; i++) {
    final r = ((t * .4 + i / 3) % 1);
    ovalStroke(c, cx + Offset(-14 + i * 14.0, 4), 4 + r * 14, 2 + r * 6, Color.fromRGBO(255, 255, 255, .35 * (1 - r)), 1);
  }
  // lotus pads
  for (final (dx, dy) in [(-30.0, 8.0), (-24.0, 14.0), (26.0, 0.0)]) {
    oval(c, cx + Offset(dx, dy), 5, 2.6, const Color(0xFF5E9E3A));
  }
  circle(c, cx + const Offset(-27, 6), 2.4, const Color(0xFFF48FB1));
  // little wooden jetty
  box(c, iso, x + 1.55, y + 1.6, .4, .35, 2, 4, const Color(0xFFB08455), wood, woodDark);
  if (o.crop != null) {
    final ready = farm.isReady(o);
    final n = ready ? 5 : 3;
    for (var i = 0; i < n; i++) {
      final a = t * (ready ? 1.2 : .6) + i * 2.4;
      final p = cx + Offset(math.cos(a) * 26, 4 + math.sin(a) * 10);
      oval(c, p, 5, 2, const Color(0x6623465A));
    }
    if (ready) {
      final j = (t * 1.3) % 2;
      if (j < 1) {
        final p = cx + Offset(10, -math.sin(j * math.pi) * 16);
        oval(c, p, 4.5, 2.2, o.crop == 'cachep' ? const Color(0xFFF0A040) : const Color(0xFF8FB8D0));
      }
    }
  }
}

// ------------------------------------------------------------------ workshops
void _factory(Canvas c, Iso iso, Farm farm, Obj o, double t) {
  final x = o.x.toDouble(), y = o.y.toDouble();
  fillPoly(c, diamond(iso, x + .05, y + .05, 1.9, 1.9), const Color(0xFFCDB58A));
  final working = o.jobs.isNotEmpty && farm.now() < o.jobs.last.end;
  switch (o.type) {
    case 'may_xay':
      wallBox(c, iso, x + .25, y + .2, 1.5, 1.2, 0, 24, const Color(0xFFD9C7A0));
      leftWallRect(c, iso, x + .6, y + 1.4, x + 1.1, 0, 16, doorCol);
      rightWallRect(c, iso, x + 1.75, y + .5, y + .9, 9, 17, windowCol, frame: woodDark);
      gableRoof(c, iso, x + .25, y + .2, 1.5, 1.2, 24, 12, RoofStyle.tin, gableWall: const Color(0xFFD9C7A0));
      // hopper
      fillPoly(c, [iso.p(x + 1.3, y + .4, 44), iso.p(x + 1.7, y + .4, 44), iso.p(x + 1.55, y + .55, 34), iso.p(x + 1.45, y + .55, 34)], const Color(0xFF8E9BA3));
      // sacks
      for (var i = 0; i < 3; i++) {
        final p = iso.p(x + 1.6, y + 1.55 + i * .13);
        oval(c, p + const Offset(0, -5), 5, 6, const Color(0xFFEDE3C8));
        line(c, p + const Offset(-3, -10), p + const Offset(3, -10), const Color(0xFFB09A6A), 1);
      }
    case 'lo_banh':
      wallBox(c, iso, x + .3, y + .25, 1.4, 1.1, 0, 22, mudWall);
      leftWallRect(c, iso, x + .55, y + 1.35, x + .95, 0, 15, doorCol);
      gableRoof(c, iso, x + .3, y + .25, 1.4, 1.1, 22, 13, RoofStyle.tile, gableWall: mudWall);
      wallBox(c, iso, x + 1.3, y + .35, .2, .2, 30, 46, const Color(0xFF9E5B45));
      // pot of bánh chưng simmering outside
      final pot = iso.p(x + 1.6, y + 1.55);
      for (final dx in [-6.0, 0.0, 6.0]) {
        line(c, pot + Offset(dx, 0), pot + Offset(dx * .6, -6), const Color(0xFF555555), 1.4);
      }
      oval(c, pot + const Offset(0, 1), 5, 2, const Color(0xFFFF7043));
      oval(c, pot + const Offset(0, -10), 9, 4, const Color(0xFF4A4A4A));
      c.drawRect(Rect.fromLTWH(pot.dx - 9, pot.dy - 10, 18, 9), Paint()..color = const Color(0xFF3B3B3B));
      oval(c, pot + const Offset(0, -19), 9, 3.5, const Color(0xFF5A5A5A));
    case 'xuong_mia':
      wallBox(c, iso, x + .2, y + .25, 1.3, 1.1, 0, 20, const Color(0xFFE3D3B0));
      leftWallRect(c, iso, x + .5, y + 1.35, x + 1.0, 0, 14, doorCol);
      gableRoof(c, iso, x + .2, y + .25, 1.3, 1.1, 20, 12, RoofStyle.tin, alongX: false,
          gableWall: const Color(0xFFE3D3B0));
      for (var i = 0; i < 6; i++) {
        final a = iso.p(x + 1.55, y + .5 + i * .12, 2 + (i % 2) * 2);
        line(c, a, a + const Offset(18, 6), const Color(0xFF7B3F8C), 2.4);
      }
      // press wheel
      final w = iso.p(x + 1.5, y + 1.55, 10);
      ovalStroke(c, w, 7, 7, woodDark, 2);
      final ang = working ? t * 3 : 0.0;
      line(c, w, w + Offset(math.cos(ang) * 7, math.sin(ang) * 7), woodDark, 1.6);
    case 'xuong_ca':
      wallBox(c, iso, x + .2, y + .2, 1.1, 1.0, 0, 18, const Color(0xFFDCCFB0));
      gableRoof(c, iso, x + .2, y + .2, 1.1, 1.0, 18, 11, RoofStyle.thatch, gableWall: const Color(0xFFDCCFB0));
      leftWallRect(c, iso, x + .45, y + 1.2, x + .85, 0, 12, doorCol);
      for (var i = 0; i < 4; i++) {
        final p = iso.p(x + 1.45 + (i % 2) * .3, y + .55 + (i ~/ 2) * .55 + (i % 2) * .15);
        oval(c, p + const Offset(0, -7), 7, 8, const Color(0xFF8D5A35));
        oval(c, p + const Offset(0, -14), 5.5, 2, const Color(0xFF5B3A22));
        oval(c, p + const Offset(-2, -8), 2, 4, const Color(0x33FFFFFF));
      }
  }
  if (working) {
    final top = iso.p(x + 1, y + .8, 48);
    for (var i = 0; i < 3; i++) {
      final k = (t * .5 + i / 3) % 1;
      circle(c, top + Offset(math.sin(k * 6 + i) * 4, -k * 22), 3 + k * 5, Color.fromRGBO(240, 240, 240, .55 * (1 - k)));
    }
  }
}

// ------------------------------------------------------------------ house
void drawHouse(Canvas c, Iso iso, double x, double y, int level, double t) {
  // yard
  final yard = switch (level) {
    0 => const Color(0xFFC9A877),
    1 => const Color(0xFFC0705A),
    _ => const Color(0xFFCFCBC0),
  };
  fillPoly(c, diamond(iso, x + .1, y + .1, 2.8, 2.8), yard);
  if (level == 1) {
    for (var i = 1; i < 6; i++) {
      line(c, iso.p(x + .1 + i * .47, y + .1), iso.p(x + .1 + i * .47, y + 2.9), const Color(0x44FFFFFF), .8);
      line(c, iso.p(x + .1, y + .1 + i * .47), iso.p(x + 2.9, y + .1 + i * .47), const Color(0x44FFFFFF), .8);
    }
  }
  switch (level) {
    case 0: // nhà tranh vách đất
      wallBox(c, iso, x + .3, y + .3, 2.2, 1.3, 0, 20, mudWall);
      leftWallRect(c, iso, x + 1.1, y + 1.6, x + 1.6, 0, 15, doorCol);
      leftWallRect(c, iso, x + .5, y + 1.6, x + .85, 7, 14, const Color(0xFF4A3424));
      for (var i = 0; i < 3; i++) {
        line(c, iso.p(x + .53 + i * .12, y + 1.6, 7), iso.p(x + .53 + i * .12, y + 1.6, 14), wood, 1);
      }
      gableRoof(c, iso, x + .3, y + .3, 2.2, 1.3, 20, 20, RoofStyle.thatch, over: .22, gableWall: mudWall);
      // haystack + clothesline vibe: a chum by the door
      oval(c, iso.p(x + 2.3, y + 2.1) + const Offset(0, -6), 6, 7, const Color(0xFF7B4B2A));
      oval(c, iso.p(x + 2.3, y + 2.1) + const Offset(0, -13), 5, 2, const Color(0xFF4E2E18));
    case 1: // nhà gạch mái ngói
      wallBox(c, iso, x + .3, y + .25, 2.3, 1.4, 0, 24, plaster);
      // verandah columns
      for (var i = 0; i < 4; i++) {
        final p = iso.p(x + .4 + i * .7, y + 1.85);
        line(c, p, p - const Offset(0, 24), const Color(0xFFE9E1D0), 3);
      }
      fillPoly(c, diamond(iso, x + .3, y + 1.65, 2.3, .3), const Color(0xFFD8CBB0));
      for (var i = 0; i < 3; i++) {
        leftWallRect(c, iso, x + .5 + i * .7, y + 1.65, x + .85 + i * .7, 0, 17, i == 1 ? doorCol : const Color(0xFF7A4A2A), frame: woodDark);
      }
      gableRoof(c, iso, x + .3, y + .25, 2.3, 1.7, 24, 18, RoofStyle.tile, over: .14, gableWall: plaster);
    case 2: // nhà mái bằng
      wallBox(c, iso, x + .3, y + .3, 2.3, 1.5, 0, 34, const Color(0xFFEDEFE6));
      leftWallRect(c, iso, x + 1.15, y + 1.8, x + 1.65, 0, 20, const Color(0xFF8D5A3B), frame: woodDark);
      for (final xx in [.5, 1.95]) {
        leftWallRect(c, iso, x + xx, y + 1.8, x + xx + .4, 9, 22, windowCol, frame: const Color(0xFF9AA5AE));
      }
      rightWallRect(c, iso, x + 2.6, y + .6, y + 1.1, 9, 22, windowCol, frame: const Color(0xFF9AA5AE));
      // parapet + water tank
      box(c, iso, x + .25, y + .25, 2.4, 1.6, 34, 38, const Color(0xFFDCDDD3), const Color(0xFFC9CBC0), const Color(0xFFB5B7AC));
      fillPoly(c, diamond(iso, x + .35, y + .35, 2.2, 1.4, 38), const Color(0xFFB4B2A6));
      final tank = iso.p(x + .8, y + .7, 38);
      c.drawRect(Rect.fromLTWH(tank.dx - 7, tank.dy - 14, 14, 14), Paint()..color = const Color(0xFF90A4AE));
      oval(c, tank + const Offset(0, -14), 7, 2.5, const Color(0xFFB0BEC5));
    case 3: // nhà ống hai tầng
      wallBox(c, iso, x + .5, y + .3, 2.0, 1.6, 0, 52, const Color(0xFFF6E7A9));
      leftWallRect(c, iso, x + 1.1, y + 1.9, x + 1.9, 0, 20, const Color(0xFF90A4AE), frame: const Color(0xFF607D8B));
      // balcony
      box(c, iso, x + .5, y + 1.9, 2.0, .3, 24, 26, const Color(0xFFE0E0E0), const Color(0xFFBDBDBD), const Color(0xFF9E9E9E));
      for (var i = 0; i <= 8; i++) {
        final p = iso.p(x + .5 + i * .25, y + 2.2, 26);
        line(c, p, p - const Offset(0, 8), const Color(0xFF8D6E63), 1);
      }
      line(c, iso.p(x + .5, y + 2.2, 34), iso.p(x + 2.5, y + 2.2, 34), const Color(0xFF8D6E63), 1.5);
      leftWallRect(c, iso, x + 1.0, y + 1.9, x + 2.0, 28, 44, windowCol, frame: const Color(0xFF9AA5AE));
      rightWallRect(c, iso, x + 2.5, y + .6, y + 1.2, 30, 44, windowCol, frame: const Color(0xFF9AA5AE));
      hipRoof(c, iso, x + .5, y + .3, 2.0, 1.6, 52, 16, RoofStyle.tile);
      // potted plants
      for (final xx in [.7, 2.3]) {
        final p = iso.p(x + xx, y + 2.6);
        box(c, iso, x + xx - .1, y + 2.5, .2, .2, 0, 5, const Color(0xFFB0563A), const Color(0xFF9A4A32), const Color(0xFF833E2A));
        circle(c, p + const Offset(0, -10), 5, const Color(0xFF4E9A2E));
      }
    default: // biệt thự nhà vườn
      wallBox(c, iso, x + .2, y + .2, 2.6, 1.6, 0, 46, const Color(0xFFFFFBF0));
      wallBox(c, iso, x + 1.6, y + 1.8, 1.0, .7, 0, 30, const Color(0xFFFFFBF0));
      leftWallRect(c, iso, x + .5, y + 1.8, x + 1.3, 0, 18, const Color(0xFF8D5A3B), frame: const Color(0xFFD4AF37));
      leftWallRect(c, iso, x + .4, y + 1.8, x + 1.4, 25, 40, windowCol, frame: const Color(0xFFD4AF37));
      leftWallRect(c, iso, x + 1.8, y + 2.5, x + 2.4, 8, 22, windowCol, frame: const Color(0xFFD4AF37));
      rightWallRect(c, iso, x + 2.8, y + .5, y + 1.4, 22, 38, windowCol, frame: const Color(0xFFD4AF37));
      hipRoof(c, iso, x + .2, y + .2, 2.6, 1.6, 46, 22, RoofStyle.darkTile, curl: false);
      hipRoof(c, iso, x + 1.6, y + 1.8, 1.0, .7, 30, 12, RoofStyle.darkTile);
      for (final (xx, yy) in [(.35, 2.6), (2.85, .3)]) {
        circle(c, iso.p(x + xx, y + yy) + const Offset(0, -6), 6, const Color(0xFF66BB6A));
        circle(c, iso.p(x + xx, y + yy) + const Offset(-2, -9), 1.5, const Color(0xFFE91E63));
      }
  }
  // smoke from the kitchen
  for (var i = 0; i < 3; i++) {
    final k = (t * .3 + i / 3) % 1;
    final base = iso.p(x + .6, y + .4, level >= 3 ? 70 : 45);
    circle(c, base + Offset(math.sin(k * 5 + i) * 3, -k * 20), 2.5 + k * 4, Color.fromRGBO(235, 235, 235, .45 * (1 - k)));
  }
}

// ------------------------------------------------------------------ projects
void _project(Canvas c, Iso iso, String type, double x, double y, double t) {
  switch (type) {
    case 'gieng':
      final f = iso.p(x + .5, y + .5);
      oval(c, f, 18, 9, const Color(0xFFBDB6A6));
      c.drawRect(Rect.fromLTWH(f.dx - 12, f.dy - 14, 24, 14), Paint()..color = const Color(0xFF9E9585));
      oval(c, f, 12, 5, const Color(0xFF9E9585));
      for (var i = 0; i < 3; i++) {
        line(c, f + Offset(-12, -4.0 - i * 4), f + Offset(12, -4.0 - i * 4), const Color(0x33000000), .8);
      }
      oval(c, f + const Offset(0, -14), 12, 5, const Color(0xFFB2AA9A));
      oval(c, f + const Offset(0, -14), 9, 3.6, const Color(0xFF2F5F7A));
      line(c, f + const Offset(-11, -14), f + const Offset(-11, -34), woodDark, 2.2);
      line(c, f + const Offset(11, -14), f + const Offset(11, -34), woodDark, 2.2);
      line(c, f + const Offset(-13, -34), f + const Offset(13, -34), wood, 2.6);
      line(c, f + const Offset(0, -34), f + const Offset(0, -22), const Color(0xFF6D6D6D), .8);
      c.drawRect(Rect.fromLTWH(f.dx - 3, f.dy - 24, 6, 5), Paint()..color = const Color(0xFF8D6E63));
    case 'cong_lang':
      fillPoly(c, diamond(iso, x, y, 2, 1), const Color(0xFFCFCBC0));
      for (final xx in [.15, 1.65]) {
        wallBox(c, iso, x + xx, y + .3, .2, .4, 0, 40, const Color(0xFFEAE0C8));
      }
      box(c, iso, x + .05, y + .25, 1.9, .5, 40, 50, const Color(0xFFEAE0C8), const Color(0xFFE0D3B5), const Color(0xFFC9BC9E));
      hipRoof(c, iso, x + .05, y + .25, 1.9, .5, 50, 10, RoofStyle.tile, curl: true, over: .1);
      final sign = iso.p(x + 1, y + .75, 45);
      final tp = textPainter('LÀNG QUÊ', 6.5, color: const Color(0xFFB71C1C), weight: FontWeight.w900);
      c.save();
      c.translate(sign.dx, sign.dy);
      c.transform(Float64List.fromList([1, .5, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2 - 6));
      c.restore();
    case 'tram_bom':
      fillPoly(c, diamond(iso, x + .05, y + .05, 1.9, 1.9), const Color(0xFFBFC3C0));
      wallBox(c, iso, x + .3, y + .3, 1.1, 1.0, 0, 26, const Color(0xFFE6E8E3));
      box(c, iso, x + .25, y + .25, 1.2, 1.1, 26, 29, const Color(0xFFCFD2CC), const Color(0xFFBDC0BA), const Color(0xFFA7AAA4));
      leftWallRect(c, iso, x + .55, y + 1.3, x + .95, 0, 17, const Color(0xFF546E7A));
      final s = iso.p(x + .6, y + .7, 29);
      final tp = textPainter('TRẠM BƠM', 6, color: const Color(0xFF1565C0));
      tp.paint(c, s - Offset(tp.width / 2, 12));
      // pipes into a channel
      box(c, iso, x + 1.4, y + .55, .55, .18, 4, 9, const Color(0xFF1E88E5), const Color(0xFF1565C0), const Color(0xFF0D47A1));
      fillPoly(c, diamond(iso, x + 1.5, y + 1.0, .45, .95, 0), const Color(0xFF5DA9CF));
      final drip = (t * 2) % 1;
      circle(c, iso.p(x + 1.95, y + .65, 6 - drip * 6), 1.6, const Color(0xFFBBDEFB));
    case 'tram_dien':
      final f = iso.p(x + .5, y + .5);
      shadow(c, f, 12, 5);
      for (final dx in [-8.0, 8.0]) {
        line(c, f + Offset(dx, 0), f + Offset(dx * .6, -62), const Color(0xFF9E9E9E), 3);
      }
      line(c, f + const Offset(-14, -56), f + const Offset(14, -56), const Color(0xFF757575), 2);
      for (final dx in [-12.0, 0.0, 12.0]) {
        circle(c, f + Offset(dx, -58), 1.8, const Color(0xFFECEFF1));
      }
      c.drawRect(Rect.fromLTWH(f.dx - 9, f.dy - 40, 18, 14), Paint()..color = const Color(0xFF78909C));
      c.drawRect(Rect.fromLTWH(f.dx - 9, f.dy - 40, 18, 3), Paint()..color = const Color(0xFF546E7A));
      text(c, '⚡', f + const Offset(0, -32), 7, color: const Color(0xFFFFEB3B));
      // wires sagging off-map
      final wire = Path()
        ..moveTo(f.dx - 12, f.dy - 58)
        ..quadraticBezierTo(f.dx - 60, f.dy - 40, f.dx - 110, f.dy - 70);
      pathStroke(c, wire, const Color(0x99333333), .8);
    case 'truong':
      fillPoly(c, diamond(iso, x + .05, y + .05, 2.9, 1.9), const Color(0xFFD9CDB0));
      wallBox(c, iso, x + .2, y + .2, 2.6, 1.0, 0, 26, const Color(0xFFF6D25B));
      for (var i = 0; i < 4; i++) {
        leftWallRect(c, iso, x + .4 + i * .6, y + 1.2, x + .75 + i * .6, 7, 19, i == 1 ? doorCol : const Color(0xFF4FC3F7),
            frame: const Color(0xFFFFFFFF));
      }
      gableRoof(c, iso, x + .2, y + .2, 2.6, 1.0, 26, 12, RoofStyle.tile, gableWall: const Color(0xFFF6D25B));
      final sign = iso.p(x + 1.5, y + 1.2, 33);
      final tp = textPainter('TRƯỜNG MẦM NON', 5.5, color: const Color(0xFFB71C1C), weight: FontWeight.w900);
      c.save();
      c.translate(sign.dx, sign.dy);
      c.transform(Float64List.fromList([1, .5, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
      c.restore();
      // flag pole with red flag + yellow star
      final pole = iso.p(x + 2.6, y + 1.6);
      line(c, pole, pole - const Offset(0, 50), const Color(0xFFBDBDBD), 1.6);
      final wave = math.sin(t * 3) * 1.5;
      final flag = Path()
        ..moveTo(pole.dx, pole.dy - 50)
        ..quadraticBezierTo(pole.dx + 8, pole.dy - 50 + wave, pole.dx + 16, pole.dy - 49)
        ..lineTo(pole.dx + 16, pole.dy - 39)
        ..quadraticBezierTo(pole.dx + 8, pole.dy - 40 + wave, pole.dx, pole.dy - 40)
        ..close();
      pathFill(c, flag, const Color(0xFFDA251D));
      _star(c, pole + Offset(8, -45 + wave * .5), 2.8, const Color(0xFFFFEB3B));
      // swing set
      final sw = iso.p(x + .6, y + 1.65);
      line(c, sw + const Offset(-10, 0), sw + const Offset(-6, -18), const Color(0xFFE53935), 1.8);
      line(c, sw + const Offset(10, 0), sw + const Offset(6, -18), const Color(0xFFE53935), 1.8);
      line(c, sw + const Offset(-6, -18), sw + const Offset(6, -18), const Color(0xFFE53935), 1.8);
      final sx = math.sin(t * 2) * 3;
      line(c, sw + const Offset(0, -18), sw + Offset(sx, -5), const Color(0xFF555555), .8);
      c.drawRect(Rect.fromLTWH(sw.dx + sx - 3, sw.dy - 5, 6, 2), Paint()..color = const Color(0xFF1E88E5));
    case 'tram_y_te':
      fillPoly(c, diamond(iso, x + .05, y + .05, 1.9, 1.9), const Color(0xFFD7DCD5));
      wallBox(c, iso, x + .25, y + .25, 1.5, 1.2, 0, 28, const Color(0xFFF5F7F2));
      leftWallRect(c, iso, x + .7, y + 1.45, x + 1.2, 0, 18, const Color(0xFF80CBC4), frame: const Color(0xFF26A69A));
      rightWallRect(c, iso, x + 1.75, y + .5, y + 1.0, 10, 20, windowCol, frame: const Color(0xFF26A69A));
      hipRoof(c, iso, x + .25, y + .25, 1.5, 1.2, 28, 12, RoofStyle.tin);
      final s = iso.p(x + 1.0, y + 1.45, 24);
      c.drawRect(Rect.fromCenter(center: s, width: 10, height: 3.2), Paint()..color = const Color(0xFF2E7D32));
      c.drawRect(Rect.fromCenter(center: s, width: 3.2, height: 10), Paint()..color = const Color(0xFF2E7D32));
    case 'cho_que':
      fillPoly(c, diamond(iso, x + .05, y + .05, 2.9, 2.9), const Color(0xFFC9B48C));
      for (var i = 0; i < 2; i++) {
        for (var j = 0; j < 2; j++) {
          final sx = x + .3 + i * 1.35, sy = y + .3 + j * 1.35;
          for (final (dx, dy) in [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]) {
            final p = iso.p(sx + dx, sy + dy);
            line(c, p, p - const Offset(0, 18), woodDark, 2);
          }
          box(c, iso, sx + .1, sy + .2, .8, .6, 6, 9, const Color(0xFFB08455), wood, woodDark);
          final goods = [const Color(0xFFFFB300), const Color(0xFF66BB6A), const Color(0xFFE53935), const Color(0xFFF5DEB3)];
          for (var k = 0; k < 4; k++) {
            circle(c, iso.p(sx + .25 + k * .17, sy + .5, 11), 2.4, goods[(k + i + j) % 4]);
          }
          gableRoof(c, iso, sx, sy, 1, 1, 18, 9, j == 0 ? RoofStyle.tile : RoofStyle.thatch,
              alongX: i == 0, gableWall: const Color(0x00000000));
        }
      }
    case 'nha_van_hoa':
      fillPoly(c, diamond(iso, x + .05, y + .05, 2.9, 1.9), const Color(0xFFCFCBC0));
      wallBox(c, iso, x + .2, y + .2, 2.6, 1.1, 0, 30, const Color(0xFFFFF3D6));
      for (var i = 0; i < 6; i++) {
        final p = iso.p(x + .3 + i * .48, y + 1.55);
        line(c, p, p - const Offset(0, 30), const Color(0xFFFFFFFF), 3);
      }
      fillPoly(c, diamond(iso, x + .2, y + 1.3, 2.6, .3), const Color(0xFFE0D8C4));
      leftWallRect(c, iso, x + 1.2, y + 1.3, x + 1.8, 0, 20, doorCol);
      gableRoof(c, iso, x + .2, y + .2, 2.6, 1.4, 30, 14, RoofStyle.tile, gableWall: const Color(0xFFFFF3D6));
      final sign = iso.p(x + 1.5, y + 1.6, 36);
      final tp = textPainter('NHÀ VĂN HÓA', 6, color: const Color(0xFFFFEB3B), weight: FontWeight.w900);
      c.save();
      c.translate(sign.dx, sign.dy);
      c.transform(Float64List.fromList([1, .5, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: tp.width + 6, height: tp.height + 2), Paint()..color = const Color(0xFFC62828));
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
      c.restore();
    case 'dinh_lang':
      fillPoly(c, diamond(iso, x + .05, y + .05, 2.9, 2.9), const Color(0xFFBDB6A6));
      box(c, iso, x + .3, y + .3, 2.4, 1.8, 0, 6, const Color(0xFFD6CEBC), const Color(0xFFBDB6A6), const Color(0xFFA59E8E));
      wallBox(c, iso, x + .55, y + .5, 1.9, 1.3, 6, 30, const Color(0xFF8E3B2A));
      for (var i = 0; i < 6; i++) {
        final p = iso.p(x + .5 + i * .4, y + 2.0, 6);
        line(c, p, p - const Offset(0, 26), const Color(0xFF7A2E1F), 3);
      }
      hipRoof(c, iso, x + .3, y + .3, 2.4, 1.8, 30, 22, RoofStyle.darkTile, curl: true, over: .2);
      // incense smoke
      final pot = iso.p(x + 1.5, y + 2.55);
      oval(c, pot + const Offset(0, -4), 5, 4, const Color(0xFFB8860B));
      for (var i = 0; i < 2; i++) {
        final k = (t * .4 + i / 2) % 1;
        circle(c, pot + Offset(math.sin(k * 7) * 3, -10 - k * 18), 1.5 + k * 3, Color.fromRGBO(220, 220, 220, .5 * (1 - k)));
      }
  }
}

void _star(Canvas c, Offset p, double r, Color col) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r : r * .42;
    final q = p + Offset(math.cos(a) * rr, math.sin(a) * rr);
    if (i == 0) {
      path.moveTo(q.dx, q.dy);
    } else {
      path.lineTo(q.dx, q.dy);
    }
  }
  pathFill(c, path..close(), col);
}

// ------------------------------------------------------------------ deco & obstacles
void _deco(Canvas c, Iso iso, String type, double x, double y, Offset f, double t, int seed) {
  switch (type) {
    case 'rom_dong':
      shadow(c, f, 14, 6);
      final path = Path()
        ..moveTo(f.dx - 13, f.dy)
        ..quadraticBezierTo(f.dx - 14, f.dy - 20, f.dx, f.dy - 32)
        ..quadraticBezierTo(f.dx + 14, f.dy - 20, f.dx + 13, f.dy)
        ..close();
      pathFill(c, path, const Color(0xFFE0B654));
      for (var i = 0; i < 5; i++) {
        line(c, f + Offset(-11 + i * 1.5, -4.0 - i * 5), f + Offset(11 - i * 1.5, -4.0 - i * 5), const Color(0x55A0782A), 1);
      }
      line(c, f + const Offset(0, -32), f + const Offset(0, -40), woodDark, 1.8);
      oval(c, f + const Offset(0, -40), 3.5, 2, const Color(0xFF7B4B2A));
    case 'chum':
      shadow(c, f, 9, 3.5);
      oval(c, f + const Offset(0, -9), 8, 10, const Color(0xFF7B4B2A));
      oval(c, f + const Offset(-2.5, -11), 2, 5, const Color(0x33FFFFFF));
      oval(c, f + const Offset(0, -18), 6.5, 2.4, const Color(0xFF4E2E18));
      oval(c, f + const Offset(0, -19), 6, 2, const Color(0xFFC8A777));
    case 'bu_nhin':
      line(c, f, f + const Offset(0, -26), woodDark, 2);
      line(c, f + const Offset(-11, -18), f + const Offset(11, -18), woodDark, 2);
      fillPoly(c, [f + const Offset(-7, -20), f + const Offset(7, -20), f + const Offset(5, -8), f + const Offset(-5, -8)], const Color(0xFF5C6BC0));
      circle(c, f + const Offset(0, -25), 4, const Color(0xFFE6C987));
      // nón lá
      fillPoly(c, [f + const Offset(-9, -26), f + const Offset(9, -26), f + const Offset(0, -35)], const Color(0xFFF1E3B5));
      line(c, f + const Offset(-9, -26), f + const Offset(9, -26), const Color(0xFFC9B27A), 1);
      line(c, f + const Offset(-11, -18), f + Offset(-15, -14 + math.sin(t * 2) * 2), const Color(0xFFE0B654), 1.5);
    case 'hoa_dao':
      drawPeach(c, f, t);
    case 'tre':
      drawBamboo(c, f, .55, seed: seed, t: t);
    case 'cay_da':
      drawBanyan(c, f, t);
  }
}

void _obstacle(Canvas c, String type, Offset f, int seed) {
  switch (type) {
    case 'bui':
      drawBush(c, f);
    case 'da':
      shadow(c, f, 12, 4);
      final path = Path()
        ..moveTo(f.dx - 12, f.dy)
        ..lineTo(f.dx - 10, f.dy - 9)
        ..lineTo(f.dx - 2, f.dy - 14)
        ..lineTo(f.dx + 8, f.dy - 11)
        ..lineTo(f.dx + 12, f.dy - 2)
        ..lineTo(f.dx + 4, f.dy + 2)
        ..close();
      pathFill(c, path, const Color(0xFF9E9E9E));
      fillPoly(c, [f + const Offset(-10, -9), f + const Offset(-2, -14), f + const Offset(8, -11), f + const Offset(0, -7)], const Color(0xFFBDBDBD));
      oval(c, f + const Offset(6, -1), 3, 1.5, const Color(0xFF7CB342));
    case 'goc_cay':
      shadow(c, f, 10, 4);
      c.drawRect(Rect.fromLTWH(f.dx - 7, f.dy - 9, 14, 9), Paint()..color = const Color(0xFF7A5230));
      oval(c, f, 7, 3, const Color(0xFF7A5230));
      oval(c, f + const Offset(0, -9), 7, 3, const Color(0xFFD7B98A));
      ovalStroke(c, f + const Offset(0, -9), 4, 1.6, const Color(0xFFA6814F), .8);
      line(c, f + const Offset(-7, -1), f + const Offset(-12, 2), const Color(0xFF7A5230), 2);
  }
}
