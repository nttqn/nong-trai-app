// Village life: people and animals that wander about the map just for
// show. Nothing here touches the game state; everything is worked out from
// the clock (plus a tiny remembered random walk for the free-range hens).
//
// - villagers on the village road: a farmer with a shoulder pole, a girl
//   on a bicycle, a boy riding a buffalo playing the flute, a duck herder
//   driving his flock, two kids with a kite
// - a farmer at work in one of the growing fields
// - a hen and her chicks pecking about the yard by the house
// - a duck and ducklings swimming on the lotus lake
// - a little sampan poled along the river
//
// Optional sprites (art batch 13) replace the code-drawn people.

import 'dart:math' as math;
import 'dart:ui';

import '../core/defs.dart';
import '../core/farm.dart';
import 'animals.dart';
import 'ground.dart' show hash2;
import 'iso.dart';
import 'sprites.dart';

/// Something to draw in depth order among the farm objects.
class Actor {
  /// Compared with farm_painter's depthOf (front corner x + y).
  final double depth;

  /// Roughly where it stands on screen (for culling).
  final Offset at;
  final void Function(Canvas c) draw;
  const Actor(this.depth, this.at, this.draw);
}

/// People are drawn a size up from their local units, to stand right next
/// to the painted animals and houses.
const _people = 1.35;

const _ink = Color(0xFF4A3426);
const _skin = Color(0xFFF0C8A0);
const _hair = Color(0xFF2B211C);
const _hat = Color(0xFFEAD9A4);
const _hatShade = Color(0xFFCDB57E);
const _shirts = [
  Color(0xFF8A5A3B), // áo nâu
  Color(0xFF3F5A7A), // áo chàm
  Color(0xFFF3EFE4), // áo bà ba trắng
  Color(0xFF6E9A5A),
  Color(0xFFB5543F),
];

/// Depth of something standing at grid point (gx, gy): a hair in front of
/// the tile centre so it shows over what stands behind and beside it.
double _depthAt(double gx, double gy) => gx + gy + 1.3;

/// Everything alive on the map this frame, to be merged into the object
/// draw order. [night] 0..1, [rain] when it pours.
List<Actor> villageLife(Farm farm, Iso iso, double t, {required double night, required bool rain}) {
  final out = <Actor>[];
  if (night < .5) {
    _road(out, iso, t, rain);
    _fieldWorkers(out, farm, iso, t);
    if (!rain) _hens(out, farm, iso, t);
  }
  return out;
}

/// Ducks on the lake and the boat on the river: on the water, which nothing
/// stands on, so drawn right after the ground.
void drawWaterLife(Canvas c, Iso iso, double t, {required double night}) {
  if (night > .5) return;
  final shown = c.getLocalClipBounds().inflate(80);
  _lakeDucks(c, iso, t, shown);
  _boat(c, iso, t, shown);
}

// ------------------------------------------------------------- the road

enum _Walker { ganh, xeDap, trau, vit, dieu }

const _walkerMix = [
  _Walker.ganh, _Walker.xeDap, _Walker.trau, _Walker.vit, _Walker.dieu, //
  _Walker.ganh, _Walker.xeDap, _Walker.ganh, _Walker.dieu,
];

/// Tiles per second.
double _speed(_Walker w) => switch (w) {
      _Walker.ganh => .42,
      _Walker.xeDap => 1.05,
      _Walker.trau => .37,
      _Walker.vit => .4,
      _Walker.dieu => .72,
    };

const _roadFrom = -1.5, _roadTo = 36.8, _roadLen = _roadTo - _roadFrom;

