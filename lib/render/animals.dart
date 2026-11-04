// Farm animals in screen space. f = foot point, dir = ±1 facing, ph = phase.

import 'dart:math' as math;
import 'dart:ui';

import 'iso.dart';

void drawAnimal(Canvas c, String id, Offset f, double dir, double t, double ph) {
  switch (id) {
    case 'ga':
      _chicken(c, f, dir, t, ph);
    case 'vit':
      _duck(c, f, dir, t, ph);
    case 'lon':
      _pig(c, f, dir, t, ph);
    case 'bo':
      _cow(c, f, dir, t, ph, const Color(0xFFF5F1E8), spots: true);
    case 'trau':
      _buffalo(c, f, dir, t, ph);
    case 'de':
      _goat(c, f, dir, t, ph);
    case 'ong':
      _bees(c, f, t, ph);
  }
}

void _goat(Canvas c, Offset f, double d, double t, double ph) {
  const body = Color(0xFFF2EFE6);
  shadow(c, f, 9, 2.6);
  for (final x in [-5.0, -3.0, 3.0, 5.0]) {
    line(c, _m(f, d, x, -5), _m(f, d, x, 0), const Color(0xFF9E9787), 1.6);
  }
  oval(c, _m(f, d, 0, -8), 8, 4.5, body);
  final graze = math.sin(t * .8 + ph * 3) > .4 ? 4.0 : 0.0;
  final head = _m(f, d, 8, -11 + graze);
  oval(c, head, 3.2, 2.6, body);
  line(c, head + Offset(-1 * d, -2), head + Offset(-3 * d, -6), const Color(0xFF8D7B5E), 1.3);
  line(c, head + Offset(2.6 * d, 1.4), head + Offset(2.6 * d, 3.6), const Color(0xFFD9D2C0), 1.2); // beard
  circle(c, head + Offset(.9 * d, -.6), .6, const Color(0xFF1B1B1B));
  line(c, _m(f, d, -8, -10), _m(f, d, -10, -12 + math.sin(t * 5 + ph)), body, 1.6);
}

/// A few bees buzzing around a hive spot.
void _bees(Canvas c, Offset f, double t, double ph) {
  for (var i = 0; i < 3; i++) {
    final a = t * (2.2 + i * .4) + ph * 2 + i * 2.1;
    final p = f + Offset(math.cos(a) * 9, -12 + math.sin(a * 1.3) * 5);
    oval(c, p, 2.2, 1.5, const Color(0xFFFFC107));
    line(c, p + const Offset(-.6, -1.4), p + const Offset(-.6, 1.4), const Color(0xFF3E2A1A), .8);
    final w = math.sin(t * 40 + i) * 1.2;
    oval(c, p + Offset(0, -2 - w * .3), 1.6, 1, const Color(0xCCFFFFFF));
  }
}

Offset _m(Offset f, double dir, double x, double y) => f + Offset(x * dir, y);

void _chicken(Canvas c, Offset f, double d, double t, double ph) {
  final peck = math.max(0, math.sin(t * 3 + ph * 7)) > .85 ? 3.0 : 0.0;
  shadow(c, f, 6, 2);
  line(c, _m(f, d, -1, -3), _m(f, d, -1, 0), const Color(0xFFE0A030), 1);
  line(c, _m(f, d, 1.5, -3), _m(f, d, 1.5, 0), const Color(0xFFE0A030), 1);
  // tail
  final tail = Path()
    ..moveTo(_m(f, d, -4, -6).dx, _m(f, d, -4, -6).dy)
    ..lineTo(_m(f, d, -8, -12).dx, _m(f, d, -8, -12).dy)
    ..lineTo(_m(f, d, -6, -5).dx, _m(f, d, -6, -5).dy)
    ..close();
  pathFill(c, tail, const Color(0xFF3E2A1A));
  oval(c, _m(f, d, 0, -6), 5.5, 4, const Color(0xFFB8682E));
  oval(c, _m(f, d, -1, -6.5), 3, 2, const Color(0xFF8E4A1F));
  final head = _m(f, d, 4.5, -10 + peck);
  circle(c, head, 2.6, const Color(0xFFC9772F));
  circle(c, head + Offset(0, -2.6), 1.3, const Color(0xFFE53935));
  fillPoly(c, [head + Offset(2.2 * d, -.6), head + Offset(4.5 * d, .4), head + Offset(2.2 * d, 1)], const Color(0xFFF2B630));
  circle(c, head + Offset(.8 * d, -.6), .6, const Color(0xFF1B1B1B));
}

