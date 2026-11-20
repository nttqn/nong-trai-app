// Decorations added in 1.8.0: the ones sold in Xây dựng → Trang trí and the
// weekly event gifts. Drawn in code until their art arrives (art/PROMPTS.md
// batch 15); a sprite with the same key replaces each.

import 'dart:math' as math;
import 'dart:ui';

import 'iso.dart';

const _wood = Color(0xFF8A5A33), _woodDark = Color(0xFF6B4226);
const _bamboo = Color(0xFFC9B26A), _bambooDark = Color(0xFF9C8445);
const _leaf = Color(0xFF5E9E3E), _leafDark = Color(0xFF3F7A2A);
const _tile = Color(0xFFA0442E);

/// Draws [type] if it is one of these decorations; false otherwise.
bool drawMoreDeco(Canvas c, Iso iso, String type, double x, double y, Offset f, double t, int seed) {
  final sway = math.sin(t * 1.4 + seed) * 1.2;
  switch (type) {
    case 'hang_rao':
      // runs along the tile's x axis so a row of them joins up
      final a = iso.p(x, y + .5), b = iso.p(x + 1, y + .5);
      shadow(c, f, 20, 3, .12);
      for (var i = 0; i <= 4; i++) {
        final p = Offset.lerp(a, b, i / 4)!;
        line(c, p, p + const Offset(0, -17), i % 2 == 0 ? _bambooDark : _bamboo, i % 2 == 0 ? 2.6 : 1.8);
      }
      for (final h in [-6.0, -12.0]) {
        line(c, a + Offset(0, h), b + Offset(0, h), _bambooDark, 1.6);
      }
      for (var i = 0; i < 8; i++) {
        final p = Offset.lerp(a, b, (i + .5) / 8)!;
        line(c, p + const Offset(-1, -2), p + const Offset(1, -15), shade(_bamboo, .1), 1);
      }
    case 'duong_gach':
      fillPoly(c, diamond(iso, x + .02, y + .02, .96, .96), const Color(0xFFC0664A));
      for (var i = 1; i < 3; i++) {
        line(c, iso.p(x + .02, y + i / 3), iso.p(x + .98, y + i / 3), const Color(0xFFE9C9A8), 1);
        // staggered joints
        for (var j = 0; j < 3; j++) {
          final u = x + (j + (i.isOdd ? .5 : 0)) / 3;
          if (u <= x + .02 || u >= x + .98) continue;
          line(c, iso.p(u, y + (i - 1) / 3), iso.p(u, y + i / 3), const Color(0xFFE9C9A8), 1);
        }
      }
      for (var j = 0; j < 3; j++) {
        final u = x + (j + .5) / 3;
        line(c, iso.p(u, y + 2 / 3), iso.p(u, y + .98), const Color(0xFFE9C9A8), 1);
      }
      strokePoly(c, diamond(iso, x + .02, y + .02, .96, .96), const Color(0xFF8E4A35), 1);
    case 'chong_tre':
      shadow(c, f, 20, 7);
      for (final (u, v) in [(.18, .3), (.82, .3), (.18, .7), (.82, .7)]) {
        final p = iso.p(x + u, y + v);
        line(c, p, p + const Offset(0, -10), _bambooDark, 2);
      }
      box(c, iso, x + .15, y + .27, .7, .46, 10, 12.5, _bamboo, shade(_bamboo, -.1), shade(_bamboo, -.22));
      for (var i = 1; i < 6; i++) {
        line(c, iso.p(x + .15 + i * .7 / 6, y + .27, 12.5), iso.p(x + .15 + i * .7 / 6, y + .73, 12.5), _bambooDark, .7);
      }
      // a teapot and two cups
      final tp = iso.p(x + .55, y + .45, 12.5);
      oval(c, tp + const Offset(0, -4), 4.5, 4, const Color(0xFF3F6E9E));
      line(c, tp + const Offset(4, -5), tp + const Offset(8, -8), const Color(0xFF3F6E9E), 1.6);
      oval(c, tp + const Offset(0, -8.5), 1.6, 1, const Color(0xFF2C4F73));
      for (final d in [const Offset(-9, 1), const Offset(-5, 4)]) {
        oval(c, tp + d, 2, 1.5, const Color(0xFFF5F0E6));
      }
    case 'cong_ngo':
      shadow(c, f, 22, 6);
      for (final u in [.12, .76]) {
        wallBox(c, iso, x + u, y + .4, .12, .2, 0, 38, const Color(0xFFE9D9B5));
      }
      // wooden double door between the pillars
      final d0 = iso.p(x + .24, y + .5), d1 = iso.p(x + .76, y + .5);
      fillPoly(c, [d0, d1, d1 + const Offset(0, -26), d0 + const Offset(0, -26)], _wood);
      line(c, Offset.lerp(d0, d1, .5)!, Offset.lerp(d0, d1, .5)! + const Offset(0, -26), _woodDark, 1.2);
      // little tiled roof over the top
      final r0 = iso.p(x + .02, y + .5, 40), r1 = iso.p(x + 1, y + .5, 40);
      fillPoly(c, [r0 + const Offset(-2, 4), r1 + const Offset(2, 4), r1 + const Offset(-4, -8), r0 + const Offset(4, -8)], _tile);
      line(c, r0 + const Offset(4, -8), r1 + const Offset(-4, -8), shade(_tile, -.25), 2);
      for (var i = 1; i < 6; i++) {
        final p = Offset.lerp(r0, r1, i / 6)!;
        line(c, p + const Offset(0, 4), p + const Offset(0, -8), shade(_tile, -.15), .8);
      }
    case 'gian_hoa':
      shadow(c, f, 18, 6);
      final l = iso.p(x + .2, y + .5), r = iso.p(x + .8, y + .5);
      line(c, l, l + const Offset(0, -38), _woodDark, 2.4);
      line(c, r, r + const Offset(0, -38), _woodDark, 2.4);
      final arch = Path()
        ..moveTo(l.dx, l.dy - 38)
        ..quadraticBezierTo((l.dx + r.dx) / 2, l.dy - 56, r.dx, r.dy - 38);
      pathStroke(c, arch, _woodDark, 2);
      final rng = math.Random(seed);
      for (var i = 0; i < 16; i++) {
        final k = i / 15;
        final p = Offset(l.dx + (r.dx - l.dx) * k, l.dy - 38 - math.sin(k * math.pi) * 12) +
            Offset(rng.nextDouble() * 8 - 4, rng.nextDouble() * 8 - 4);
        circle(c, p, 4.2, _leafDark);
        circle(c, p + const Offset(1.5, -1), 2.8, i.isEven ? const Color(0xFFE91E63) : const Color(0xFFD81B60));
      }
      for (var i = 0; i < 6; i++) {
        final side = i.isEven ? l : r;
        final p = side + Offset(rng.nextDouble() * 6 - 3, -8.0 - i * 5);
        circle(c, p, 3, const Color(0xFFEC407A));
      }
    case 'cot_den':
      shadow(c, f, 7, 3);
      line(c, f, f + const Offset(0, -46), const Color(0xFF546E7A), 3);
      line(c, f + const Offset(0, -44), f + const Offset(8, -46), const Color(0xFF546E7A), 2);
      final lamp = f + const Offset(9, -42);
      fillPoly(c, [lamp + const Offset(-4, -4), lamp + const Offset(4, -4), lamp + const Offset(3, 4), lamp + const Offset(-3, 4)],
          const Color(0xFFFFF3C4));
      line(c, lamp + const Offset(-5, -4), lamp + const Offset(5, -4), const Color(0xFF37474F), 2);
    case 'ao_sen':
      fillPoly(c, diamond(iso, x + .12, y + .12, 1.76, 1.76), const Color(0xFF9E9E8E));
      fillPoly(c, diamond(iso, x + .24, y + .24, 1.52, 1.52), const Color(0xFF4F8FB0));
      fillPoly(c, diamond(iso, x + .24, y + .24, 1.52, .3), const Color(0x22000000));
      final rng = math.Random(seed);
      for (var i = 0; i < 9; i++) {
        final p = iso.p(x + .45 + rng.nextDouble() * 1.1, y + .45 + rng.nextDouble() * 1.1);
        oval(c, p, 6.5, 3.2, i.isEven ? _leaf : _leafDark);
        line(c, p, p + const Offset(4, -1.5), const Color(0xFF8BC34A), .8);
      }
      for (var i = 0; i < 3; i++) {
        final p = iso.p(x + .6 + i * .35, y + 1.1 - i * .25) + Offset(sway * .3, -10);
        line(c, p + const Offset(0, 10), p, const Color(0xFF4E8B32), 1.2);
        for (var k = 0; k < 5; k++) {
          final a = -math.pi / 2 + (k - 2) * .5;
          oval(c, p + Offset(math.cos(a) * 3, math.sin(a) * 3 + 1), 2.2, 4, const Color(0xFFF48FB1));
        }
        circle(c, p + const Offset(0, 1), 1.5, const Color(0xFFFFC107));
      }
    case 'cay_mai':
      shadow(c, f, 13, 5);
      final pot = f + const Offset(0, -6);
      fillPoly(c, [pot + const Offset(-9, -6), pot + const Offset(9, -6), pot + const Offset(7, 6), pot + const Offset(-7, 6)],
          const Color(0xFF8D4E2A));
      line(c, pot + const Offset(-10, -6), pot + const Offset(10, -6), const Color(0xFF6D3A1F), 2);
      final top = pot + const Offset(0, -6);
      final branches = [const Offset(-14, -26), const Offset(12, -30), const Offset(-4, -40), const Offset(16, -16)];
      line(c, top, top + const Offset(0, -18), _woodDark, 3);
      for (final b in branches) {
        line(c, top + const Offset(0, -12), top + b, _woodDark, 1.6);
      }
      final rng = math.Random(seed);
      for (var i = 0; i < 26; i++) {
        final b = branches[i % branches.length];
        final k = .4 + rng.nextDouble() * .6;
        final p = top + const Offset(0, -12) + (b - const Offset(0, -12)) * k + Offset(rng.nextDouble() * 6 - 3, rng.nextDouble() * 6 - 3);
        circle(c, p, 2.6, const Color(0xFFFFC107));
        circle(c, p, 1, const Color(0xFFE65100));
      }
    case 'hon_non_bo':
      shadow(c, f, 16, 6);
      final b = f + const Offset(0, -4);
      oval(c, b, 15, 8, const Color(0xFF8D8D85));
      oval(c, b + const Offset(0, -2), 12, 6, const Color(0xFF5B9CC0));
      final rock = Path()
        ..moveTo(b.dx - 10, b.dy - 2)
        ..lineTo(b.dx - 7, b.dy - 24)
        ..lineTo(b.dx - 2, b.dy - 18)
        ..lineTo(b.dx + 2, b.dy - 36)
        ..lineTo(b.dx + 7, b.dy - 20)
        ..lineTo(b.dx + 10, b.dy - 2)
        ..close();
      pathFill(c, rock, const Color(0xFF8A8A82));
      fillPoly(c, [Offset(b.dx + 2, b.dy - 36), Offset(b.dx + 7, b.dy - 20), Offset(b.dx + 10, b.dy - 2), Offset(b.dx + 3, b.dy - 4)],
          const Color(0xFF6E6E68));
      // a little banyan clinging to the peak and a trickle of water
      circle(c, Offset(b.dx - 2, b.dy - 34), 5, _leafDark);
      circle(c, Offset(b.dx + 1, b.dy - 37), 4, _leaf);
      line(c, Offset(b.dx + 4, b.dy - 22), Offset(b.dx + 5, b.dy - 4), const Color(0xCCE3F2FD), 1.6);
    // ------------------------------------------------ weekly event gifts
    case 'bo_lua':
      shadow(c, f, 10, 4);
      final band = f + const Offset(0, -14);
      for (var i = -5; i <= 5; i++) {
        line(c, f + Offset(i * 1.2, 0), band, const Color(0xFFCFA43A), 1.4);
        final tip = band + Offset(i * 3.2 + sway, -18 - (5 - i.abs()) * 1.6);
        line(c, band, tip, const Color(0xFFE8C766), 1.4);
        oval(c, tip, 1.6, 3.2, const Color(0xFFF2D27A));
      }
      line(c, band + const Offset(-5, 0), band + const Offset(5, 0), const Color(0xFFD32F2F), 3);
    case 'o_ga':
      shadow(c, f, 13, 5);
      oval(c, f + const Offset(0, -4), 13, 6, const Color(0xFFD9B35B));
      for (var i = 0; i < 6; i++) {
        line(c, f + Offset(-12 + i * 4.5, -2), f + Offset(-9 + i * 4.5, -8), const Color(0xFFB8913E), 1);
      }
      // the hen sitting on her eggs
      final h = f + const Offset(1, -12);
      oval(c, h, 9, 7, const Color(0xFFB5652F));
      oval(c, h + const Offset(-3, 1), 5, 4, const Color(0xFF8D4A22));
      circle(c, h + const Offset(7, -6), 4, const Color(0xFFB5652F));
      fillPoly(c, [h + const Offset(6, -10), h + const Offset(9, -11), h + const Offset(8, -8)], const Color(0xFFE53935));
      fillPoly(c, [h + const Offset(10.5, -6), h + const Offset(13.5, -5), h + const Offset(10.5, -4)], const Color(0xFFFFB300));
      circle(c, h + const Offset(8, -6.5), .9, const Color(0xFF212121));
      for (final d in [const Offset(-10, -3), const Offset(-7, -1)]) {
        oval(c, f + d, 2.2, 2.8, const Color(0xFFF3E3C3));
      }
    case 'gian_bau':
      shadow(c, f, 22, 8);
      final posts = [iso.p(x + .15, y + .15), iso.p(x + .85, y + .15), iso.p(x + .85, y + .85), iso.p(x + .15, y + .85)];
      for (final p in posts) {
        line(c, p, p + const Offset(0, -34), _bambooDark, 2);
      }
      final top = [for (final p in posts) p + const Offset(0, -34)];
      strokePoly(c, top, _bambooDark, 1.4);
      line(c, Offset.lerp(top[0], top[1], .5)!, Offset.lerp(top[3], top[2], .5)!, _bambooDark, 1);
      line(c, Offset.lerp(top[0], top[3], .5)!, Offset.lerp(top[1], top[2], .5)!, _bambooDark, 1);
      final rng = math.Random(seed);
      for (var i = 0; i < 18; i++) {
        final p = Offset.lerp(Offset.lerp(top[0], top[1], rng.nextDouble())!, Offset.lerp(top[3], top[2], rng.nextDouble())!,
            rng.nextDouble())!;
        oval(c, p, 6, 3.4, i.isEven ? _leaf : _leafDark);
      }
      for (var i = 0; i < 4; i++) {
        final p = Offset.lerp(Offset.lerp(top[3], top[2], .2 + i * .2)!, Offset.lerp(top[0], top[1], .3 + i * .15)!, .3)!;
        line(c, p, p + Offset(sway * .4, 8), _leafDark, .8);
        oval(c, p + Offset(sway * .4, 13), 3, 6, const Color(0xFFB7D77A));
      }
    case 'thuyen_nan':
      shadow(c, f, 15, 6);
      final b = f + const Offset(0, -6);
      oval(c, b, 14, 8, const Color(0xFF5D3A1E));
      oval(c, b + const Offset(0, -3), 12, 5.5, const Color(0xFF7A4F28));
      for (var i = 0; i < 5; i++) {
        ovalStroke(c, b + const Offset(0, -3), 12 - i * 2.2, 5.5 - i, const Color(0xFF5D3A1E), .7);
      }
      line(c, b + const Offset(-2, -4), b + const Offset(16, -22), _wood, 2.2);
      oval(c, b + const Offset(16, -22), 2.4, 4, _wood);
    case 'binh_gom':
      shadow(c, f, 9, 4);
      final v = f + const Offset(0, -2);
      final body = Path()
        ..moveTo(v.dx - 4, v.dy)
        ..quadraticBezierTo(v.dx - 12, v.dy - 10, v.dx - 4, v.dy - 20)
        ..lineTo(v.dx - 3, v.dy - 26)
        ..lineTo(v.dx + 3, v.dy - 26)
        ..lineTo(v.dx + 4, v.dy - 20)
        ..quadraticBezierTo(v.dx + 12, v.dy - 10, v.dx + 4, v.dy)
        ..close();
      pathFill(c, body, const Color(0xFFF5F2EA));
      line(c, v + const Offset(-8, -12), v + const Offset(8, -12), const Color(0xFF2E5C9A), 1.6);
      line(c, v + const Offset(-6, -6), v + const Offset(6, -6), const Color(0xFF2E5C9A), 1);
      circle(c, v + const Offset(0, -9), 1.6, const Color(0xFF2E5C9A));
      oval(c, v + const Offset(-3, -14), 1.4, 4, const Color(0x55FFFFFF));
      for (var i = 0; i < 4; i++) {
        final tip = v + Offset(-6.0 + i * 4 + sway * .3, -36.0 - (i.isOdd ? 4 : 0));
        line(c, v + const Offset(0, -26), tip, _leafDark, 1);
        circle(c, tip, 2.8, i.isEven ? const Color(0xFFE53935) : const Color(0xFFFFB300));
      }
    case 'xe_bo':
      // a cart on the left tile, the ox pulling it on the right
      final cart = iso.p(x + .5, y + .5), ox = iso.p(x + 1.45, y + .5);
      shadow(c, Offset.lerp(cart, ox, .5)!, 34, 8);
      box(c, iso, x + .15, y + .25, .7, .5, 12, 16, const Color(0xFFB07A45), _wood, _woodDark);
      for (final (dx, col) in [(-7.0, Color(0xFFE6D2A0)), (3.0, Color(0xFFD9C08A)), (-2.0, Color(0xFFEADBB5))]) {
        oval(c, cart + Offset(dx, -22), 6, 6, col);
        line(c, cart + Offset(dx - 2, -27), cart + Offset(dx + 2, -27), const Color(0xFF8D6E4C), 1);
      }
      final wheel = iso.p(x + .5, y + .8, 8);
      ovalStroke(c, wheel, 7, 8, _woodDark, 2);
      line(c, wheel + const Offset(-7, 0), wheel + const Offset(7, 0), _woodDark, 1);
      line(c, wheel + const Offset(0, -8), wheel + const Offset(0, 8), _woodDark, 1);
      line(c, iso.p(x + .85, y + .5, 13), ox + const Offset(-6, -12), _woodDark, 2);
      // the ox
      final bob = math.sin(t * 2 + seed) * .6;
      oval(c, ox + Offset(0, -14 + bob), 11, 7, const Color(0xFF8D5A3B));
      for (final d in [-6.0, -2.0, 4.0, 8.0]) {
        line(c, ox + Offset(d, -10), ox + Offset(d, 0), const Color(0xFF6D4228), 2);
      }
      final head = ox + Offset(12, -17 + bob);
      oval(c, head, 4.5, 4, const Color(0xFF7A4A2E));
      line(c, head + const Offset(-2, -3), head + const Offset(-5, -8), const Color(0xFFEDE3C8), 1.4);
      line(c, head + const Offset(2, -3), head + const Offset(5, -8), const Color(0xFFEDE3C8), 1.4);
      circle(c, head + const Offset(1.5, -.5), .8, const Color(0xFF212121));
    default:
      return false;
  }
  return true;
}
