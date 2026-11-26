// Khoe với bạn bè: a picture of the farm as it is on screen, framed with
// what happened (lên cấp, thành tựu) and the game's name, handed to the
// system share sheet with a short text and the store link. No reward for
// sharing (store rules: no paying for social actions).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import 'analytics.dart';
import 'update.dart';

class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  /// Wraps the map (not the HUD): what the card shows.
  final GlobalKey shotKey = GlobalKey();

  static const _playUrl = 'https://play.google.com/store/apps/details?id=com.trungsmail.nongtrai';

  /// The store a friend of this player most likely uses: the same one.
  /// iOS-visible text never names the other store (App Store 2.3.10).
  static String get storeUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return UpdateService.instance.appStoreUrl ??
          'https://apps.apple.com/app/id6838682662';
    }
    return _playUrl;
  }

  bool _busy = false;

  /// [kind] for analytics (level, ach, invite). [origin] anchors the iPad
  /// popover: the widget that was tapped.
  Future<void> share({
    required String kind,
    required String headline,
    required String detail,
    required String text,
    BuildContext? origin,
  }) async {
    if (_busy) return;
    _busy = true;
    Rect? at;
    final box = origin?.findRenderObject();
    if (box is RenderBox && box.hasSize) at = box.localToGlobal(Offset.zero) & box.size;
    try {
      final shot = await _shot();
      final png = await _card(shot, headline, detail);
      Analytics.instance.log('share', {'kind': kind});
      await SharePlus.instance.share(ShareParams(
        text: '$text\n$storeUrl',
        files: [if (png != null) XFile.fromData(png, mimeType: 'image/png', name: 'mua_lua_chin.png')],
        sharePositionOrigin: at,
      ));
    } catch (e) {
      debugPrint('share: $e');
    } finally {
      _busy = false;
    }
  }

  Future<ui.Image?> _shot() async {
    try {
      final b = shotKey.currentContext?.findRenderObject();
      if (b is! RenderRepaintBoundary || !b.hasSize) return null;
      // about 1080 px across, whatever the phone
      return await b.toImage(pixelRatio: (1080 / b.size.width).clamp(1.0, 3.0));
    } catch (e) {
      debugPrint('share shot: $e');
      return null;
    }
  }

  static const double _w = 1080, _h = 1350, _band = 330;

  @visibleForTesting
  Future<Uint8List?> debugCard(ui.Image? shot, String headline, String detail) => _card(shot, headline, detail);

  Future<Uint8List?> _card(ui.Image? shot, String headline, String detail) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, _w, _h), Paint()..color = const Color(0xFFFFF8E7));
    const photo = Rect.fromLTWH(0, 0, _w, _h - _band);
    if (shot != null) {
      // cover the photo area, centred
      final s = math.max(photo.width / shot.width, photo.height / shot.height);
      final sw = photo.width / s, sh = photo.height / s;
      final src = Rect.fromLTWH((shot.width - sw) / 2, (shot.height - sh) / 2, sw, sh);
      c.drawImageRect(shot, src, photo, Paint()..filterQuality = FilterQuality.medium);
    } else {
      c.drawRect(photo, Paint()..color = const Color(0xFF9FCB63));
    }
    // a soft fade into the band
    c.drawRect(
      Rect.fromLTWH(0, photo.bottom - 60, _w, 60),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, photo.bottom - 60), Offset(0, photo.bottom),
            [const Color(0x00FFF8E7), const Color(0xFFFFF8E7)]),
    );
    c.drawRect(Rect.fromLTWH(0, photo.bottom, _w, 6), Paint()..color = const Color(0xFFD9B97A));
    final top = photo.bottom;
    _text(c, headline, 66, const Color(0xFF5D3A1A), top + 80, w: FontWeight.w900);
    _text(c, detail, 38, const Color(0xFF8A6A45), top + 160, w: FontWeight.w700);
    // the game's name on a green ribbon
    final name = _para('🌾 Mùa Lúa Chín', 44, Colors.white, FontWeight.w900, 700);
    final pill = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(_w / 2, top + 255), width: name.maxIntrinsicWidth + 90, height: 84),
        const Radius.circular(42));
    c.drawRRect(pill, Paint()..color = const Color(0xFF5A9E2F));
    c.drawParagraph(name, Offset((_w - name.width) / 2, top + 255 - name.height / 2));
    final img = await rec.endRecording().toImage(_w.toInt(), _h.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  /// One line, shrunk until it fits [maxW].
  static ui.Paragraph _para(String s, double size, Color color, FontWeight w, double maxW) {
    ui.Paragraph build(double sz) => (ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1, ellipsis: '…'))
          ..pushStyle(ui.TextStyle(color: color, fontSize: sz, fontWeight: w))
          ..addText(s))
        .build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));
    var p = build(size);
    if (p.maxIntrinsicWidth > maxW) p = build(math.max(size * .55, size * maxW / p.maxIntrinsicWidth));
    p.layout(ui.ParagraphConstraints(width: math.min(p.maxIntrinsicWidth, maxW) + 1));
    return p;
  }

  static void _text(Canvas c, String s, double size, Color color, double cy, {FontWeight w = FontWeight.w500}) {
    final p = _para(s, size, color, w, _w - 80);
    c.drawParagraph(p, Offset((_w - p.width) / 2, cy - p.height / 2));
  }
}
