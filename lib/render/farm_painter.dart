// Paints the whole farm: cached ground picture + animated objects.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/defs.dart';
import '../core/farm.dart';
import '../core/weather.dart';
import 'animals.dart';
import 'ground.dart';
import 'iso.dart';
import 'sprites.dart';
import 'structures.dart';

const worldMarginX = 320.0, worldTop = 230.0, worldBottom = 210.0;
const worldW = worldMarginX * 2 + mapSize * 2 * Iso.hw;
const worldH = worldTop + mapSize * 2 * Iso.hh + worldBottom;
const worldIso = Iso(Offset(worldMarginX + mapSize * Iso.hw, worldTop));

class FloatFx {
  final Fx fx;
  final double born;
  FloatFx(this.fx, this.born);
}

/// What the screen wants highlighted / previewed.
class ViewState {
  Obj? selected;
  String? ghostType;
  int ghostX = 0, ghostY = 0;
  Obj? moving;
  /// Visiting a neighbour: no "Mua đất" signs.
  bool visiting = false;
  /// Sprites each object was drawn with last frame (object id → where).
  final Map<int, List<SpriteHit>> drawn = {};
  final List<FloatFx> floats = [];
}

class GroundCache {
  ui.Picture? pic;
  int rev = -1;
}

double objHeight(Obj o) => switch (o.def.kind) {
      BKind.house => 90,
      BKind.factory => 58,
      BKind.storage => 60,
      BKind.project => 64,
      BKind.tree => 52,
      BKind.deco => o.type == 'cay_da' ? 80 : 40,
      BKind.obstacle => 16,
      BKind.pen => 28,
      _ => 12,
    };

/// The object's body is its footprint pushed straight up by [objHeight]
/// (a prism), slightly inset: a point hits it when some point below it,
/// within that height, lies on the footprint. Unlike a bounding box this
/// leaves the tiles beside and behind a building's roof tappable.
bool _bodyHit(Obj o, Offset s) {
  // (x, y, w, h) of the tall part on the grid, and its height in px
  final (bx, by, bw, bh, hgt) = switch (o.type) {
    // code-drawn: a small pump house on a wide concrete pad
    'tram_bom' => (o.x + .25, o.y + .25, 1.2, 1.1, 30.0),
    // code-drawn houses (the art ones are tested by their pixels)
    'nha' => switch (o.level) {
        0 => (o.x + .3, o.y + .3, 2.2, 1.3, 40.0),
        1 => (o.x + .3, o.y + .25, 2.3, 1.7, 42.0),
        2 => (o.x + .25, o.y + .25, 2.4, 1.6, 38.0),
        3 => (o.x + .5, o.y + .3, 2.0, 1.6, 68.0),
        _ => (o.x + .2, o.y + .2, 2.6, 1.6, 68.0),
      },
    _ => (o.x + .12, o.y + .12, o.w - .24, o.h - .24, objHeight(o)),
  };
  for (var h = 0.0; h <= hgt; h += 3) {
    final (gx, gy) = worldIso.toGrid(s + Offset(0, h));
    if (gx > bx && gx < bx + bw && gy > by && gy < by + bh) return true;
  }
  return false;
}

int depthOf(Obj o) => (o.x + o.w) + (o.y + o.h);

/// Frontmost object under a screen point (footprint or its tall body).
/// The icon of the "ready" bubble floating over [o], or null.
String? bubbleIcon(Farm farm, Obj o) {
  switch (o.def.kind) {
    case BKind.pen:
      if (farm.isReady(o)) return item(animalForPen(o.type)!.product).icon;
      if (o.end == 0 && o.count > 0) return '🍽️';
    case BKind.pond:
      if (o.crop != null && farm.isReady(o)) return item(fishes[o.crop]!.product).icon;
    case BKind.tree:
      if (farm.isReady(o)) return item(trees[o.type]!.product).icon;
    case BKind.factory:
      final n = farm.readyJobs(o);
      if (n > 0) return item(recipes[o.jobs.first.recipe]!.product).icon;
    default:
  }
  return null;
}