void _road(List<Actor> out, Iso iso, double t, bool rain) {
  final lanes = rain ? 3 : 9;
  for (var lane = 0; lane < lanes; lane++) {
    final period = 112.0 + lane * 13;
    final lt = t + lane * 37.7 + 5000;
    final slot = (lt / period).floor();
    final u = lt - slot * period;
    final seed = slot * 31 + lane * 7;
    var kind = _walkerMix[(hash2(seed, 1) * _walkerMix.length).floor() % _walkerMix.length];
    if (rain && kind == _Walker.dieu) kind = _Walker.ganh; // no kites in the rain
    final dur = _roadLen / _speed(kind);
    final start = hash2(seed, 2) * (period - dur - 2);
    final k = (u - start) / dur;
    if (k < 0 || k > 1) continue;
    final down = hash2(seed, 3) < .5; // down the screen (+y) or back up
    final gy = down ? _roadFrom + _roadLen * k : _roadTo - _roadLen * k;
    final gx = Farm.roadX + (down ? .34 : .66); // keep to their side
    final fade = math.min(1.0, math.min(k, 1 - k) * _roadLen / 1.2);
    final ph = t * 2 * math.pi * (kind == _Walker.dieu ? 2.6 : 1.7) + lane;
    final shirt = _shirts[(hash2(seed, 4) * _shirts.length).floor() % _shirts.length];
    final dir = down ? 1.0 : -1.0; // grid y step
    void add(double y, void Function(Canvas c, Offset f) paint, {double dx = 0}) {
      final f = iso.p(gx + dx, y);
      out.add(Actor(_depthAt(gx + dx, y), f, (c) => _faded(c, f, fade, () => paint(c, f))));
    }

    switch (kind) {
      case _Walker.ganh:
        final rice = hash2(seed, 5) < .5;
        add(gy, (c, f) => _carrier(c, f, ph, down, shirt, rice));
      case _Walker.xeDap:
        add(gy, (c, f) => _cyclist(c, f, t, down, shirt));
      case _Walker.trau:
        add(gy, (c, f) => _buffaloBoy(c, f, t, ph, down));
      case _Walker.vit:
        add(gy, (c, f) => _herder(c, f, t, ph, down, shirt));
        for (var i = 0; i < 6; i++) {
          final ahead = .55 + (i ~/ 2) * .38 + hash2(seed, 10 + i) * .2;
          final side = ((i % 2) - .5) * .32 + (hash2(seed, 20 + i) - .5) * .12;
          final wob = math.sin(t * 1.3 + i * 2.1) * .06;
          add(gy + dir * (ahead + wob), (c, f) => _walkingDuck(c, f, t, i.toDouble(), down), dx: side);
        }
      case _Walker.dieu:
        add(gy, (c, f) => _kiteKid(c, f, t, ph, down, shirt));
        final lag = .55 + math.sin(t * .9 + lane) * .12;
        add(gy - dir * lag, (c, f) => _kid(c, f, ph + 1.4, down, down, _shirts[(lane + 2) % _shirts.length], wave: true),
            dx: down ? .18 : -.18);
    }
  }
}

void _faded(Canvas c, Offset f, double a, void Function() paint) {
  if (a >= .999) return paint();
  if (a <= 0) return;
  c.saveLayer(Rect.fromCenter(center: f - const Offset(0, 40), width: 200, height: 240),
      Paint()..color = Color.fromRGBO(0, 0, 0, a));
  paint();
  c.restore();
}

// ---------------------------------------------------------- people bits

/// Draws [paint] in a local frame facing right with the feet at the
/// origin; mirrored for [left].
void _local(Canvas c, Offset f, bool left, void Function() paint, [double scale = 1]) {
  scale *= _people;
  c.save();
  c.translate(f.dx, f.dy);
  c.scale(left ? -scale : scale, scale);
  paint();
  c.restore();
}

/// Torso, arms, head and hat from the hip point [hip] up. [hands] are the
/// two hand points (behind arm first). [front] shows the face, else the
/// back of the head.
void _upper(Canvas c, Offset hip,
    {required Color shirt,
    required bool front,
    required List<Offset> hands,
    bool hat = true,
    double lean = 0}) {
  c.save();
  c.translate(hip.dx, hip.dy);
  if (lean != 0) c.rotate(lean);
  final dark = shade(shirt, .78);
  const sh = Offset(0, -7); // shoulder
  // hands are given unrotated; bring them into the leaning frame
  final cs = math.cos(-lean), sn = math.sin(-lean);
  hands = [
    for (final h in hands) Offset((h - hip).dx * cs - (h - hip).dy * sn, (h - hip).dx * sn + (h - hip).dy * cs) + hip,
  ];
  // back arm
  line(c, sh + const Offset(-.6, 0), hands[0] - hip, dark, 2.1);
  circle(c, hands[0] - hip, 1.1, _skin);
  final torso = RRect.fromRectAndRadius(const Rect.fromLTRB(-3.4, -8.6, 3.4, .6), const Radius.circular(2.6));
  c.drawRRect(torso, Paint()..color = shirt);
  c.drawRRect(torso,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8);
  // front arm
  line(c, sh + const Offset(.8, 0), hands[1] - hip, dark, 2.2);
  circle(c, hands[1] - hip, 1.15, _skin);
  // head
  const head = Offset(.5, -11.8);
  circle(c, head, 3.3, _skin);
  if (front) {
    circle(c, head + const Offset(1.1, -.2), .45, _ink);
    circle(c, head + const Offset(2.5, -.2), .45, _ink);
    circle(c, head + const Offset(2.2, 1.3), .7, const Color(0x55E57373));
  } else {
    c.drawArc(Rect.fromCircle(center: head, radius: 3.3), math.pi * .55, math.pi * 1.25, true, Paint()..color = _hair);
  }
  ovalStroke(c, head, 3.3, 3.3, _ink, .7);
  if (hat) {
    final rim = head.dy - 1.3;
    final cone = [Offset(-7, rim), Offset(8, rim), Offset(.5, rim - 6.8)];
    fillPoly(c, cone, _hat);
    fillPoly(c, [Offset(.5, rim), Offset(8, rim), Offset(.5, rim - 6.8)], _hatShade);
    line(c, Offset(-3.6, rim - 3.2), Offset(4.6, rim - 3.2), withA(_ink, .35), .6);
    strokePoly(c, cone, _ink, .8);
  } else {
    // a cap of hair over the forehead, a tuft sticking up
    c.drawArc(Rect.fromCircle(center: head, radius: 3.4), math.pi * 1.08, math.pi * .84, false, Paint()..color = _hair);
    fillPoly(c, [head + const Offset(-.6, -3), head + const Offset(.4, -5), head + const Offset(1.2, -3)], _hair);
  }
  c.restore();
}

