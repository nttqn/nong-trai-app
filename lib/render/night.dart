// Night over the farm: a moonlit blue tint, warm lamplight from houses,
// workshops and lanterns, stars and the moon mirrored in the river and the
// lake, fireflies by the bamboo; and a starry sky across the top of the
// screen with the moon in its real lunar phase.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/daynight.dart';
import '../core/defs.dart';
import '../core/farm.dart';
import '../core/weather.dart';
import 'ground.dart';
import 'iso.dart';

const _nightBlue = Color(0xFF26346A);

/// Darkens what is drawn under it (multiply), less on bright moonlit nights.
void drawNightTint(Canvas c, Rect area, double n, double lit) {
  final k = tintOf(n) * (.8 - .14 * lit); // keep in step with nightShade
  c.drawRect(
      area,
      Paint()
        ..color = Color.lerp(const Color(0xFFFFFFFF), _nightBlue, k)!
        ..blendMode = BlendMode.multiply);
}

/// A soft round glow (added light), squashed to lie on the ground when
/// [flat] < 1.
void _glow(Canvas c, Offset at, double r, Color col, double a, {double flat = 1}) {
  if (a <= 0) return;
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(1, flat);
  c.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          col.withValues(alpha: a),
          col.withValues(alpha: a * .35),
          col.withValues(alpha: 0),
        ], stops: const [0, .45, 1])
            .createShader(Rect.fromCircle(center: Offset.zero, radius: r)));
  c.restore();
}

/// Lamplight: houses and their windows, busy workshops, festival lanterns.
void drawNightLights(Canvas c, Iso iso, Farm farm, Iterable<Obj> shown, double t, double n) {
  // with the village transformer station the houses have electric light
  final electric = farm.objs.any((o) => o.type == 'tram_dien');
  final lamp = electric ? const Color(0xFFFFF1C9) : const Color(0xFFFFB74D);
  final now = farm.now();
  for (final o in shown) {
    final x = o.x.toDouble(), y = o.y.toDouble();
    final mid = iso.p(x + o.w / 2, y + o.h / 2);
    final flick = .9 + .1 * math.sin(t * 7.3 + o.id) * math.sin(t * 3.1 + o.id * 2);
    switch (o.def.kind) {
      case BKind.house:
        // lamplight spilling out of the front door onto the yard, and a
        // glow around the windows
        _glow(c, iso.p(x + o.w * .62, y + o.h + .3), 70, lamp, .38 * n * (electric ? 1 : flick), flat: .5);
        _glow(c, iso.p(x + o.w * .55, y + o.h * .75, 22), 46, lamp, .30 * n * (electric ? 1 : flick));
      case BKind.factory:
        if (o.jobs.isNotEmpty && now < o.jobs.last.end) {
          _glow(c, iso.p(x + 1, y + 1.8), 55, const Color(0xFFFF9E40), .34 * n * flick, flat: .55);
          _glow(c, iso.p(x + 1, y + 1.4, 20), 34, const Color(0xFFFFB060), .26 * n * flick);
        }
      case BKind.project when const {'dinh_lang', 'nha_van_hoa', 'tram_y_te', 'truong', 'cho_que'}.contains(o.type):
        _glow(c, iso.p(x + o.w * .6, y + o.h + .2), 60, lamp, .26 * n, flat: .5);
      case BKind.deco:
        switch (o.type) {
          case 'den_long':
            _glow(c, mid - const Offset(0, 34), 44, const Color(0xFFFF5A36), .55 * n * flick);
            _glow(c, mid, 50, const Color(0xFFFF7043), .30 * n, flat: .5);
          case 'den_ong_sao':
            _glow(c, mid - const Offset(0, 36), 40, const Color(0xFFFFD54F), .55 * n * flick);
            _glow(c, mid, 46, const Color(0xFFFFC107), .28 * n, flat: .5);
          case 'cay_neu':
            _glow(c, mid - const Offset(0, 60), 26, const Color(0xFFFFE082), .35 * n * flick);
        }
      default:
    }
  }
  // street lamps along the village road once there is electricity
  if (electric) {
    for (var y = 3; y < mapSize; y += 5) {
      final f = iso.p(Farm.roadX + .88, y + .5);
      _glow(c, f - const Offset(0, 26), 22, const Color(0xFFFFF6D8), .5 * n);
      _glow(c, f, 40, const Color(0xFFFFF1C9), .26 * n, flat: .5);
    }
  }
}

