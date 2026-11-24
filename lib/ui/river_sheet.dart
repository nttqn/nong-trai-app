// 🎣 Câu cá ngoài sông: cast, wait for the float to bob, strike, then stop
// the sweeping marker inside the green band to land the catch. The rules
// and the roll are in core/farm_river.dart.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/farm.dart';
import '../render/sprites.dart';
import '../services/ads.dart';
import '../services/sound.dart';
import '../services/week_board.dart';
import 'board_view.dart';
import 'sheets.dart' show Report;
import 'week_sheet.dart' show fmtDays;
import 'widgets.dart';

enum _St { ready, waiting, bite, reel, result }

class RiverSheet extends StatefulWidget {
  final Farm farm;
  final Report report;
  const RiverSheet(this.farm, this.report, {super.key});
  @override
  State<RiverSheet> createState() => _RiverSheetState();
}

class _RiverSheetState extends State<RiverSheet> with SingleTickerProviderStateMixin {
  Farm get f => widget.farm;
  late final Ticker _ticker;
  final _t = ValueNotifier(0.0);
  _St _st = _St.ready;
  RiverBite? _bite;
  double _biteAt = 0, _stateAt = 0, _zoneAt = .5;
  late String _msg = f.riverFun ? 'Chạm "Câu giải trí" rồi chờ phao động.' : 'Chạm "Thả câu" rồi chờ phao động.';
  bool _good = true;
  final _rng = math.Random();