/// Centre of [o]'s bubble (without the bob).
Offset bubbleAt(Iso iso, Obj o) => iso.p(o.x + o.w / 2, o.y + o.h / 2, objHeight(o) + 10);

Obj? hitTest(Farm farm, Offset s, [ViewState? view]) {
  // Bubbles are drawn above everything, so a tap on one wins even when a
  // building stands in front of its owner.
  Obj? bub;
  var bubD = 20.0 * 20.0;
  for (final o in farm.objs) {
    if (bubbleIcon(farm, o) == null) continue;
    final d = (bubbleAt(worldIso, o) - s).distanceSquared;
    if (d < bubD) {
      bub = o;
      bubD = d;
    }
  }
  if (bub != null) return bub;
  final (gx, gy) = worldIso.toGrid(s);
  Obj? best;
  var bestDepth = -1;
  for (final o in farm.objs) {
    // its tile, or what is drawn above it: the sprite's real pixels when
    // it was drawn from art, else a box shaped like the code-drawn model
    final sprites = view?.drawn[o.id];
    var hit = o.contains(gx.floor(), gy.floor()) ||
        (sprites != null && sprites.isNotEmpty ? sprites.any((h) => Sprites.solidAt(h, s)) : _bodyHit(o, s));
    if (hit && depthOf(o) > bestDepth) {
      best = o;
      bestDepth = depthOf(o);
    }
  }
  return best;
}

class FarmPainter extends CustomPainter {
  final Farm farm;
  final ViewState view;
  final ValueNotifier<double> clock;
  final GroundCache cache;
  FarmPainter(this.farm, this.view, this.clock, this.cache) : super(repaint: clock);