/// Lamp posts beside the village road (drawn before the night tint, so
/// they stand there by day too) once the transformer station is built.
void drawStreetLamps(Canvas c, Iso iso, Farm farm, double n) {
  if (!farm.objs.any((o) => o.type == 'tram_dien')) return;
  for (var y = 3; y < mapSize; y += 5) {
    final f = iso.p(Farm.roadX + .88, y + .5);
    shadow(c, f, 3, 1.5);
    line(c, f, f - const Offset(0, 25), const Color(0xFF8D9399), 1.8);
    line(c, f - const Offset(0, 25), f - const Offset(5, 27), const Color(0xFF8D9399), 1.4);
    oval(c, f - const Offset(5, 26), 2.6, 1.5,
        Color.lerp(const Color(0xFFDADDE0), const Color(0xFFFFF8DC), n)!);
  }
}

List<(int, int)>? _lake;

/// Stars twinkling on the river and the lake, and the moon's glitter on
/// the lake.
void drawWaterSky(Canvas c, Iso iso, double t, double n, double lit) {
  _lake ??= [
    for (var x = 0; x < mapSize; x++)
      for (var y = 0; y < mapSize; y++)
        if (Farm.isLake(x, y)) (x, y)
  ];
  final star = Paint()..blendMode = BlendMode.plus;
  void dot(Offset p, double a, double r) {
    if (a <= 0) return;
    star.color = Color.fromRGBO(255, 250, 225, a);
    c.drawCircle(p, r, star);
  }

  // river
  for (var i = 0; i < 70; i++) {
    final x = -6 + hash2(i, 41) * (mapSize + 12);
    final y = -.85 + hash2(i, 42) * 2.5;
    final tw = (math.sin(t * (1.5 + hash2(i, 43) * 2) + i) + 1) / 2;
    dot(iso.p(x, y), n * (.25 + .55 * tw), .8 + hash2(i, 44) * .7);
  }
  final lake = _lake!;
  if (lake.isEmpty) return;
  for (var i = 0; i < 40; i++) {
    final (lx, ly) = lake[(hash2(i, 51) * lake.length).floor() % lake.length];
    final tw = (math.sin(t * (1.3 + hash2(i, 53) * 2) + i * 1.7) + 1) / 2;
    dot(iso.p(lx + hash2(i, 54), ly + hash2(i, 55)), n * (.2 + .5 * tw), .7 + hash2(i, 56) * .7);
  }
  // the moon's path of light across the lake: rippling short strokes
  if (lit < .03) return;
  // centre of the lake on screen (the painted lake fills the tiles' box)
  var box = Rect.fromCircle(center: iso.p(lake.first.$1 + .5, lake.first.$2 + .5), radius: 0);
  for (final (x, y) in lake) {
    box = box.expandToInclude(Rect.fromCircle(center: iso.p(x + .5, y + .5), radius: 0));
  }
  final ctr = box.center + const Offset(10, -6);
  _glow(c, ctr, 46, const Color(0xFFFFF4CF), .16 * n * lit, flat: .45);
  final p = Paint()
    ..blendMode = BlendMode.plus
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 7; i++) {
    final dy = -14 + i * 4.6;
    final w = (4 + 7 * lit) * (1 - (dy.abs() / 20)) * (.6 + .4 * math.sin(t * 2.2 + i * 1.9));
    final dx = math.sin(t * 1.4 + i * 2.3) * 2.5;
    p
      ..color = Color.fromRGBO(255, 246, 210, n * (.12 + .22 * lit) * (.6 + .4 * math.sin(t * 1.7 + i)))
      ..strokeWidth = 1.3;
    c.drawLine(ctr + Offset(dx - w, dy), ctr + Offset(dx + w, dy), p);
  }
}

