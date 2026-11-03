// Isometric projection and low-level drawing helpers.


import 'package:flutter/painting.dart';

class Iso {
  static const hw = 32.0, hh = 16.0; // half tile width/height in px
  final Offset o;
  const Iso(this.o);

  Offset p(double x, double y, [double z = 0]) =>
      Offset(o.dx + (x - y) * hw, o.dy + (x + y) * hh - z);

  /// Screen point → fractional grid coordinates.
  (double, double) toGrid(Offset s) {
    final a = (s.dx - o.dx) / hw, b = (s.dy - o.dy) / hh;
    return ((a + b) / 2, (b - a) / 2);
  }
}

Color shade(Color c, double f) {
  // f < 0 darkens, f > 0 lightens
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + f).clamp(0.0, 1.0)).toColor();
}

Color withA(Color c, double a) => c.withValues(alpha: a);

Path poly(List<Offset> pts) {
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    path.lineTo(pts[i].dx, pts[i].dy);
  }
  return path..close();
}

final _fill = Paint()..isAntiAlias = true;
final _line = Paint()
  ..style = PaintingStyle.stroke
  ..isAntiAlias = true
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void fillPoly(Canvas c, List<Offset> pts, Color color) =>
    c.drawPath(poly(pts), _fill..color = color);

void strokePoly(Canvas c, List<Offset> pts, Color color, double width) =>
    c.drawPath(poly(pts), _line..color = color..strokeWidth = width);

void line(Canvas c, Offset a, Offset b, Color color, double width) =>
    c.drawLine(a, b, _line..color = color..strokeWidth = width);

void circle(Canvas c, Offset at, double r, Color color) =>
    c.drawCircle(at, r, _fill..color = color);

void oval(Canvas c, Offset at, double rx, double ry, Color color) =>
    c.drawOval(Rect.fromCenter(center: at, width: rx * 2, height: ry * 2),
        _fill..color = color);

void ovalStroke(Canvas c, Offset at, double rx, double ry, Color color, double w) =>
    c.drawOval(Rect.fromCenter(center: at, width: rx * 2, height: ry * 2),
        _line..color = color..strokeWidth = w);

void pathFill(Canvas c, Path p, Color color) => c.drawPath(p, _fill..color = color);
void pathStroke(Canvas c, Path p, Color color, double w) =>
    c.drawPath(p, _line..color = color..strokeWidth = w);

/// Soft elliptical shadow on the ground.
void shadow(Canvas c, Offset at, double rx, double ry, [double a = 0.22]) =>
    oval(c, at, rx, ry, Color.fromRGBO(30, 40, 10, a));

final Map<String, TextPainter> _tpCache = {};

/// Web loads the emoji fallback font lazily; painters laid out before it
/// arrives keep showing tofu, so callers can flush the cache.
void clearTextCache() => _tpCache.clear();

TextPainter textPainter(String s, double size,
    {Color color = const Color(0xFF3B2A14), FontWeight weight = FontWeight.w700}) {
  final key = '$s|$size|${color.toARGB32()}|${weight.value}';
  final hit = _tpCache[key];
  if (hit != null) return hit;
  if (_tpCache.length > 400) _tpCache.clear();
  final tp = TextPainter(
    text: TextSpan(
        text: s,
        style: TextStyle(fontSize: size, color: color, fontWeight: weight, height: 1.1)),
    textDirection: TextDirection.ltr,
  )..layout();
  return _tpCache[key] = tp;
}