void _duck(Canvas c, Offset f, double d, double t, double ph) {
  shadow(c, f, 7, 2.2);
  line(c, _m(f, d, -1, -3), _m(f, d, -1, 0), const Color(0xFFF08A24), 1.4);
  line(c, _m(f, d, 2, -3), _m(f, d, 2, 0), const Color(0xFFF08A24), 1.4);
  oval(c, _m(f, d, 0, -6), 6.5, 4, const Color(0xFFFAFAF5));
  oval(c, _m(f, d, -1.5, -6), 3.5, 2.2, const Color(0xFFE3E3DA));
  final bob = math.sin(t * 2 + ph * 5) * .8;
  line(c, _m(f, d, 4, -7), _m(f, d, 5, -11 + bob), const Color(0xFFFAFAF5), 3);
  final head = _m(f, d, 5, -12 + bob);
  circle(c, head, 2.5, const Color(0xFF5E8C6A));
  fillPoly(c, [head + Offset(1.6 * d, -.4), head + Offset(5 * d, .4), head + Offset(1.6 * d, 1.4)], const Color(0xFFF08A24));
  circle(c, head + Offset(.6 * d, -.8), .6, const Color(0xFF111111));
}

void _pig(Canvas c, Offset f, double d, double t, double ph) {
  shadow(c, f, 10, 3);
  for (final x in [-5.0, -2.0, 3.0, 6.0]) {
    line(c, _m(f, d, x, -4), _m(f, d, x, 0), const Color(0xFFD98C93), 2);
  }
  oval(c, _m(f, d, 0, -7), 9.5, 5.5, const Color(0xFFF2A7AE));
  oval(c, _m(f, d, -1, -9), 6, 2.5, const Color(0xFFF7C3C8));
  final head = _m(f, d, 8, -8);
  circle(c, head, 4.2, const Color(0xFFF2A7AE));
  oval(c, head + Offset(3.4 * d, .6), 1.8, 1.6, const Color(0xFFE07F89));
  circle(c, head + Offset(3.2 * d, .3), .45, const Color(0xFF7A3B44));
  fillPoly(c, [head + Offset(-1.5 * d, -3), head + Offset(.5 * d, -6), head + Offset(1.4 * d, -2.6)], const Color(0xFFE38D97));
  circle(c, head + Offset(1.2 * d, -1.4), .7, const Color(0xFF2B1B1B));
  final wag = math.sin(t * 6 + ph) * 1.5;
  final tail = Path()
    ..moveTo(_m(f, d, -9, -8).dx, _m(f, d, -9, -8).dy)
    ..quadraticBezierTo(_m(f, d, -12, -11 + wag).dx, _m(f, d, -12, -11 + wag).dy,
        _m(f, d, -11, -7).dx, _m(f, d, -11, -7).dy);
  pathStroke(c, tail, const Color(0xFFE07F89), 1.2);
}

void _cow(Canvas c, Offset f, double d, double t, double ph, Color body, {bool spots = false}) {
  shadow(c, f, 13, 3.5);
  for (final x in [-8.0, -5.0, 5.0, 8.0]) {
    line(c, _m(f, d, x, -6), _m(f, d, x, 0), shade(body, -.35), 2.4);
  }
  oval(c, _m(f, d, 0, -10), 12, 6, body);
  if (spots) {
    oval(c, _m(f, d, -4, -11), 4, 3, const Color(0xFF2B2B2B));
    oval(c, _m(f, d, 4, -9), 3, 2.4, const Color(0xFF2B2B2B));
    oval(c, _m(f, d, 0, -4.8), 2.2, 1.4, const Color(0xFFF4B6C2)); // udder
  }
  final graze = math.sin(t * .7 + ph * 3) > .3 ? 5.0 : 0.0;
  final head = _m(f, d, 12, -12 + graze);
  oval(c, head, 4, 3.4, body);
  oval(c, head + Offset(2.6 * d, 1.4), 2.4, 1.8, const Color(0xFFF2C6B4));
  line(c, head + Offset(-1 * d, -3), head + Offset(-3 * d, -6), const Color(0xFFE8E0C8), 1.4);
  line(c, head + Offset(1 * d, -3), head + Offset(2 * d, -6), const Color(0xFFE8E0C8), 1.4);
  circle(c, head + Offset(.8 * d, -.8), .7, const Color(0xFF1B1B1B));
  line(c, _m(f, d, -12, -11), _m(f, d, -13, -4 + math.sin(t * 2 + ph)), shade(body, -.3), 1.2);
}