/// Fireflies blinking around bamboo, trees and the lake shore.
void drawFireflies(Canvas c, Iso iso, Iterable<Obj> shown, double t, double n) {
  final homes = [
    for (final o in shown)
      if (o.def.kind == BKind.tree || const {'tre', 'cay_da', 'hoa_dao', 'bu_nhin', 'chum'}.contains(o.type)) o
  ];
  final p = Paint()..blendMode = BlendMode.plus;
  var count = 0;
  for (final o in homes) {
    for (var i = 0; i < 3 && count < 60; i++, count++) {
      final s = o.id * 7 + i;
      final ctr = iso.p(o.x + o.w / 2, o.y + o.h / 2, 10 + hash2(s, 61) * 22);
      final a = t * (.35 + hash2(s, 62) * .3) + hash2(s, 63) * 6;
      final pos = ctr + Offset(math.cos(a) * (14 + hash2(s, 64) * 16), math.sin(a * 1.7) * 8 + math.sin(t * .9 + s) * 4);
      final blink = math.max(0.0, math.sin(t * (1.6 + hash2(s, 65)) + s * 2.1));
      if (blink <= 0) continue;
      final k = n * blink;
      p.color = Color.fromRGBO(200, 255, 120, .22 * k);
      c.drawCircle(pos, 5, p);
      p.color = Color.fromRGBO(240, 255, 190, .9 * k);
      c.drawCircle(pos, 1.3, p);
    }
  }
}

/// The night sky over the top of the screen (screen space, under the HUD).
class SkyPainter extends CustomPainter {
  final Farm farm;
  final ValueNotifier<double> clock;

  /// Where the moon is drawn (screen point).
  final Offset moonAt;
  SkyPainter(this.farm, this.clock, this.moonAt) : super(repaint: clock);

  static const moonR = 17.0;