/// Two walking legs from the hip down to the feet at the origin.
void _legs(Canvas c, double ph, {Color pants = const Color(0xFF3B3430), double len = 8, bool walking = true}) {
  final s = walking ? math.sin(ph) * 2.3 : 0.0;
  line(c, Offset(-.7, -len), Offset(-.7 - s, -.4), shade(pants, .8), 2.4);
  line(c, Offset(.7, -len), Offset(.7 + s, -.4), pants, 2.4);
  oval(c, Offset(-.7 - s + .6, 0), 1.4, .7, _ink);
  oval(c, Offset(.7 + s + .6, 0), 1.4, .7, _ink);
}

double _bob(double ph) => math.sin(ph).abs() * .8;

/// Farmer carrying two baskets on a shoulder pole (đòn gánh).
void _carrier(Canvas c, Offset f, double ph, bool down, Color shirt, bool rice) {
  if (Sprites.has('nguoi_ganh')) return _sprite(c, f, 'nguoi_ganh', 34, ph, down);
  shadow(c, f, 13, 2.6, .18);
  _local(c, f, down, () {
    final b = _bob(ph);
    final sway = math.sin(ph * .5) * 1.2;
    final pole = -16.5 - b;
    void basket(double x) {
      final top = Offset(x + sway * .3, pole);
      final bot = Offset(x + sway, -5.5 - b * .3);
      line(c, top + const Offset(-2.5, 0), bot + const Offset(-3, -3), withA(_ink, .7), .6);
      line(c, top + const Offset(2.5, 0), bot + const Offset(3, -3), withA(_ink, .7), .6);
      if (rice) {
        oval(c, bot + const Offset(0, -3.6), 3.6, 2.2, const Color(0xFFE8B931));
      } else {
        circle(c, bot + const Offset(-1.4, -3.6), 1.9, const Color(0xFF5E9E3A));
        circle(c, bot + const Offset(1.4, -3.8), 2.1, const Color(0xFF79B84A));
      }
      final q = [bot + const Offset(-4, -3), bot + const Offset(4, -3), bot + const Offset(3, 1), bot + const Offset(-3, 1)];
      fillPoly(c, q, const Color(0xFFB98A50));
      line(c, bot + const Offset(-3.6, -1), bot + const Offset(3.6, -1), const Color(0xFF8A6235), .6);
      strokePoly(c, q, _ink, .7);
    }

    basket(-12);
    _legs(c, ph);
    _upper(c, Offset(0, -8 - b), shirt: shirt, front: down, hands: [Offset(-4, pole + 1.5), Offset(4.5, pole + 1.5)]);
    final bend = Path()
      ..moveTo(-13, pole + .6)
      ..quadraticBezierTo(0, pole - 1.8 + b, 13, pole + .6);
    pathStroke(c, bend, const Color(0xFF9C7A3C), 1.6);
    basket(12);
  });
}

