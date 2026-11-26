// Lời qua tiếng lại: now and then a villager says something in a speech
// bubble — the trader calling from the landing, kids spotting the boat,
// a farmer hurrying when rain is coming. Lines follow what is going on in
// the village (trader docked, rain on the way, a dry spell, ripe fields, a
// festival, the time of day), mixed with everyday chatter. Show only: like
// life.dart, nothing here touches the game.
//
// life.dart calls [say] for each speaker as it is drawn; farm_painter
// draws the bubbles on top of everything with [drawChatter].

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../core/farm.dart';
import '../core/weather.dart';
import 'ground.dart' show hash2;

enum Speaker { trader, boatman, kid, buffaloBoy, carrier, cyclist, herder, farmer, hen }

/// What is going on, worked out once a frame by [chatterFrame].
class _Ctx {
  bool trader = false, traderLeaving = false, rainSoon = false, rain = false, drought = false, ripe = false;
  String? festival;
  int hour = 12;
}

final _ctx = _Ctx();

/// Each frame, before anything speaks.
void chatterFrame(Farm farm) {
  final now = farm.now();
  final w = weatherAt(now), ends = weatherEndsAt(now);
  _ctx
    ..trader = farm.traderHere
    ..traderLeaving = farm.traderHere && farm.traderMs < 10 * 60 * 1000
    ..rain = w == Weather.rain
    ..drought = w == Weather.drought
    ..rainSoon = w != Weather.rain && weatherAt(ends) == Weather.rain && ends - now < 45 * 60 * 1000
    ..ripe = farm.readyCount > 0
    ..festival = farm.festival?.def.name
    ..hour = DateTime.fromMillisecondsSinceEpoch(now).hour;
  _bubbles.clear();
}

/// Lines for [s] right now: the ones about what is happening (said more
/// often) and the everyday ones.
(List<String>, List<String>) _lines(Speaker s) {
  final c = _ctx;
  final morning = c.hour >= 5 && c.hour < 10, noon = c.hour >= 11 && c.hour < 14, evening = c.hour >= 17 && c.hour < 20;
  switch (s) {
    case Speaker.trader:
      return (
        [
          if (c.traderLeaving) ...['Ghe sắp nhổ neo rồi, ai bán gì lẹ lên nghen!', 'Chút nữa ghe đi rồi đó bà con ơi!'],
          'Ghe tới rồi, bà con có gì bán không?',
          'Mua lúa, mua gạo, mua trứng đây!',
          'Hàng ngon trả giá cao nghen bà con!',
          if (c.rain) 'Mưa cũng mua, bà con ra bến đi!',
        ],
        ['Ai bán gì hông?', 'Ghe hàng ghé bến đầu cầu nè!'],
      );
    case Speaker.boatman:
      return (
        [if (c.rainSoon) 'Mây đen kéo tới, chèo lẹ về thôi!', if (c.rain) 'Mưa ướt hết áo rồi nè!'],
        ['Ơ hò... ơ... hò...', 'Nước lớn rồi đó!', 'Chiều nay ghé chợ nổi.', 'Sông quê mát rượi!'],
      );
    case Speaker.kid:
      return (
        [
          if (c.trader) ...['Ghe thương lái tới kìa mấy bạn!', 'Ra bến coi ghe hàng đi!'],
          if (c.rainSoon) 'Sắp mưa rồi, thu diều về thôi!',
          if (c.rain) 'Mưa rồi, tắm mưa đi tụi bây!',
          if (c.festival != null) '${c.festival} vui quá trời!',
        ],
        [
          'Thả diều cao lên nữa!',
          'Ê, chờ tui với!',
          'Chiều nay đi tắm sông hông?',
          'Đi bắt cào cào đi!',
          if (noon) 'Trưa nay má nấu canh chua!',
        ],
      );
    case Speaker.buffaloBoy:
      return (
        [
          if (c.trader) 'Ghe thương lái tới kìa!',
          if (c.rainSoon) 'Trâu ơi, về chuồng lẹ, sắp mưa!',
          if (evening) 'Chiều rồi, dắt trâu về thôi.',
        ],
        ['Nghé ơi, đi chậm thôi!', 'Tò te... tò te...', 'Trâu ơi ta bảo trâu này...'],
      );
    case Speaker.carrier:
      return (
        [
          if (c.trader) 'Gánh hàng ra bến bán cho thương lái!',
          if (c.rainSoon) 'Trời sắp mưa, gánh lúa về lẹ!',
          if (c.drought) 'Nắng gì nắng dữ thần!',
          if (c.festival != null) 'Sắp tới ${c.festival}, đi chợ sắm đồ!',
        ],
        [
          'Gánh lúa về sân phơi đây!',
          'Nặng quá trời nặng!',
          if (morning) 'Sáng sớm ra đồng cho mát.',
          'Năm nay được mùa rồi!',
        ],
      );
    case Speaker.cyclist:
      return (
        [
          if (c.rainSoon) 'Đạp lẹ về kẻo mắc mưa!',
          if (c.trader) 'Ghe hàng tới bến rồi kìa!',
        ],
        ['Kính coong! Tránh đường nha!', 'Ra chợ huyện mua đồ đây!', if (morning) 'Đi học kẻo trễ!'],
      );
    case Speaker.herder:
      return (
        [if (c.rainSoon) 'Lùa vịt về, sắp mưa rồi!', if (c.rain) 'Vịt khoái mưa lắm nè!'],
        ['Vịt ơi, đi đúng hàng nào!', 'Bầy vịt năm nay mập ghê!', 'Cạp cạp... đi đi!'],
      );
    case Speaker.farmer:
      return (
        [
          if (c.rainSoon) ...['Trời sắp mưa rồi, gặt nhanh lên!', 'Mây đen kéo tới kìa bà con ơi!'],
          if (c.drought) 'Nắng hạn, ruộng nứt nẻ hết rồi!',
          if (c.rain) 'Mưa thuận gió hòa, lúa tốt!',
          if (c.ripe) 'Lúa chín vàng rồi, gặt thôi!',
          if (c.trader) 'Ghe thương lái tới, bán lúa được giá!',
        ],
        [
          'Cấy lúa phải cấy cho đều...',
          'Ai ơi bưng bát cơm đầy...',
          'Năm nay chắc được mùa!',
          if (noon) 'Trưa rồi, nghỉ tay ăn cơm thôi.',
          if (morning) 'Sáng nay sương nhiều ghê.',
        ],
      );
    case Speaker.hen:
      return ([if (c.rainSoon) 'Cục cục... vô chuồng!'], ['Cục ta cục tác!', 'Chiếp chiếp!', 'Cục cục... ăn thóc nè con!']);
  }
}

