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

class Sprites {
  static final Map<String, ui.Image> _img = {};
  static final Map<String, SpriteTweak> _tweak = {};
  static final _paint = Paint()..filterQuality = FilterQuality.medium;

  static bool has(String key) => _img.containsKey(key);
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
          _img[f.substring('assets/sprites/'.length, f.length - 4)] = frame.image;
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