/// A girl on a bicycle with a basket of flowers.
void _cyclist(Canvas c, Offset f, double t, bool down, Color shirt) {
  if (Sprites.has('nguoi_xe_dap')) return _sprite(c, f, 'nguoi_xe_dap', 30, t * 9, down, bob: .3, skew: .3);
  shadow(c, f, 14, 2.6, .18);
  _local(c, f, down, () {
    const r = 4.6, rear = Offset(-7.5, -4.6), fr = Offset(7.5, -4.6);
    const frame = Color(0xFF2E7D6B);
    final spin = t * 7;
    for (final w in [rear, fr]) {
      for (var i = 0; i < 3; i++) {
        final a = spin + i * math.pi / 3;
        line(c, w + Offset(math.cos(a), math.sin(a)) * r, w - Offset(math.cos(a), math.sin(a)) * r, withA(_ink, .45), .5);
      }
      ovalStroke(c, w, r, r, const Color(0xFF2A2A2A), 1.4);
    }
    const seat = Offset(-2.2, -12), pedal = Offset(-.4, -4.8), bar = Offset(5.6, -14);
    for (final s in [
      [rear, seat],
      [seat, pedal],
      [pedal, rear],
      [pedal, const Offset(5, -11)],
      [const Offset(-2, -10.5), const Offset(5, -11)],
      [bar, fr],
    ]) {
      line(c, s[0], s[1], frame, 1.3);
    }
    line(c, bar, bar + const Offset(-2.4, -.8), const Color(0xFF2A2A2A), 1.2);
    // pedalling legs
    final a = t * 7;
    final k1 = pedal + Offset(math.cos(a), math.sin(a)) * 2.6, k2 = pedal - Offset(math.cos(a), math.sin(a)) * 2.6;
    const hip = Offset(-2.2, -13.5);
    for (final (p, col) in [(k2, const Color(0xFF2E2A2A)), (k1, const Color(0xFF3B3430))]) {
      final knee = Offset.lerp(hip, p, .5)! + const Offset(2.2, -1.5);
      line(c, hip, knee, col, 2.3);
      line(c, knee, p, col, 2.1);
    }
    _upper(c, hip, shirt: shirt, front: down, hands: [bar + const Offset(-2, -.2), bar + const Offset(-1.4, .2)], lean: .2);
    // basket of flowers
    final q = [const Offset(6.2, -16.5), const Offset(11.2, -16.5), const Offset(10.6, -13), const Offset(6.8, -13)];
    for (final (p, col) in [
      (const Offset(7.4, -17.4), const Color(0xFFF48FB1)),
      (const Offset(9.6, -17.8), const Color(0xFFFFE066)),
      (const Offset(8.6, -18.6), const Color(0xFFFFFFFF)),
    ]) {
      circle(c, p, 1.4, col);
    }
    fillPoly(c, q, const Color(0xFFC79A5B));
    strokePoly(c, q, _ink, .7);
  });
}

/// A boy riding a buffalo, playing the bamboo flute.
void _buffaloBoy(Canvas c, Offset f, double t, double ph, bool down) {
  final step = math.sin(ph * .5);
  const w = 34.0;
  final img = Sprites.image('trau');
  final back = img != null ? w * img.height / img.width * .7 : 17.0;
  c.save();
  c.translate(f.dx, f.dy);
  c.rotate(step * .02);
  if (img == null || !Sprites.at(c, 'trau', Offset.zero, w, flipX: !down)) {
    drawAnimal(c, 'trau', Offset.zero, down ? -1 : 1, t, 0);
  }
  c.restore();
  final seat = f + Offset(down ? 2 : -2, -back + step.abs() * .6);
  if (Sprites.has('be_thoi_sao')) {
    Sprites.at(c, 'be_thoi_sao', seat + const Offset(0, 6), 18, flipX: !down);
  } else {
    _local(c, seat, down, () {
      // legs astride, dangling down the side
      line(c, const Offset(-1, -1), const Offset(1.5, 4), const Color(0xFF3B3430), 2.2);
      _upper(c, const Offset(0, -1), shirt: const Color(0xFFF3EFE4), front: down, hat: false, hands: [
        const Offset(4.5, -11.2),
        const Offset(6.5, -11),
      ]);
      line(c, const Offset(2.8, -11.8), const Offset(10.5, -10.6), const Color(0xFFBFA05A), 1.1); // sáo
    }, .9 / _people);
  }
  final n = (t * .45) % 1;
  if (((t * .45).floor() % 2) == 0) {
    text(c, n < .5 ? '♪' : '♫', seat + Offset((down ? -1 : 1) * (8 + n * 6), -18 - n * 14), 7 + n * 2,
        color: Color.fromRGBO(255, 255, 255, (1 - n) * .95), weight: FontWeight.w900);
  }
}

/// The duck herder (người chăn vịt) with his long bamboo pole.
void _herder(Canvas c, Offset f, double t, double ph, bool down, Color shirt) {
  if (Sprites.has('nguoi_chan_vit')) return _sprite(c, f, 'nguoi_chan_vit', 32, ph, down);
  shadow(c, f, 6, 2, .2);
  _local(c, f, down, () {
    final b = _bob(ph);
    final wave = math.sin(t * 1.4) * 1.5;
    final hand = Offset(4, -14 - b);
    final tip = Offset(17 + wave, -31 - b);
    _legs(c, ph);
    _upper(c, Offset(0, -8 - b), shirt: shirt, front: down, hands: [Offset(2.5, -12 - b), hand]);
    line(c, hand + const Offset(-3, 2.5), tip, const Color(0xFFB59A55), 1.2);
    // a strip of cloth on the tip, fluttering
    final fl = math.sin(t * 6) * 1.2;
    fillPoly(c, [tip, tip + Offset(5, 1 + fl), tip + Offset(4.4, 3 + fl), tip + const Offset(-.4, 2.4)], const Color(0xFFE53935));
  });
}

void _walkingDuck(Canvas c, Offset f, double t, double i, bool down) {
  final step = math.sin(t * 9 + i * 1.7);
  final p = f - Offset(0, step.abs() * 1.2);
  c.save();
  c.translate(p.dx, p.dy);
  c.rotate(step * .08);
  if (!Sprites.at(c, 'vit', Offset.zero, 15, flipX: !down)) drawAnimal(c, 'vit', Offset.zero, down ? -1 : 1, t, i);
  c.restore();
}

