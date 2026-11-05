// Optional image sprites (assets/sprites/<key>.png, made from AI art by
// tool/sprites.dart). Every draw call falls back to the code-drawn art when
// a sprite is missing, so art can be swapped in one piece at a time.
//
// A sprite is drawn with its width matching the object's footprint
// diamond ((w + h) half-tiles), centred on the footprint and with its
// bottom edge on the footprint's front corner. assets/sprites/tweaks.json
// can adjust each key: {"nha_0": {"scale": 1.1, "dy": 4, "flip": true}}.

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'iso.dart';

class SpriteTweak {
  final double scale, dx, dy;
  final bool flip;
  const SpriteTweak({this.scale = 1, this.dx = 0, this.dy = 0, this.flip = false});
  factory SpriteTweak.fromJson(Map<String, dynamic> j) => SpriteTweak(
        scale: (j['scale'] as num?)?.toDouble() ?? 1,
        dx: (j['dx'] as num?)?.toDouble() ?? 0,
        dy: (j['dy'] as num?)?.toDouble() ?? 0,
        flip: j['flip'] == true,
      );
}

/// Where a sprite was drawn last frame (for pixel-exact tap tests).
class SpriteHit {
  final String key;
  final Rect rect;
  final bool flip;
  const SpriteHit(this.key, this.rect, this.flip);
}

/// Which pixels of a sprite are solid, at 1/[_maskStep] resolution.
class _Mask {
  final int w, h;
  final Uint8List solid;
  const _Mask(this.w, this.h, this.solid);
}

const _maskStep = 4;

class Sprites {
  static final Map<String, ui.Image> _img = {};
  static final Map<String, _Mask> _mask = {};

  /// While set, every sprite drawn is recorded here (the farm painter sets
  /// it around each object so taps can test the real drawn pixels).
  static List<SpriteHit>? rec;
  static final Map<String, SpriteTweak> _tweak = {};
  static final _paint = Paint()..filterQuality = FilterQuality.medium;

  static bool has(String key) => _img.containsKey(key);
  static ui.Image? image(String key) => _img[key];
  static int get count => _img.length;

  /// Loads every sprite in the asset bundle. Never throws.
  static Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final files = manifest.listAssets().where((a) => a.startsWith('assets/sprites/') && a.endsWith('.png'));
      await Future.wait(files.map((f) async {
        try {
          final data = await rootBundle.load(f);
          final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
          final frame = await codec.getNextFrame();
          final key = f.substring('assets/sprites/'.length, f.length - 4);
          _img[key] = frame.image;
          final m = await _maskOf(frame.image);
          if (m != null) _mask[key] = m;
        } catch (_) {}
      }));
    } catch (_) {}
    try {
      final j = jsonDecode(await rootBundle.loadString('assets/sprites/tweaks.json')) as Map<String, dynamic>;
      j.forEach((k, v) {
        if (v is Map<String, dynamic>) _tweak[k] = SpriteTweak.fromJson(v);
      });
    } catch (_) {}
  }

  static Future<_Mask?> _maskOf(ui.Image img) async {
    try {
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null) return null;
      final w = (img.width / _maskStep).ceil(), h = (img.height / _maskStep).ceil();
      final solid = Uint8List(w * h);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final px = x * _maskStep, py = y * _maskStep;
          if (px >= img.width || py >= img.height) continue;
          solid[y * w + x] = bd.getUint8((py * img.width + px) * 4 + 3) > 60 ? 1 : 0;
        }
      }
      return _Mask(w, h, solid);
    } catch (_) {
      return null;
    }
  }

  /// Is the drawn sprite [h] solid at [p] (a pixel or so of slack)?
  /// Unknown masks count as solid inside the rectangle.
  static bool solidAt(SpriteHit h, Offset p) {
    if (!h.rect.contains(p)) return false;
    final m = _mask[h.key];
    if (m == null) return true;
    var u = (p.dx - h.rect.left) / h.rect.width;
    if (h.flip) u = 1 - u;
    final v = (p.dy - h.rect.top) / h.rect.height;
    final cx = (u * m.w).floor(), cy = (v * m.h).floor();
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final x = cx + dx, y = cy + dy;
        if (x >= 0 && y >= 0 && x < m.w && y < m.h && m.solid[y * m.w + x] != 0) return true;
      }
    }
    return false;
  }

  /// Draws [key] standing on footprint (x, y, w, h). False when missing.
  static bool foot(Canvas c, Iso iso, String key, double x, double y, double w, double h,
      {double z = 0, double scale = 1}) {
    if (!has(key)) return false;
    final center = iso.p(x + w / 2, y + h / 2, z);
    final front = iso.p(x + w, y + h, z);
    at(c, key, Offset(center.dx, front.dy), (w + h) * Iso.hw * scale);
    return true;
  }

  /// Draws [key] with its bottom-centre at [bottom], [width] wide.
  static bool at(Canvas c, String key, Offset bottom, double width, {bool flipX = false}) {
    final img = _img[key];
    if (img == null) return false;
    final tw = _tweak[key] ?? const SpriteTweak();
    final w = width * tw.scale;
    final h = w * img.height / img.width;
    final flip = flipX != tw.flip;
    final b = bottom + Offset(tw.dx, tw.dy);
    final dst = Rect.fromLTWH(b.dx - w / 2, b.dy - h, w, h);
    rec?.add(SpriteHit(key, dst, flip));
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    if (flip) {
      c.save();
      c.translate(b.dx, 0);
      c.scale(-1, 1);
      c.translate(-b.dx, 0);
      c.drawImageRect(img, src, dst, _paint);
      c.restore();
    } else {
      c.drawImageRect(img, src, dst, _paint);
    }
    return true;
  }
}