class _Bubble {
  final Offset at;
  final String text;
  final double a;
  const _Bubble(this.at, this.text, this.a);
}

final _bubbles = <_Bubble>[];

/// [s] (one person, told apart by [key]) stands with its head at [head]:
/// speaks for a few seconds now and then.
void say(Speaker s, int key, Offset head, double t) {
  // each speaker its own rhythm: a few seconds of talk every 12–24 s
  final cycle = 12 + hash2(key, 71) * 12, on = 4.2;
  final lt = t + hash2(key, 72) * cycle;
  final turn = (lt / cycle).floor();
  final u = lt - turn * cycle;
  if (u > on) return;
  final (now, every) = _lines(s);
  // the trader always has business; others often skip a turn
  if (s != Speaker.trader && hash2(key, turn, 73) < (now.isNotEmpty ? .15 : .4)) return;
  final pool = now.isNotEmpty && hash2(key, turn, 74) < .7 ? now : every;
  if (pool.isEmpty) return;
  final text = pool[(hash2(key, turn, 75) * pool.length).floor() % pool.length];
  final a = math.min(1.0, math.min(u, on - u) / .25);
  _bubbles.add(_Bubble(head, text, a));
}

final _tp = <String, TextPainter>{};

TextPainter _painter(String s) {
  final hit = _tp[s];
  if (hit != null) return hit;
  if (_tp.length > 120) _tp.clear();
  return _tp[s] = TextPainter(
    text: TextSpan(
        text: s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4A3426), height: 1.2)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 3,
  )..layout(maxWidth: 140);
}

/// The bubbles said this frame, over everything on the map (a few at
/// most, none on top of another). [zoom]: the map's scale; bubbles keep
/// about one size on screen so they read at any zoom.
void drawChatter(Canvas c, double zoom) {
  final shown = c.getLocalClipBounds();
  final k = (1 / zoom).clamp(.45, 1.9);
  final taken = <Rect>[];
  for (final b in _bubbles) {
    if (!shown.contains(b.at) || taken.length >= 4) continue;
    final tp = _painter(b.text);
    final w = tp.width + 16, h = tp.height + 10;
    // pops up a little as it appears
    final lift = (1 - b.a) * 6;
    final box = Rect.fromLTWH(-w / 2, -h - 8 + lift, w, h);
    final onMap = Rect.fromLTWH(b.at.dx + box.left * k, b.at.dy + box.top * k, w * k, h * k);
    if (taken.any((r) => r.overlaps(onMap))) continue;
    taken.add(onMap);
    c.save();
    c.translate(b.at.dx, b.at.dy);
    c.scale(k);
    final rr = RRect.fromRectAndRadius(box, const Radius.circular(9));
    final tail = Path()
      ..moveTo(-5, box.bottom - 1)
      ..lineTo(5, box.bottom - 1)
      ..lineTo(-1, box.bottom + 7)
      ..close();
    c.saveLayer(box.inflate(12), Paint()..color = Color.fromRGBO(0, 0, 0, b.a));
    c.drawRRect(rr.shift(const Offset(1, 2)), Paint()..color = const Color(0x33000000));
    final fill = Paint()..color = const Color(0xFFFFFDF5);
    c.drawRRect(rr, fill);
    c.drawPath(tail, fill);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFB89A68);
    c.drawRRect(rr, edge);
    tp.paint(c, Offset(box.left + 8, box.top + 5));
    c.restore();
    c.restore();
  }
}