void _kid(Canvas c, Offset f, double ph, bool left, bool front, Color shirt, {bool wave = false}) {
  final key = wave ? 'tre_chay' : 'tre_tha_dieu';
  if (Sprites.has(key)) return _sprite(c, f, key, 24, ph, front);
  shadow(c, f, 4.5, 1.6, .2);
  _local(c, f, left, () {
    final b = _bob(ph) * 1.4;
    _legs(c, ph, len: 6.5, pants: const Color(0xFF41506B));
    final armUp = wave ? Offset(5 + math.sin(ph * 1.3) * 1.5, -17 - b) : Offset(4, -9 - b);
    _upper(c, Offset(0, -6.5 - b), shirt: shirt, front: front, hat: false, hands: [Offset(-3.5 - math.sin(ph) * 2, -8 - b), armUp]);
  }, .78);
}

/// A kid running with a kite on a long string.
void _kiteKid(Canvas c, Offset f, double t, double ph, bool down, Color shirt) {
  _kid(c, f, ph, down, down, shirt);
  final s = down ? -1.0 : 1.0;
  // the painted kid holds the string up behind; the drawn one in front
  final hand = Sprites.has('tre_tha_dieu') ? f + Offset(-s * 6, -22) : f + Offset(s * 3.2, -9);
  // the kite streams out behind, high up
  final kite = f + Offset(-s * (34 + math.sin(t * .7) * 6), -96 + math.sin(t * 1.1) * 7);
  final string = Path()
    ..moveTo(hand.dx, hand.dy)
    ..quadraticBezierTo((hand.dx + kite.dx) / 2 + s * 4, (hand.dy + kite.dy) / 2 + 14, kite.dx, kite.dy + 6);
  pathStroke(c, string, const Color(0x99FFFFFF), .6);
  c.save();
  c.translate(kite.dx, kite.dy);
  c.rotate(math.sin(t * 1.6) * .18 - s * .15);
  final d = [const Offset(0, -9), const Offset(7, 0), const Offset(0, 7), const Offset(-7, 0)];
  fillPoly(c, d, const Color(0xFFE53935));
  fillPoly(c, [d[0], d[1], Offset.zero], const Color(0xFFFFD54F));
  fillPoly(c, [d[2], d[3], Offset.zero], const Color(0xFFFFD54F));
  line(c, d[0], d[2], _ink, .6);
  line(c, d[1], d[3], _ink, .6);
  strokePoly(c, d, _ink, .8);
  // tail of little bows
  var p = d[2];
  for (var i = 1; i <= 5; i++) {
    final q = Offset(math.sin(t * 3 + i) * 2.5 + s * i * .8, 7.0 + i * 5);
    line(c, p, q, const Color(0xFFFFFFFF), .6);
    fillPoly(c, [q + const Offset(-2, -1), q + const Offset(2, 1), q + const Offset(2, -1), q + const Offset(-2, 1)],
        i.isOdd ? const Color(0xFFFFD54F) : const Color(0xFFE53935));
    p = q;
  }
  c.restore();
}

/// A painted person sprite (faces lower-left like the animals), with a
/// walking bob since it is a single frame.
/// [down]: walking down the road (screen left), where a sprite drawn
/// facing left needs no flip (tweaks.json flips the ones drawn facing right).
void _sprite(Canvas c, Offset f, String key, double w, double ph, bool down, {double bob = 1, double skew = 0}) {
  shadow(c, f, w * .32, w * .08, .18);
  final s = math.sin(ph);
  c.save();
  c.translate(f.dx, f.dy - s.abs() * 1.2 * bob);
  // a side-on bicycle leans along the road: the road climbs to the right
  // on screen, so whichever way it goes the right wheel sits higher
  if (skew != 0) c.skew(0, -skew);
  c.rotate(s * .04 * bob);
  Sprites.at(c, key, Offset.zero, w, flipX: !down);
  c.restore();
}

// -------------------------------------------------------- field workers

/// One or two farmers tending growing fields that are on screen: bent
/// over transplanting in a paddy, hoeing a vegetable bed.
void _fieldWorkers(List<Actor> out, Farm farm, Iso iso, double t) {
  final fields = [
    for (final o in farm.objs)
      if ((o.def.kind == BKind.paddy || o.def.kind == BKind.bed) && o.crop != null) o,
  ];
  if (fields.isEmpty) return;
  final n = fields.length >= 6 ? 2 : 1;
  for (var w = 0; w < n; w++) {
    const period = 95.0;
    final lt = t + w * period / 2 + 300;
    final slot = (lt / period).floor();
    final u = lt - slot * period;
    final o = fields[(hash2(slot, 61 + w) * fields.length).floor() % fields.length];
    final fade = math.min(1.0, math.min(u, period - u) / 1.2);
    final paddy = o.def.kind == BKind.paddy;
    // drifts slowly along the front of the field
    final along = .25 + .5 * (.5 + .5 * math.sin(u * .09 + w));
    final gx = o.x + o.w * along, gy = o.y + o.h - .22;
    final f = iso.p(gx, gy);
    final shirt = _shirts[(slot + w * 3) % _shirts.length];
    final front = math.sin(u * .23 + w) > -.6;
    out.add(Actor(depthOf2(o) + .01, f, (c) {
      _faded(c, f, fade, () => paddy ? _planter(c, f, t, shirt, front) : _hoer(c, f, t, shirt, front));
    }));
  }
}