  @override
  void paint(Canvas c, Size size) {
    final t = clock.value;
    final iso = worldIso;
    c.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF9FCB63));
    if (cache.rev != farm.rev || cache.pic == null) {
      final rec = ui.PictureRecorder();
      drawGround(Canvas(rec), iso, farm);
      cache.pic?.dispose();
      cache.pic = rec.endRecording();
      cache.rev = farm.rev;
    }
    c.drawPicture(cache.pic!);
    drawWaterAnim(c, iso, t);

    // selection footprint under the object
    final sel = view.selected;
    if (sel != null && view.moving == null) {
      final pulse = (math.sin(t * 5) + 1) / 2;
      strokePoly(c, diamond(iso, sel.x.toDouble(), sel.y.toDouble(), sel.w.toDouble(), sel.h.toDouble()),
          Color.fromRGBO(255, 235, 59, .6 + .4 * pulse), 2.5);
    }

    final list = farm.objs.where((o) => o != view.moving).toList()
      ..sort((a, b) {
        final d = depthOf(a).compareTo(depthOf(b));
        return d != 0 ? d : a.x.compareTo(b.x);
      });
    view.drawn.clear();
    for (final o in list) {
      Sprites.rec = view.drawn[o.id] = [];
      drawObj(c, iso, farm, o, t);
    }
    Sprites.rec = null;

    _ghost(c, iso, t);
    if (!view.visiting) _lotSigns(c, iso);
    _readyBubbles(c, iso, t, list);
    if (sel != null && view.moving == null) _progressBar(c, iso, sel);
    _egrets(c, iso, t);
    if (!view.visiting) _tutArrow(c, iso, t);
    _floats(c, iso, t);
    _weather(c, size, t);
  }

  /// Bouncing arrow over what the tutorial asks the player to tap.
  void _tutArrow(Canvas c, Iso iso, double t) {
    final o = farm.tutTarget;
    if (o == null) return;
    final bob = (math.sin(t * 5) + 1) * 5;
    final tip = iso.p(o.x + o.w / 2, o.y + o.h / 2, objHeight(o) + 8 + bob);
    final pts = [
      tip,
      tip + const Offset(-13, -14),
      tip + const Offset(-5, -14),
      tip + const Offset(-5, -30),
      tip + const Offset(5, -30),
      tip + const Offset(5, -14),
      tip + const Offset(13, -14),
    ];
    fillPoly(c, [for (final p in pts) p + const Offset(1.5, 2)], const Color(0x55000000));
    fillPoly(c, pts, const Color(0xFFFFD54F));
    strokePoly(c, pts, const Color(0xFFE65100), 2);
  }

  /// Rain streaks, or a warm haze in a dry spell (the same for everyone).
  void _weather(Canvas c, Size size, double t) {
    switch (weatherAt(farm.now())) {
      case Weather.rain:
        c.drawRect(Offset.zero & size, Paint()..color = const Color(0x1A33506A));
        final p = Paint()
          ..color = const Color(0x66E3F2FD)
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 320; i++) {
          final x0 = (i * 97.31) % size.width;
          final y = (i * 53.17 + t * (380 + (i % 5) * 40)) % size.height;
          final x = (x0 - (y * .18)) % size.width;
          c.drawLine(Offset(x, y), Offset(x - 3, y + 13), p);
        }
      case Weather.drought:
        c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 160, 40, .10 + .02 * math.sin(t * 1.5)));
      case Weather.sunny:
    }
  }

  void _ghost(Canvas c, Iso iso, double t) {
    final type = view.ghostType ?? view.moving?.type;
    if (type == null) return;
    final d = bdef(type);
    final gx = view.ghostX, gy = view.ghostY;
    final ok = farm.canPlace(type, gx, gy, ignore: view.moving?.id);
    fillPoly(c, diamond(iso, gx.toDouble(), gy.toDouble(), d.w.toDouble(), d.h.toDouble()),
        ok ? const Color(0x6633DD55) : const Color(0x77EE3333));
    c.saveLayer(null, Paint()..color = const Color(0xC8FFFFFF));
    final o = view.moving ?? (Obj(-1, type, gx, gy)..level = 0);
    final ox = o.x, oy = o.y;
    o.x = gx;
    o.y = gy;
    if (d.kind == BKind.pen && view.moving == null) o.count = 2;
    drawObj(c, iso, farm, o, t);
    o.x = ox;
    o.y = oy;
    if (view.moving != null) {
      // keep real coords until confirmed
    }
    c.restore();
    strokePoly(c, diamond(iso, gx.toDouble(), gy.toDouble(), d.w.toDouble(), d.h.toDouble()),
        ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828), 2);
  }

  void _lotSigns(Canvas c, Iso iso) {
    for (var lot = 0; lot < lotsPerSide * lotsPerSide; lot++) {
      if (farm.lots.contains(lot) || !farm.lotAdjacent(lot)) continue;
      final lx = (lot % lotsPerSide) * lotSize, ly = (lot ~/ lotsPerSide) * lotSize;
      final cy = ly == 0 ? 4.0 : ly + lotSize / 2;
      final f = iso.p(lx + lotSize / 2, cy);
      line(c, f, f - const Offset(0, 22), woodDark, 2.5);
      final r = Rect.fromCenter(center: f - const Offset(0, 30), width: 62, height: 24);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFFB98A55));
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()
            ..color = woodDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      final lvl = farm.nextLotLevel;
      final label = farm.level < lvl ? '🔒 Cấp $lvl' : '${fmtNum(farm.nextLotPrice)} xu';
      text(c, 'MUA ĐẤT', r.center - const Offset(0, 5), 7, color: const Color(0xFFFFF3D6), weight: FontWeight.w900);
      text(c, label, r.center + const Offset(0, 5.5), 7.5, color: const Color(0xFFFFFFFF), weight: FontWeight.w800);
    }
  }

  void _readyBubbles(Canvas c, Iso iso, double t, List<Obj> list) {
    for (final o in list) {
      final icon = bubbleIcon(farm, o);
      if (icon == null) continue;
      final bob = math.sin(t * 3 + o.id) * 3;
      final at = bubbleAt(iso, o) - Offset(0, bob);
      c.drawCircle(at + const Offset(0, 1.5), 13, Paint()..color = const Color(0x33000000));
      c.drawCircle(at, 13, Paint()..color = const Color(0xFFFFFDF5));
      c.drawCircle(at, 13,
          Paint()
            ..color = const Color(0xFF8BC34A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      fillPoly(c, [at + const Offset(-4, 11), at + const Offset(4, 11), at + const Offset(0, 17)], const Color(0xFFFFFDF5));
      text(c, icon, at, 14);
    }
  }

  void _progressBar(Canvas c, Iso iso, Obj o) {
    int end = o.end, start = o.start;
    if (o.def.kind == BKind.factory) {
      if (o.jobs.isEmpty) return;
      final now = farm.now();
      final j = o.jobs.firstWhere((j) => j.end > now, orElse: () => o.jobs.last);
      final i = o.jobs.indexOf(j);
      end = j.end;
      start = i == 0 ? end - farm.recipeMs(recipes[j.recipe]!) : o.jobs[i - 1].end;
    }
    if (end == 0) return;
    final now = farm.now();
    if (now >= end) return;
    final p = ((now - start) / (end - start)).clamp(0.0, 1.0);
    final at = iso.p(o.x + o.w / 2, o.y + o.h / 2, objHeight(o) + 14);
    final r = Rect.fromCenter(center: at, width: 64, height: 18);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(9)), Paint()..color = const Color(0xDD3E2C17));
    final inner = Rect.fromLTWH(r.left + 3, r.top + 3, (r.width - 6) * p, r.height - 6);
    c.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(6)), Paint()..color = const Color(0xFF8BC34A));
    text(c, fmtTime(end - now), r.center, 8.5, color: const Color(0xFFFFFFFF), weight: FontWeight.w800);
  }

  void _egrets(Canvas c, Iso iso, double t) {
    for (var i = 0; i < 3; i++) {
      final cyc = (t / 38 + i * .13) % 1;
      if (cyc > .55) continue;
      final k = cyc / .55;
      final p = Offset(-60 + k * (worldW + 120), worldTop + 120 + i * 18 + math.sin(k * 6 + i) * 10);
      drawEgret(c, p + Offset(i * 26.0, 0), t, i.toDouble());
    }
  }

  void _floats(Canvas c, Iso iso, double t) {
    view.floats.removeWhere((f) => t - f.born > 1.6);
    for (final f in view.floats) {
      final k = (t - f.born) / 1.6;
      final at = iso.p(f.fx.x, f.fx.y, 40 + k * 40);
      final a = (1 - k).clamp(0.0, 1.0);
      final tp = textPainter(f.fx.text, 15, color: const Color(0xFFFFFFFF), weight: FontWeight.w900);
      final r = Rect.fromCenter(center: at, width: tp.width + 14, height: tp.height + 6);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = Color.fromRGBO(62, 44, 23, .75 * a));
      c.saveLayer(r.inflate(4), Paint()..color = Color.fromRGBO(255, 255, 255, a));
      tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant FarmPainter old) => true;
}

