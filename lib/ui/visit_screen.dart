// Ghé thăm hàng xóm: a neighbour's farm, read-only. Ripe things can be
// harvested for them (thu hoạch hộ, rewards the visitor) or one item can
// be picked on the sly (hái trộm), which a scarecrow may catch.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/achievements.dart';
import '../core/defs.dart';
import '../core/farm.dart';
import '../render/farm_painter.dart';
import '../services/neighbors.dart';
import '../services/sound.dart';
import 'market_ui.dart';
import 'widgets.dart';

class VisitScreen extends StatefulWidget {
  final Farm me, neighbor;
  final String uid, name;
  /// Achievement id of the neighbour's title (danh hiệu), or empty.
  final String title;

  /// No server (dev screenshots): actions only change the screen.
  final bool offline;
  const VisitScreen({super.key, required this.me, required this.neighbor, required this.uid, required this.name, this.title = '', this.offline = false});
  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _clock = ValueNotifier(0.0);
  final _view = ViewState()..visiting = true;
  final _cache = GroundCache();
  final _tc = TransformationController();
  final _rng = math.Random();
  bool _placed = false, _busy = false;
  Obj? _sel;
  String? _toast;
  bool _toastErr = false;
  Timer? _toastTimer;

  Farm get nb => widget.neighbor;
  Farm get me => widget.me;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) {
      _clock.value = e.inMicroseconds / 1e6;
      if (nb.fx.isNotEmpty) {
        for (final f in nb.fx) {
          _view.floats.add(FloatFx(f, _clock.value));
        }
        nb.fx.clear();
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _say(String s, {bool error = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toast = s;
      _toastErr = error;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _toast = null);
    });
    if (error) SoundService.instance.play('error');
  }

  void _place(Size s) {
    if (_placed || s.isEmpty) return;
    _placed = true;
    final scale = (s.width / 560).clamp(.55, 1.3);
    final focus = worldIso.p(12, 9);
    _tc.value = Matrix4.identity()
      ..translateByDouble(s.width / 2 - focus.dx * scale, s.height * .46 - focus.dy * scale, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _tap(Offset p) {
    final o = hitTest(nb, p, _view);
    if (o == null || nb.readyProduct(o) == null) {
      setState(() => _sel = null);
      if (o != null && o.def.kind != BKind.obstacle) _say('${o.def.name} chưa có gì để thu hoạch');
      return;
    }
    SoundService.instance.play('tap');
    setState(() => _sel = o);
  }

  Future<bool> _send(String kind, Obj o, String product, {int fine = 0}) async {
    if (widget.offline) return true;
    return Neighbors.instance.send(widget.uid, kind, o, product, fine: fine);
  }

  Future<void> _help(Obj o) async {
    final product = nb.readyProduct(o);
    if (product == null || _busy) return;
    if (me.visitCount(widget.uid, 'help') >= Farm.helpLimit) {
      return _say('Hôm nay đã giúp nhà này đủ ${Farm.helpLimit} lần', error: true);
    }
    setState(() => _busy = true);
    final ok = await _send('help', o, product);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return _say('Không gửi được, có thể bạn đã giúp chỗ này rồi', error: true);
    final (x, c) = me.helpReward(product);
    me.rewardHelp(widget.uid, product);
    nb.harvestAny(o); // on this copy only: shows it as done
    setState(() => _sel = null);
    _say('Cảm ơn bạn! +$x KN, +$c xu');
  }

  Future<void> _steal(Obj o) async {
    final product = nb.readyProduct(o);
    if (product == null || _busy) return;
    if (!nb.canBeStolen(o)) return _say('Chỉ còn ít quá, để lại cho chủ nhà thôi!', error: true);
    if (me.visitCount(widget.uid, 'steal') >= Farm.stealLimit) {
      return _say('Hôm nay đã hái trộm nhà này đủ ${Farm.stealLimit} lần', error: true);
    }
    if (!me.roomFor(1)) return _say('Kho nhà mình đầy rồi!', error: true);
    setState(() => _busy = true);
    if (Neighbors.caught(nb.catchChance, _rng)) {
      final fine = math.min(me.coins, me.stealFine);
      final ok = await _send('caught', o, product, fine: fine);
      if (!mounted) return;
      setState(() => _busy = false);
      if (!ok) return _say('Không gửi được, thử lại sau', error: true);
      me.payFine(widget.uid);
      setState(() => _sel = null);
      final dog = nb.dog;
      _say('${dog != null && nb.dogAwake(dog) ? '🐕 Chó sủa ầm lên, chủ nhà' : '🪧 Bù nhìn'} bắt quả tang! Nộp phạt ${fmtNum(fine)} xu',
          error: true);
      return;
    }
    final ok = await _send('steal', o, product);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return _say('Bạn đã hái chỗ này rồi', error: true);
    me.takeStolen(widget.uid, product);
    o.stolen++;
    setState(() => _sel = null);
    _say('Hái được 1 ${item(product).name.toLowerCase()} ${item(product).icon} — suỵt!');
  }

  @override
  Widget build(BuildContext context) {
    final helps = me.visitCount(widget.uid, 'help'), steals = me.visitCount(widget.uid, 'steal');
    return Scaffold(
      backgroundColor: const Color(0xFF9FCB63),
      body: LayoutBuilder(builder: (context, cons) {
        _place(cons.biggest);
        return Stack(children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _tc,
              constrained: false,
              minScale: .4,
              maxScale: 2.6,
              boundaryMargin: const EdgeInsets.all(60),
              child: GestureDetector(
                onTapUp: (d) => _tap(d.localPosition),
                child: CustomPaint(size: const Size(worldW, worldH), painter: FarmPainter(nb, _view, _clock, _cache)),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            top: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 6),
                decoration: cardDeco(),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: brown),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text('🏡 ${widget.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 16)),
                      if (achById(widget.title) != null)
                        Text('${achById(widget.title)!.icon} ${achById(widget.title)!.title}',
                            style: const TextStyle(color: Color(0xFFD84315), fontSize: 12, fontWeight: FontWeight.w900)),
                      Text('Cấp ${nb.level} · 🤝 $helps/${Farm.helpLimit} · 🧺 $steals/${Farm.stealLimit} hôm nay',
                          style: const TextStyle(color: brownLight, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  if (me.level >= FarmMore.marketLevel && !widget.offline)
                    IconButton(
                      tooltip: 'Sạp chợ của nhà này',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MarketScreen(me, owner: widget.uid, ownerName: widget.name)),
                      ),
                      icon: const Text('🛒', style: TextStyle(fontSize: 22)),
                    ),
                ]),
              ),
            ),
          ),
          if (_toast != null)
            Positioned(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 84,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _toastErr ? const Color(0xF2B23B32) : const Color(0xF23F7A1C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(_toast!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 0,
            child: SafeArea(top: false, child: _sel == null ? _hint() : _actions(_sel!)),
          ),
        ]);
      }),
    );
  }

  Widget _hint() => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: cardDeco(),
        child: const Text(
          'Chạm vào chỗ đã chín (có bong bóng) để thu hoạch hộ hoặc hái trộm. Cẩn thận bù nhìn và chó giữ nhà!',
          style: TextStyle(color: brown, fontWeight: FontWeight.w600),
        ),
      );

  Widget _actions(Obj o) {
    final product = nb.readyProduct(o);
    if (product == null) return _hint();
    final (x, c) = me.helpReward(product);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 12),
      decoration: cardDeco(),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ItemIcon(product, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${o.def.name}: ${nb.readyYield(o)} ${item(product).name.toLowerCase()} đã chín',
                style: const TextStyle(fontWeight: FontWeight.w900, color: brown)),
          ),
          IconButton(onPressed: () => setState(() => _sel = null), icon: const Icon(Icons.close_rounded, color: brownLight)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          PillButton(_busy ? '…' : '🤝 Thu hoạch hộ (+$x KN, +$c xu)', onTap: _busy ? null : () => _help(o)),
          PillButton(_busy ? '…' : '🧺 Hái trộm 1',
              color: const Color(0xFF8D6E4C), onTap: _busy ? null : () => _steal(o)),
        ]),
        if (nb.catchChance > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('${nb.dog != null && nb.dogAwake(nb.dog!) ? '🐕 Có chó canh' : '🪧 Có bù nhìn'}: ${(nb.catchChance * 100).round()}% bị bắt, phạt ${fmtNum(me.stealFine)} xu',
                style: const TextStyle(fontSize: 12, color: red, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }
}