/// Same as farm_painter's depthOf (kept here to avoid an import cycle).
double depthOf2(Obj o) => ((o.x + o.w) + (o.y + o.h)).toDouble();

void _planter(Canvas c, Offset f, double t, Color shirt, bool front) {
  if (Sprites.has('nguoi_cay_lua')) return _sprite(c, f, 'nguoi_cay_lua', 27, t * 1.2, front, bob: .4);
  oval(c, f + const Offset(0, .5), 8, 2, const Color(0x33FFFFFF)); // ripple in the paddy water
  _local(c, f, front, () {
    final dip = (math.sin(t * 1.5) + 1) / 2; // reach down, stand a bit
    _legs(c, 0, walking: false, pants: const Color(0xFF3B3430));
    _upper(c, const Offset(0, -8), shirt: shirt, front: false, lean: .95 + dip * .35, hands: [
      Offset(6.5 + dip * 2, -2.5 + dip * 2),
      Offset(8 + dip * 2, -1.5 + dip * 2),
    ]);
    // a bunch of seedlings in the hand
    final h = Offset(8 + dip * 2, -1.5 + dip * 2);
    for (var i = -1; i <= 1; i++) {
      line(c, h, h + Offset(i * 1.5 + 1.5, -3.5), const Color(0xFF6DBE45), .8);
    }
  });
}

void _hoer(Canvas c, Offset f, double t, Color shirt, bool front) {
  if (Sprites.has('nguoi_cuoc_dat')) return _sprite(c, f, 'nguoi_cuoc_dat', 29, t * 1.6, front, bob: .4);
  shadow(c, f, 6, 2, .2);
  _local(c, f, front, () {
    // lift the hoe overhead, bring it down; a puff of soil on each blow
    final cyc = (t * .8) % 1;
    final a = cyc < .6 ? -1.9 + cyc / .6 * 1.2 : -.7 - (cyc - .6) / .4 * .9 + (cyc > .75 ? (cyc - .75) * 3.6 : 0);
    final grip = Offset(1.5 + math.cos(a) * 4, -15 + math.sin(a) * 4);
    final head = grip + Offset(math.cos(a + .3), math.sin(a + .3)) * 12;
    _legs(c, 0, walking: false, pants: const Color(0xFF3B3430));
    _upper(c, const Offset(0, -8), shirt: shirt, front: front, lean: .15, hands: [grip, grip + Offset(math.cos(a), math.sin(a)) * 3]);
    line(c, grip - Offset(math.cos(a), math.sin(a)) * 2, head, const Color(0xFF9C7A3C), 1.3);
    fillPoly(c, [head, head + Offset(math.cos(a + 1.6), math.sin(a + 1.6)) * 4.5, head + Offset(math.cos(a + .9), math.sin(a + .9)) * 4],
        const Color(0xFF8A8F96));
    if (cyc > .78 && cyc < .95) {
      final k = (cyc - .78) / .17;
      for (var i = 0; i < 3; i++) {
        circle(c, Offset(10 + i * 2.0, -1 - k * (3 + i)), 1.1 * (1 - k * .5), Color.fromRGBO(120, 85, 50, 1 - k));
      }
    }
  });
}

// ------------------------------------------------------------ the hens

class _Flock {
  int tx = -1, ty = -1, ntx = -1, nty = -1, seg = -1;
}

final _flocks = Expando<_Flock>('flock');
const _henSeg = 7.0, _henWalk = 2.4;

bool _free(Farm farm, int x, int y) =>
    x >= 0 && y >= 2 && x < mapSize && y < mapSize && farm.owned(x, y) && Farm.terrain(x, y) == 'grass' && farm.objAt(x, y) == null;