/// Small static preview of a building for shop cards.
class ObjPreviewPainter extends CustomPainter {
  final String type;
  final Farm farm;
  ObjPreviewPainter(this.type, this.farm);

  @override
  void paint(Canvas c, Size size) {
    final d = bdef(type);
    final w = math.max(d.w, 1), h = math.max(d.h, 1);
    final span = (w + h) * Iso.hw; // footprint width in px
    final height = (w + h) * Iso.hh + objHeight(Obj(-1, type, 0, 0)) + 10;
    final s = math.min(size.width / span, size.height / height) * .92;
    c.save();
    c.translate(size.width / 2, size.height - 4);
    c.scale(s);
    final iso = Iso(Offset(-(w - h) * Iso.hw / 2, -(w + h) * Iso.hh));
    if (type == 'duong_be_tong') {
      for (var i = 0; i < 3; i++) {
        fillPoly(c, diamond(iso, 0, i - 1.0, 1, 1), concrete);
      }
    } else {
      fillPoly(c, diamond(iso, 0, 0, w.toDouble(), h.toDouble()), const Color(0x558CC152));
      final o = Obj(-1, type, 0, 0);
      if (d.kind == BKind.pen) o.count = 3;
      if (d.kind == BKind.tree) {
        o.start = 0;
        o.end = 1;
      }
      drawObj(c, iso, farm, o, 0);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant ObjPreviewPainter old) => old.type != type;
}