void _buffalo(Canvas c, Offset f, double d, double t, double ph) {
  const body = Color(0xFF55585E);
  shadow(c, f, 14, 4);
  for (final x in [-8.0, -5.0, 5.0, 8.0]) {
    line(c, _m(f, d, x, -6), _m(f, d, x, 0), const Color(0xFF3C3E42), 2.8);
  }
  oval(c, _m(f, d, 0, -11), 13, 6.8, body);
  oval(c, _m(f, d, -2, -14), 8, 2.6, const Color(0xFF6A6E75));
  final graze = math.sin(t * .6 + ph * 3) > .2 ? 5.0 : 0.0;
  final head = _m(f, d, 13, -11 + graze);
  oval(c, head, 4.6, 3.8, const Color(0xFF4A4D52));
  oval(c, head + Offset(3 * d, 1.6), 2.4, 1.8, const Color(0xFF34363A));
  // big crescent horns
  final horn = Path()
    ..moveTo(head.dx - 6, head.dy - 2)
    ..quadraticBezierTo(head.dx - 9, head.dy - 9, head.dx - 2, head.dy - 9)
    ..moveTo(head.dx + 6, head.dy - 2)
    ..quadraticBezierTo(head.dx + 9, head.dy - 9, head.dx + 2, head.dy - 9);
  pathStroke(c, horn, const Color(0xFFD8CFB8), 2.2);
  circle(c, head + Offset(1 * d, -1), .7, const Color(0xFF111111));
  line(c, _m(f, d, -13, -12), _m(f, d, -14, -4 + math.sin(t * 2 + ph)), const Color(0xFF3C3E42), 1.3);
}

/// White egrets (cò) flapping across the fields.
void drawEgret(Canvas c, Offset p, double t, double ph) {
  final flap = math.sin(t * 6 + ph) * 5;
  final path = Path()
    ..moveTo(p.dx - 11, p.dy - flap)
    ..quadraticBezierTo(p.dx - 5, p.dy - 4 - flap * .4, p.dx, p.dy)
    ..quadraticBezierTo(p.dx + 5, p.dy - 4 - flap * .4, p.dx + 11, p.dy - flap);
  pathStroke(c, path, const Color(0xFFFFFFFF), 2.2);
  oval(c, p + const Offset(0, 1), 3.5, 1.6, const Color(0xFFFFFFFF));
  line(c, p + const Offset(3, 1), p + const Offset(8, 2), const Color(0xFFFFFFFF), 1.4);
  line(c, p + const Offset(-3, 1.5), p + const Offset(-8, 3), const Color(0xFF333333), 0.8);
}

/// The guard dog: wags and looks about when fed, curls up asleep when hungry.
void drawDog(Canvas c, Offset f, double t, {required bool awake}) {
  const fur = Color(0xFFC98B4B), dark = Color(0xFF8A5A2B), light = Color(0xFFF1D3A8);
  shadow(c, f, 10, 4);
  if (!awake) {
    oval(c, f + const Offset(0, -4), 10, 5, fur);
    oval(c, f + const Offset(-7, -5), 4.5, 4, fur);
    oval(c, f + const Offset(-9, -7), 2, 2.5, dark);
    line(c, f + const Offset(8, -3), f + const Offset(3, 0), dark, 2.5);
    final z = (t * .8) % 1;
    text(c, 'z', f + Offset(-10 + z * 6, -14 - z * 10), 7 + z * 3, color: Color.fromRGBO(255, 255, 255, 1 - z));
    return;
  }
  final wag = math.sin(t * 14) * 4;
  final look = math.sin(t * .7) > .6 ? 2.0 : 0.0;
  line(c, f + const Offset(6, -9), f + Offset(11 + wag * .4, -15 - wag.abs() * .3), fur, 2.5); // tail
  oval(c, f + const Offset(1, -7), 8, 5, fur); // body
  line(c, f + const Offset(-4, -4), f + const Offset(-4, 0), dark, 2);
  line(c, f + const Offset(5, -4), f + const Offset(5, 0), dark, 2);
  oval(c, f + Offset(-7 + look, -13), 5, 4.5, fur); // head
  oval(c, f + Offset(-10 + look, -11.5), 2.6, 2, light); // muzzle
  circle(c, f + Offset(-12 + look, -12), 1, const Color(0xFF222222)); // nose
  circle(c, f + Offset(-7.5 + look, -14), .9, const Color(0xFF222222)); // eye
  fillPoly(c, [f + Offset(-5 + look, -17), f + Offset(-2 + look, -16), f + Offset(-3 + look, -11)], dark); // ear
  oval(c, f + const Offset(0, -6), 5, 2.5, light);
}