/// A hen and her chicks wander the free tiles around the house, one tile
/// at a time, pecking between steps.
void _hens(List<Actor> out, Farm farm, Iso iso, double t) {
  Obj? house;
  for (final o in farm.objs) {
    if (o.type == 'nha') house = o;
  }
  if (house == null) return;
  final hx = house.x + house.w / 2, hy = house.y + house.h / 2;
  final st = _flocks[farm] ??= _Flock();
  bool near(int x, int y) => (x + .5 - hx).abs() <= 4.5 && (y + .5 - hy).abs() <= 4.5;
  final seg = (t / _henSeg).floor();
  if (st.tx < 0 || !_free(farm, st.tx, st.ty) || !_free(farm, st.ntx, st.nty)) {
    // (re)start on the free tile closest to the door (lower-left face)
    (int, int)? best;
    var bd = 1e9;
    for (var y = house.y - 2; y <= house.y + house.h + 2; y++) {
      for (var x = house.x - 2; x <= house.x + house.w + 2; x++) {
        if (!_free(farm, x, y)) continue;
        final d = (x + .5 - hx).abs() + (y + .5 - house.y - house.h - .5).abs();
        if (d < bd) {
          bd = d;
          best = (x, y);
        }
      }
    }
    if (best == null) return;
    st
      ..tx = best.$1
      ..ty = best.$2
      ..ntx = best.$1
      ..nty = best.$2
      ..seg = seg;
  }
  if (seg != st.seg) {
    st
      ..tx = st.ntx
      ..ty = st.nty
      ..seg = seg;
    final opts = <(int, int)>[];
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final x = st.tx + dx, y = st.ty + dy;
      if (_free(farm, x, y) && near(x, y)) opts.add((x, y));
    }
    if (opts.isNotEmpty && hash2(seg, 71) < .8) {
      final p = opts[(hash2(seg, 72) * opts.length).floor() % opts.length];
      st
        ..ntx = p.$1
        ..nty = p.$2;
    }
  }
  final u = t - seg * _henSeg;
  Offset pos(double lag) {
    final k = ((u - lag) / _henWalk).clamp(0.0, 1.0);
    final e = k * k * (3 - 2 * k);
    return Offset(st.tx + .5 + (st.ntx - st.tx) * e, st.ty + .5 + (st.nty - st.ty) * e);
  }

  final dxScreen = (st.ntx - st.tx) - (st.nty - st.ty);
  final flip = dxScreen != 0 ? dxScreen > 0 : hash2(seg, 73) < .5;
  final walking = u < _henWalk;
  final hen = pos(0);
  final hf = iso.p(hen.dx, hen.dy);
  out.add(Actor(_depthAt(hen.dx, hen.dy), hf, (c) {
    final step = walking ? math.sin(u * 14) : 0.0;
    final peck = !walking && math.sin(u * 3.3) > .4;
    c.save();
    c.translate(hf.dx, hf.dy - step.abs() * 1.2);
    c.rotate(peck ? (flip ? .25 : -.25) : step * .06);
    if (!Sprites.at(c, 'ga', Offset.zero, 15, flipX: flip)) drawAnimal(c, 'ga', Offset.zero, flip ? 1 : -1, t, 0);
    c.restore();
  }));
  for (var i = 0; i < 4; i++) {
    final a = i * 1.6 + math.sin(t * .6 + i) * .5;
    final g = pos(.35 + i * .2) + Offset(math.cos(a), math.sin(a)) * (.28 + (i % 2) * .08);
    final cf = iso.p(g.dx, g.dy);
    final hop = math.max(0.0, math.sin(t * 5 + i * 2.3)) * 1.6;
    final left = math.sin(t * .8 + i * 1.9) < 0;
    out.add(Actor(_depthAt(g.dx, g.dy), cf, (c) => _chick(c, cf - Offset(0, hop), left, math.sin(t * 4 + i) > .7)));
  }
}

void _chick(Canvas c, Offset f, bool left, bool peck) {
  final s = left ? -1.0 : 1.0;
  shadow(c, f, 2.6, 1, .2);
  final b = f - const Offset(0, 2.6);
  oval(c, b, 2.6, 2.1, const Color(0xFFFFE066));
  final h = b + Offset(s * 1.9, peck ? .6 : -1.8);
  circle(c, h, 1.5, const Color(0xFFFFE780));
  fillPoly(c, [h + Offset(s * 1.2, -.3), h + Offset(s * 2.6, .2), h + Offset(s * 1.2, .7)], const Color(0xFFF08A24));
  circle(c, h + Offset(s * .5, -.4), .35, _ink);
}

// ------------------------------------------------------------ the water

/// A white duck leading four ducklings round the lotus lake.
void _lakeDucks(Canvas c, Iso iso, double t, Rect shown) {
  const cx = 29.5, cy = 29.5;
  if (!shown.contains(iso.p(cx, cy))) return;
  final base = t * .045;
  for (var i = 4; i >= 0; i--) {
    final th = base - i * .16;
    Offset at(double a) => Offset(cx + 2.05 * math.cos(a) + math.sin(a * 3) * .15, cy + 1.45 * math.sin(a));
    final g = at(th), g2 = at(th + .02);
    final p = iso.p(g.dx, g.dy), p2 = iso.p(g2.dx, g2.dy);
    final left = p2.dx < p.dx;
    final bob = math.sin(t * 2.2 + i) * .4;
    _swimDuck(c, p + Offset(0, bob), t, left, baby: i > 0);
  }
}