  static const _biteWindow = 1.0, _reelTimeout = 6.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) {
      _t.value = e.inMicroseconds / 1e6;
      _step();
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _set(_St s) {
    _st = s;
    _stateAt = _t.value;
    if (mounted) setState(() {});
  }

  void _step() {
    final t = _t.value;
    if (_st == _St.waiting && t >= _biteAt) {
      HapticFeedback.mediumImpact();
      SoundService.instance.play('splash', volume: .6);
      _set(_St.bite);
    } else if (_st == _St.bite && t - _stateAt > _biteWindow) {
      _lose('Cá rỉa mồi rồi bỏ đi mất! Thấy phao chìm thì giật ngay nhé.');
    } else if (_st == _St.reel && t - _stateAt > _reelTimeout) {
      _lose('Cá vùng vẫy rồi sổng mất!');
    }
  }

  void _cast() {
    final (b, err) = f.cast();
    if (err != null) {
      widget.report(err);
      return;
    }
    SoundService.instance.play('splash', volume: .5);
    _bite = b;
    _biteAt = _t.value + 1.6 + _rng.nextDouble() * 3.2;
    _msg = 'Đang chờ cá cắn câu...';
    _good = true;
    _set(_St.waiting);
  }

  /// The one big tap: strike while waiting/biting, stop the marker reeling.
  void _strike() {
    switch (_st) {
      case _St.waiting:
        _lose('Giật sớm quá, cá sợ chạy mất!');
      case _St.bite:
        HapticFeedback.selectionClick();
        _zoneAt = .25 + _rng.nextDouble() * .5;
        _msg = 'Cá mắc câu! Chạm khi kim nằm trong vạch xanh.';
        _set(_St.reel);
      case _St.reel:
        final b = _bite!;
        final m = _marker(_t.value - _stateAt, b.speed);
        if ((m - _zoneAt).abs() <= b.zone / 2) {
          _land(b);
        } else {
          _lose('Trượt rồi, cá sổng mất!');
        }
      default:
    }
  }

  /// Marker position 0..1 sweeping back and forth.
  static double _marker(double t, double speed) {
    final p = (t * speed) % 2;
    return p <= 1 ? p : 2 - p;
  }

  void _land(RiverBite b) {
    final err = f.landBite(b);
    if (err != null) {
      _msg = err;
      _good = false;
    } else {
      HapticFeedback.mediumImpact();
      final pts = b.pts > 0 ? ' (+${b.pts} điểm đua top)' : '';
      final sold = f.lastFunCoins > 0 ? 'bán ngay tại bờ +${fmtNum(f.lastFunCoins)} xu' : 'thả lại sông';
      _msg = b.fun
          ? switch (b.kind) {
              BiteKind.fish => 'Câu được ${b.qty} ${b.name.toLowerCase()} ${b.icon}, $sold$pts',
              _ =>
                '${b.icon} Vớt được ${b.name.toLowerCase()}... ${f.lastFunCoins > 0 ? 'bán được ${f.lastFunCoins} xu' : 'vứt đi thôi'} 😅',
            }
          : switch (b.kind) {
              BiteKind.fish => 'Câu được ${b.qty} ${b.name.toLowerCase()}! ${b.icon}$pts',
              BiteKind.junk => '${b.icon} Vớt được ${b.name.toLowerCase()}... bán đồng nát được ${f.junkCoins} xu 😅',
              BiteKind.coins => '${b.icon} Vớt được hũ tiền cổ: +${fmtNum(b.qty)} xu!',
              BiteKind.ticket => '${b.icon} Vớt được hộp gỗ: +${b.qty} Vé Xong ngay!',
            };
      _good = true;
    }
    _set(_St.result);
  }

  void _lose(String why) {
    f.lostBite();
    _msg = why;
    _good = false;
    _set(_St.result);
  }

  @override
  Widget build(BuildContext context) {
    final casts = f.riverCasts;
    return Column(
      children: [
        SheetHeader(
          '🎣 Câu cá',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                casts > 0 ? 'Còn $casts lượt' : 'Câu giải trí',
                style: const TextStyle(fontWeight: FontWeight.w900, color: brown),
              ),
              const SizedBox(width: 6),
              PillButton(
                '🏆 Đua top',
                dense: true,
                color: gold,
                onTap: () {
                  showFarmSheet(context, (_) => FishBoardSheet(f), height: .86).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Text(
            'Điểm đua top câu cá tuần này: ${fmtNum(f.fishWeek == f.weekNow ? f.fishPts : 0)}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFD84315)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _strike(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(painter: _RiverPainter(this), child: const SizedBox.expand()),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text(
            _msg,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _good ? brown : const Color(0xFFB23B32)),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: _actions(casts)),
      ],
    );
  }

  Widget _actions(int casts) {
    if (_st == _St.waiting || _st == _St.bite || _st == _St.reel) {
      return PillButton(
        _st == _St.reel ? '🎯 Kéo lên!' : '🎣 Giật cần!',
        color: const Color(0xFF1E88E5),
        onTap: _strike,
      );
    }
    if (casts > 0) return PillButton('🎣 Thả câu', onTap: _cast);
    final left = f.riverFunLeft;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          left > 0
              ? 'Hết lượt chính hôm nay. Vẫn câu thoải mái: cá bán ngay tại bờ (còn tối đa ${fmtNum(left)} xu hôm nay), vẫn tính điểm đua top.'
              : 'Hết lượt chính hôm nay. Vẫn câu thoải mái để lấy điểm đua top (hôm nay đã bán đủ cá).',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: brownLight, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            PillButton('🎣 Câu giải trí', onTap: _cast),
            if (f.riverAdLeft)
              ValueListenableBuilder<bool>(
                valueListenable: AdsService.instance.rewardedReady,
                builder: (_, ready, _) => ready
                    ? PillButton(
                        '📺 Thêm ${FarmRiver.riverAdCasts} lượt',
                        color: gold,
                        onTap: () async {
                          if (await AdsService.instance.showRewarded('river_casts')) {
                            f.riverAdGranted();
                            if (mounted) setState(() => _msg = 'Thêm ${FarmRiver.riverAdCasts} lượt câu!');
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ],
    );
  }
}

/// 🏆 Đua top câu cá: this week's fishing points board and its prizes.
class FishBoardSheet extends StatelessWidget {
  final Farm farm;
  const FishBoardSheet(this.farm, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SheetHeader('🏆 Đua top câu cá'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: cardDeco(color: const Color(0xFFE3F2FD)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mỗi con cá câu ngoài sông được điểm, cá càng khó càng nhiều điểm: '
                      'rô phi 1 · trắm 2 · chép 3 · tôm 3 · lươn 5 · cá quả 6. Hũ tiền, hộp gỗ 2 điểm. '
                      'Câu giải trí (hết lượt chính) cũng tính điểm.',
                      style: TextStyle(color: brown, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Điểm tuần này: ${fmtNum(farm.fishWeek == farm.weekNow ? farm.fishPts : 0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFD84315)),
                        ),
                        const Spacer(),
                        Ticking(
                          const Duration(minutes: 1),
                          builder: (_) => Text(
                            'Còn ${fmtDays(farm.weekEndsIn)}',
                            style: const TextStyle(fontSize: 12.5, color: brownLight, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              RankPrizeList(farm),
              const SizedBox(height: 10),
              const Text(
                '🏆 Bảng xếp hạng câu cá tuần',
                style: TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15.5),
              ),
              const SizedBox(height: 4),
              BoardList(farm, WeekBoard.fishing, firstHint: 'Câu con cá đầu tiên tuần này để có tên trên bảng.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiverPainter extends CustomPainter {
  final _RiverSheetState s;
  _RiverPainter(this.s) : super(repaint: s._t);

  @override
  void paint(Canvas c, Size size) {
    final t = s._t.value;
    final w = size.width, h = size.height;
    // water with drifting light streaks, the far bank at the top, reeds at the near bank
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7CC0D8), Color(0xFF3F8FB0), Color(0xFF2F7695)],
        ).createShader(Offset.zero & size),
    );
    c.drawRect(Rect.fromLTWH(0, 0, w, h * .12), Paint()..color = const Color(0xFF7FAE4A));
    final bamboo = Paint()..color = const Color(0xFF5E9E3E);
    for (var i = 0; i < 9; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(w * (i + .5) / 9, h * .12), width: w / 7, height: h * .06), bamboo);
    }
    final streak = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final y = h * (.2 + (i * .057) % .7);
      final x = ((i * 97.0 + t * (14 + i % 5 * 4)) % (w + 80)) - 40;
      c.drawLine(Offset(x, y), Offset(x + 26 + (i % 3) * 10, y), streak);
    }
    final reed = Paint()
      ..color = const Color(0xFF4E8B32)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final x = w * i / 11;
      c.drawLine(Offset(x, h), Offset(x + math.sin(t * 1.3 + i) * 4 - 6 + (i % 3) * 5, h - 40 - (i % 4) * 12), reed);
    }

    // the float
    final st = s._st;
    final fl = Offset(w * .5, h * .5);
    var dip = math.sin(t * 2.2) * 2.0;
    if (st == _St.waiting && s._biteAt - t < 1.2) dip += math.sin(t * 14) * 2; // nibbles
    if (st == _St.bite) dip = 9 + math.sin(t * 20) * 3;
    if (st == _St.reel) dip = 12 + math.sin(t * 9) * 4;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    if (st != _St.ready && st != _St.result) {
      for (var i = 0; i < 3; i++) {
        final k = ((t * (st == _St.bite ? 1.6 : .6)) + i / 3) % 1;
        ring.color = Colors.white.withValues(alpha: (1 - k) * .55);
        c.drawOval(Rect.fromCenter(center: fl + const Offset(0, 4), width: 18 + k * 70, height: 8 + k * 26), ring);
      }
      // the line from the rod tip off the bottom right
      c.drawLine(
        Offset(w + 10, h * .82),
        fl + Offset(0, dip - 16),
        Paint()
          ..color = const Color(0xCCFFFFFF)
          ..strokeWidth = 1.1,
      );
      final body = fl + Offset(0, dip);
      c.drawOval(Rect.fromCenter(center: body, width: 12, height: 18), Paint()..color = const Color(0xFFFFFDF5));
      c.drawOval(
        Rect.fromCenter(center: body - const Offset(0, 5), width: 12, height: 9),
        Paint()..color = const Color(0xFFE53935),
      );
      c.drawLine(
        body - const Offset(0, 9),
        body - const Offset(0, 18),
        Paint()
          ..color = const Color(0xFFE53935)
          ..strokeWidth = 2,
      );
      if (st == _St.bite) {
        _text(c, '!', fl + const Offset(24, -34), 34, const Color(0xFFFFEB3B));
      }
    } else {
      _text(c, '🎣', fl, 54, Colors.white);
    }

    // the reel bar: green band and the sweeping marker
    if (st == _St.reel) {
      final b = s._bite!;
      final bar = Rect.fromLTWH(w * .1, h * .78, w * .8, 22);
      final rr = RRect.fromRectAndRadius(bar, const Radius.circular(11));
      c.drawRRect(rr, Paint()..color = const Color(0xCC3E2723));
      final z0 = bar.left + bar.width * (s._zoneAt - b.zone / 2), z1 = bar.left + bar.width * (s._zoneAt + b.zone / 2);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(z0, bar.top + 3, z1, bar.bottom - 3), const Radius.circular(8)),
        Paint()..color = const Color(0xFF66BB6A),
      );
      final m = bar.left + bar.width * _RiverSheetState._marker(t - s._stateAt, b.speed);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(m, bar.center.dy), width: 7, height: 34),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFFFEB3B),
      );
      final left = (_RiverSheetState._reelTimeout - (t - s._stateAt)).clamp(0.0, _RiverSheetState._reelTimeout);
      c.drawRect(
        Rect.fromLTWH(bar.left, bar.bottom + 8, bar.width * left / _RiverSheetState._reelTimeout, 4),
        Paint()..color = const Color(0x99FFFFFF),
      );
    }
    if (st == _St.result && s._good && s._bite != null) {
      final at = fl + Offset(0, -10 - math.sin((t - s._stateAt).clamp(0, 1.5) * 2) * 30);
      // the item's painted icon (batch 7 art) when there is one, else its emoji
      final it = s._bite!.item, img = it == null ? null : Sprites.image('item_$it');
      if (img != null) {
        c.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromCenter(center: at, width: 64, height: 64 * img.height / img.width),
          Paint()..filterQuality = FilterQuality.medium,
        );
      } else {
        _text(c, s._bite!.icon, at, 46, Colors.white);
      }
    }
  }

  void _text(Canvas c, String s, Offset at, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: size, color: col, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RiverPainter old) => true;
}