void text(Canvas c, String s, Offset center, double size,
    {Color color = const Color(0xFF3B2A14), FontWeight weight = FontWeight.w700}) {
  final tp = textPainter(s, size, color: color, weight: weight);
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

/// Box with its footprint at grid (x,y,w,h) between heights z0..z1.
void box(Canvas c, Iso iso, double x, double y, double w, double h, double z0,
    double z1, Color top, Color left, Color right) {
  fillPoly(c, [iso.p(x, y + h, z0), iso.p(x + w, y + h, z0), iso.p(x + w, y + h, z1), iso.p(x, y + h, z1)], left);
  fillPoly(c, [iso.p(x + w, y, z0), iso.p(x + w, y + h, z0), iso.p(x + w, y + h, z1), iso.p(x + w, y, z1)], right);
  fillPoly(c, [iso.p(x, y, z1), iso.p(x + w, y, z1), iso.p(x + w, y + h, z1), iso.p(x, y + h, z1)], top);
}

/// Box with walls coloured by one base colour (left lighter, right darker).
void wallBox(Canvas c, Iso iso, double x, double y, double w, double h,
    double z0, double z1, Color wall, {Color? top}) {
  box(c, iso, x, y, w, h, z0, z1, top ?? shade(wall, .08), wall, shade(wall, -.12));
}

/// Diamond of the tile footprint at height z.
List<Offset> diamond(Iso iso, double x, double y, double w, double h, [double z = 0]) =>
    [iso.p(x, y, z), iso.p(x + w, y, z), iso.p(x + w, y + h, z), iso.p(x, y + h, z)];

enum RoofStyle { thatch, tile, tin, darkTile }

Color roofColor(RoofStyle s) => switch (s) {
      RoofStyle.thatch => const Color(0xFFD9B25F),
      RoofStyle.tile => const Color(0xFFC0563A),
      RoofStyle.tin => const Color(0xFF7E97A6),
      RoofStyle.darkTile => const Color(0xFF6E4A3A),
    };

/// Gable roof. [alongX]: ridge parallel to the x axis.
void gableRoof(Canvas c, Iso iso, double x, double y, double w, double h,
    double z, double rise, RoofStyle style,
    {bool alongX = true, double over = 0.12, Color? gableWall}) {
  final rc = roofColor(style);
  final front = rc, back = shade(rc, -.1), gable = gableWall ?? const Color(0xFFE9D9B4);
  final o = over;
  if (alongX) {
    final ym = y + h / 2;
    final b = [iso.p(x - o, y - o, z), iso.p(x + w + o, y - o, z), iso.p(x + w + o, ym, z + rise), iso.p(x - o, ym, z + rise)];
    fillPoly(c, b, back);
    fillPoly(c, [iso.p(x + w, y, z), iso.p(x + w, y + h, z), iso.p(x + w, ym, z + rise)], shade(gable, -.1));
    final f = [iso.p(x - o, y + h + o, z), iso.p(x + w + o, y + h + o, z), iso.p(x + w + o, ym, z + rise), iso.p(x - o, ym, z + rise)];
    fillPoly(c, f, front);
    _roofTexture(c, iso, style, f, along: true);
    line(c, f[3], f[2], shade(rc, -.25), 2);
    strokePoly(c, f, shade(rc, -.3), 0.8);
  } else {
    final xm = x + w / 2;
    final b = [iso.p(x - o, y - o, z), iso.p(x - o, y + h + o, z), iso.p(xm, y + h + o, z + rise), iso.p(xm, y - o, z + rise)];
    fillPoly(c, b, shade(rc, .04));
    fillPoly(c, [iso.p(x, y + h, z), iso.p(x + w, y + h, z), iso.p(xm, y + h, z + rise)], gable);
    final f = [iso.p(x + w + o, y - o, z), iso.p(x + w + o, y + h + o, z), iso.p(xm, y + h + o, z + rise), iso.p(xm, y - o, z + rise)];
    fillPoly(c, f, shade(rc, -.1));
    _roofTexture(c, iso, style, f, along: false);
    line(c, f[3], f[2], shade(rc, -.3), 2);
    strokePoly(c, b, shade(rc, -.3), 0.8);
    strokePoly(c, f, shade(rc, -.3), 0.8);
  }
}

/// Hip roof (four slopes), ridge along x.
void hipRoof(Canvas c, Iso iso, double x, double y, double w, double h, double z,
    double rise, RoofStyle style, {double over = 0.14, double inset = 0.35, bool curl = false}) {
  final rc = roofColor(style);
  final o = over, ym = y + h / 2;
  final r0 = x + inset * w, r1 = x + w - inset * w;
  final e = [iso.p(x - o, y - o, z), iso.p(x + w + o, y - o, z), iso.p(x + w + o, y + h + o, z), iso.p(x - o, y + h + o, z)];
  final ra = iso.p(r0, ym, z + rise), rb = iso.p(r1, ym, z + rise);
  fillPoly(c, [e[0], e[1], rb, ra], shade(rc, -.08)); // back
  fillPoly(c, [e[0], ra, e[3]], shade(rc, .02)); // left end
  final right = [e[1], e[2], rb];
  fillPoly(c, right, shade(rc, -.16));
  final front = [e[3], e[2], rb, ra];
  fillPoly(c, front, rc);
  _roofTexture(c, iso, style, front, along: true);
  strokePoly(c, front, shade(rc, -.3), 0.8);
  strokePoly(c, right, shade(rc, -.3), 0.8);
  line(c, ra, rb, shade(rc, -.32), 2.2);
  if (curl) {
    // upturned "đầu đao" corners
    for (final (p, dir) in [(e[3], -1.0), (e[2], 1.0), (e[1], 1.0)]) {
      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(p.dx + dir * 6, p.dy + 1, p.dx + dir * 8, p.dy - 9);
      pathStroke(c, path, shade(rc, -.3), 3);
    }
    // ridge ornaments
    final mid = Offset((ra.dx + rb.dx) / 2, (ra.dy + rb.dy) / 2);
    circle(c, mid - const Offset(0, 4), 3.5, const Color(0xFFE2B33C));
    for (final p in [ra, rb]) {
      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(p.dx + (p == ra ? -5 : 5), p.dy - 3, p.dx + (p == ra ? -3 : 3), p.dy - 10);
      pathStroke(c, path, shade(rc, -.32), 3);
    }
  }
}

void _roofTexture(Canvas c, Iso iso, RoofStyle style, List<Offset> q, {required bool along}) {
  // q: eave a, eave b, ridge b, ridge a
  final col = switch (style) {
    RoofStyle.thatch => const Color(0x553B2A10),
    RoofStyle.tile => const Color(0x66702A18),
    RoofStyle.tin => const Color(0x553A4A55),
    RoofStyle.darkTile => const Color(0x66301A10),
  };
  if (style == RoofStyle.thatch) {
    for (var i = 1; i < 5; i++) {
      final t = i / 5;
      line(c, Offset.lerp(q[0], q[3], t)!, Offset.lerp(q[1], q[2], t)!, col, 1);
    }
    line(c, q[0], q[1], shade(roofColor(style), -.25), 2.5);
  } else {
    final n = ((q[1] - q[0]).distance / 6).round().clamp(3, 40);
    for (var i = 1; i < n; i++) {
      final t = i / n;
      line(c, Offset.lerp(q[0], q[1], t)!, Offset.lerp(q[3], q[2], t)!, col, 1);
    }
    if (style != RoofStyle.tin) {
      for (var i = 1; i < 4; i++) {
        final t = i / 4;
        line(c, Offset.lerp(q[0], q[3], t)!, Offset.lerp(q[1], q[2], t)!, withA(col, .25), 0.8);
      }
    }
  }
}

/// A window/door drawn on the left (+y facing) wall: u along x, v up in px.
void leftWallRect(Canvas c, Iso iso, double x0, double yWall, double x1, double z0,
    double z1, Color color, {Color? frame}) {
  final pts = [iso.p(x0, yWall, z0), iso.p(x1, yWall, z0), iso.p(x1, yWall, z1), iso.p(x0, yWall, z1)];
  fillPoly(c, pts, color);
  if (frame != null) strokePoly(c, pts, frame, 1.2);
}

/// Same on the right (+x facing) wall.
void rightWallRect(Canvas c, Iso iso, double xWall, double y0, double y1, double z0,
    double z1, Color color, {Color? frame}) {
  final pts = [iso.p(xWall, y0, z0), iso.p(xWall, y1, z0), iso.p(xWall, y1, z1), iso.p(xWall, y0, z1)];
  fillPoly(c, pts, color);
  if (frame != null) strokePoly(c, pts, frame, 1.2);
}