void _swimDuck(Canvas c, Offset p, double t, bool left, {required bool baby}) {
  final s = left ? -1.0 : 1.0, k = baby ? .85 : 1.5;
  // ripples spreading behind
  for (var r = 0; r < 2; r++) {
    final q = ((t * .7 + r * .5) % 1);
    ovalStroke(c, p + Offset(-s * q * 6 * k, .5), (5 + q * 7) * k, (1.8 + q * 2.4) * k, Color.fromRGBO(255, 255, 255, .45 * (1 - q)), .8);
  }
  final body = baby ? const Color(0xFFFFE066) : const Color(0xFFFAFAF5);
  final b = p - Offset(0, 2 * k);
  oval(c, b, 6 * k, 2.8 * k, body);
  fillPoly(c, [b + Offset(-s * 5 * k, -.5 * k), b + Offset(-s * 8 * k, -3 * k), b + Offset(-s * 4 * k, -2 * k)], body);
  ovalStroke(c, b, 6 * k, 2.8 * k, withA(_ink, .55), .6);
  final h = b + Offset(s * 4 * k, -4.6 * k);
  line(c, b + Offset(s * 3 * k, -1 * k), h, body, 2.6 * k);
  circle(c, h, 2.3 * k, body);
  fillPoly(c, [h + Offset(s * 1.6 * k, -.4 * k), h + Offset(s * 4.4 * k, .4 * k), h + Offset(s * 1.6 * k, 1.2 * k)], const Color(0xFFF08A24));
  circle(c, h + Offset(s * .6 * k, -.7 * k), .5, _ink);
}

/// A little sampan poled up and down the river east of the bridge.
void _boat(Canvas c, Iso iso, double t, Rect shown) {
  const x0 = 13.6, x1 = 34.8, y = 1.0;
  final cyc = (t / 150) % 1;
  final k = cyc < .5 ? cyc * 2 : 2 - cyc * 2;
  final e = k * k * (3 - 2 * k);
  final bx = x0 + (x1 - x0) * e;
  final fwd = cyc < .5 ? 1.0 : -1.0; // +x = down-right on screen
  if (!shown.contains(iso.p(bx, y))) return;
  final rock = math.sin(t * 1.8) * .6;
  // wake
  for (var r = 0; r < 3; r++) {
    final q = (t * .6 + r / 3) % 1;
    final w = iso.p(bx - fwd * (.7 + q * 1.2), y);
    ovalStroke(c, w, 6 + q * 10, 2 + q * 3, Color.fromRGBO(255, 255, 255, .35 * (1 - q)), .8);
  }
  List<Offset> hull(double z, double half, double wide) => [
        iso.p(bx - half, y, z),
        iso.p(bx - half * .65, y - wide, z),
        iso.p(bx + half * .65, y - wide, z),
        iso.p(bx + half, y, z),
        iso.p(bx + half * .65, y + wide, z),
        iso.p(bx - half * .65, y + wide, z),
      ];
  final lo = hull(0, .62, .17), hi = hull(4 + rock, .7, .22), inner = hull(3.4 + rock, .6, .15);
  fillPoly(c, lo, const Color(0xFF4E3524));
  // the hull's sides: join the waterline to the rim
  for (var i = 0; i < 6; i++) {
    final j = (i + 1) % 6;
    fillPoly(c, [lo[i], lo[j], hi[j], hi[i]], i >= 3 ? const Color(0xFF6D4A30) : const Color(0xFF5A3D28));
  }
  fillPoly(c, hi, const Color(0xFF8A6240));
  fillPoly(c, inner, const Color(0xFF3E2A1C));
  strokePoly(c, hi, _ink, .8);
  // a load of baskets in the middle
  final mid = iso.p(bx + fwd * .1, y, 3.5 + rock);
  oval(c, mid + const Offset(-3, -2), 3.4, 2.2, const Color(0xFFB98A50));
  oval(c, mid + const Offset(-3, -3.4), 2.6, 1.4, const Color(0xFF79B84A));
  oval(c, mid + const Offset(3, -1.5), 3.4, 2.2, const Color(0xFFB98A50));
  oval(c, mid + const Offset(3, -2.8), 2.6, 1.4, const Color(0xFFE8B931));
  // the boatman at the stern, poling
  final stern = iso.p(bx - fwd * .42, y, 3.6 + rock);
  final push = (math.sin(t * 1.1) + 1) / 2;
  final front = fwd < 0; // coming up the screen → facing us
  _local(c, stern, fwd < 0, () {
    _legs(c, 0, walking: false);
    final hand = Offset(4 + push * 2, -14);
    _upper(c, const Offset(0, -8), shirt: _shirts[0], front: front, lean: .1 + push * .12, hands: [hand + const Offset(-2, 2), hand]);
    line(c, hand + const Offset(-4, -9), hand + Offset(-1 - push * 7, 14), const Color(0xFFB59A55), 1.2);
  });
}