  @override
  void paint(Canvas c, Size size) {
    final now = farm.now();
    // the moon and stars at full strength; only the dark band is softened.
    // With the night look off only the moon stays (the full-moon gift).
    final n = nightAt(now);
    if (n < .01) return;
    final off = nightLook <= 0;
    final shade = off ? 0.0 : glowOf(n);
    final t = clock.value;
    final rain = weatherAt(now) == Weather.rain;
    final day = moonDayAt(now);
    final (lit, waxing) = moonPhase(day);
    final h = math.max(moonAt.dy + 90, size.height * .34);
    final band = Rect.fromLTWH(0, 0, size.width, h);
    c.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            Color.fromRGBO(10, 16, 44, .92 * shade),
            Color.fromRGBO(22, 32, 76, .6 * shade),
            Color.fromRGBO(30, 44, 96, 0),
          ], stops: const [0, .55, 1])
              .createShader(band));
    if (rain) {
      // clouds hide the sky; the moon is a smudge of light behind them
      if (lit > .1) _halo(c, moonAt, 46, .12 * n * lit);
      return;
    }
    // stars, thicker towards the top and on dark (moonless) nights
    final p = Paint();
    final stars = off ? 0 : (90 - 35 * lit).round();
    for (var i = 0; i < stars; i++) {
      final y = math.pow(hash2(i, 71), 1.6) * h * .9;
      final x = hash2(i, 72) * size.width;
      final fade = 1 - y / h;
      final tw = (math.sin(t * (1 + hash2(i, 73) * 2.5) + i * 1.3) + 1) / 2;
      final big = hash2(i, 74) > .88;
      final a = n * fade * (.35 + .65 * tw) * (big ? 1 : .8);
      p.color = Color.fromRGBO(255, 252, 235, a);
      c.drawCircle(Offset(x, y), big ? 1.5 : .9, p);
      if (big && tw > .75) {
        // a little sparkle cross on the brightest ones
        p.strokeWidth = .7;
        final r = 3.5 * (tw - .75) * 4;
        c.drawLine(Offset(x - r, y), Offset(x + r, y), p);
        c.drawLine(Offset(x, y - r), Offset(x, y + r), p);
      }
    }
    if (!off) _shootingStar(c, size, h, t, n);
    if (lit >= .03) _moon(c, moonAt, lit, waxing, n);
    if (farm.moonGiftReady) _giftSparkle(c, moonAt, t, n);
  }

  void _halo(Canvas c, Offset at, double r, double a) {
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.fromRGBO(255, 244, 200, a),
            Color.fromRGBO(255, 244, 200, 0),
          ]).createShader(Rect.fromCircle(center: at, radius: r)));
  }

  /// Now and then a shooting star streaks across.
  void _shootingStar(Canvas c, Size size, double h, double t, double n) {
    const period = 19.0, dur = .9;
    final slot = (t / period).floor();
    final u = t - slot * period;
    if (u > dur || hash2(slot, 81) < .35) return;
    final k = u / dur;
    final start = Offset(size.width * (.15 + .7 * hash2(slot, 82)), h * (.08 + .3 * hash2(slot, 83)));
    final dir = Offset(hash2(slot, 84) < .5 ? -1 : 1, .45);
    final head = start + dir * (140 * k);
    final tail = head - dir * (40 * (1 - k * .5));
    c.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(colors: [
            const Color(0x00FFFFFF),
            Color.fromRGBO(255, 255, 240, n * (1 - k)),
          ]).createShader(Rect.fromPoints(tail, head)));
  }

  void _moon(Canvas c, Offset at, double lit, bool waxing, double n) {
    const r = moonR;
    _halo(c, at, r * (2.6 + 1.6 * lit), .35 * n * (.3 + .7 * lit));
    final disc = Rect.fromCircle(center: at, radius: r);
    // the unlit part, faintly (earthshine)
    c.drawCircle(at, r, Paint()..color = Color.fromRGBO(60, 70, 110, .55 * n));
    // lit part: half the disc on the lit side, plus or minus the ellipse
    // of the terminator
    final half = Path()
      ..addArc(disc, waxing ? -math.pi / 2 : math.pi / 2, math.pi)
      ..close();
    final rx = r * (2 * lit - 1).abs();
    final ell = Path()..addOval(Rect.fromCenter(center: at, width: rx * 2, height: r * 2));
    final shape = Path.combine(lit >= .5 ? PathOperation.union : PathOperation.difference, half, ell);
    c.save();
    c.clipPath(shape);
    c.drawCircle(at, r, Paint()..color = Color.fromRGBO(255, 246, 214, n));
    // maria (the dark "chú Cuội dưới gốc cây đa" patches)
    for (final (dx, dy, rr) in const [(-5.0, -4.0, 4.6), (4.0, 3.0, 3.6), (-2.0, 7.0, 2.6), (6.0, -6.0, 2.2)]) {
      c.drawCircle(at + Offset(dx, dy), rr, Paint()..color = Color.fromRGBO(214, 200, 160, .55 * n));
    }
    c.restore();
  }

  /// A full-moon gift is waiting: a pulsing ring and sparkles round the moon.
  void _giftSparkle(Canvas c, Offset at, double t, double n) {
    final pulse = (math.sin(t * 3) + 1) / 2;
    c.drawCircle(
        at,
        moonR + 6 + pulse * 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Color.fromRGBO(255, 224, 130, n * (.4 + .5 * pulse)));
    final p = Paint()..color = Color.fromRGBO(255, 248, 210, n);
    for (var i = 0; i < 4; i++) {
      final a = t * .8 + i * math.pi / 2;
      final s = at + Offset(math.cos(a), math.sin(a)) * (moonR + 14);
      final r = 2.2 + 1.6 * math.max(0, math.sin(t * 4 + i * 1.7));
      c.drawLine(s - Offset(r, 0), s + Offset(r, 0), p..strokeWidth = 1.2);
      c.drawLine(s - Offset(0, r), s + Offset(0, r), p);
    }
  }

  /// Whether the moon is up on screen (at night, not behind rain clouds).
  static bool visible(Farm farm) {
    final now = farm.now();
    return nightAt(now) > .3 && weatherAt(now) != Weather.rain;
  }

  @override
  bool shouldRepaint(covariant SkyPainter old) => old.moonAt != moonAt;
}

/// Night strength for the painter (0 by day, and always 0 with the night
/// look turned off).
double nightOf(Farm farm) => nightLook <= 0 ? 0 : nightAt(farm.now());

/// The tint is scaled by the player setting: lights, stars and glows keep
/// more of their strength so a soft night still reads as night.
double tintOf(double n) => n * nightLook;

/// Lights and the sky on a softer night.
double glowOf(double n) => n * (.35 + .65 * nightLook);

/// Moonlight strength (lit fraction) for tonight.
double moonLitOf(Farm farm) => moonPhase(moonDayAt(farm.now())).$1;


/// [base] as it looks under tonight's tint (for plain backgrounds).
Color nightShade(Color base, Farm farm) {
  final n = nightOf(farm);
  if (n < .01) return base;
  final k = Color.lerp(const Color(0xFFFFFFFF), _nightBlue, tintOf(n) * (.8 - .14 * moonLitOf(farm)))!;
  return Color.from(alpha: 1, red: base.r * k.r, green: base.g * k.g, blue: base.b * k.b);
}
