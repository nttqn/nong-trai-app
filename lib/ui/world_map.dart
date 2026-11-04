// 🗺️ Bản đồ vùng: the villages of other players, drawn on a hand-painted
// countryside map. Tap one to visit.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/achievements.dart';
import '../core/demo.dart';
import '../core/farm.dart';
import '../services/cloud.dart';
import '../services/neighbors.dart';
import '../services/sound.dart';
import 'market_ui.dart';
import 'visit_screen.dart';
import 'widgets.dart';

class WorldMapScreen extends StatefulWidget {
  final Farm me;
  final VoidCallback onNameNeeded;
  const WorldMapScreen(this.me, {super.key, required this.onNameNeeded});
  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  List<VillageInfo>? _list;
  String? _error;
  bool _opening = false;

  /// Dev screenshots on web: made-up villages, demo farms.
  bool get _demo => kIsWeb && Uri.base.queryParameters['worldmap'] == 'demo';

  static const _rowH = 190.0;
  double _w = 400;
  int get _cols => _w >= 700 ? 4 : 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_demo) {
      setState(() => _list = [
            for (final (i, n) in ['Trang trại Bác Ba', 'Vườn Cô Lan', 'Nhà Chú Tám', 'Ấp Hoa Cau', 'Đồng Xanh',
              'Làng Sen', 'Trại Ong Vàng', 'Quê Ngoại'].indexed)
              VillageInfo('demo$i', n, 8 + i * 3, i % 5, ['order', '', 'steal', 'harvest', ''][i % 5]),
          ]);
      return;
    }
    if (!Neighbors.instance.available) return setState(() {});
    try {
      final l = await Neighbors.instance.nearby();
      if (mounted) setState(() => _list = l);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không tải được bản đồ, thử lại sau.');
    }
  }

  Offset _slot(int i, String uid) {
    final h = uid.hashCode;
    final col = i % _cols, row = i ~/ _cols;
    final colW = _w / _cols;
    final jx = ((h & 0xff) / 255 - .5) * 30, jy = (((h >> 8) & 0xff) / 255 - .5) * 40;
    return Offset(colW * (col + .5) + (row.isOdd ? colW * .18 : -colW * .12) + jx, 130 + row * _rowH + (col.isOdd ? _rowH * .45 : 0) + jy);
  }

  Future<void> _visit(VillageInfo v) async {
    if (v.uid == Neighbors.instance.myUid) {
      Navigator.pop(context);
      return;
    }
    if (_opening) return;
    setState(() => _opening = true);
    SoundService.instance.play('tap');
    Farm? f;
    try {
      f = _demo ? demoFarm(1 + v.house % 3) : await Neighbors.instance.load(v.uid);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _opening = false);
    if (f == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không mở được nông trại này')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisitScreen(me: widget.me, neighbor: f!, uid: v.uid, name: v.name, title: v.title, offline: _demo),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = CloudSave.instance;
    return Scaffold(
      backgroundColor: const Color(0xFF8FC25A),
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: brown,
        title: const Text('🗺️ Các làng lân cận', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (widget.me.level >= FarmMore.marketLevel && !_demo)
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarketScreen(widget.me))),
              icon: const Text('🛒', style: TextStyle(fontSize: 18)),
              label: const Text('Chợ phiên', style: TextStyle(color: brown, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: cs,
        builder: (context, _) {
          if (!_demo && !cs.available) {
            return _note('Bản đồ cần kết nối máy chủ, bản này chưa bật.');
          }
          if (!_demo && cs.user == null) {
            return _note('Đăng nhập Google để ghé thăm hàng xóm và để làng của bạn hiện trên bản đồ.',
                action: PillButton(cs.busy ? 'Đang đăng nhập…' : 'Đăng nhập Google', onTap: cs.busy ? null : () async {
                  if (await cs.signInGoogle()) _load();
                }));
          }
          if (_error != null) return _note(_error!);
          final list = _list;
          if (list == null) {
            if (cs.user != null && _list == null && !_demo) {
              // signed in after the screen opened
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _list == null && _error == null) _load();
              });
            }
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          _w = math.max(380.0, MediaQuery.of(context).size.width);
          final rows = (list.length / _cols).ceil();
          final h = math.max(MediaQuery.of(context).size.height, 260 + rows * _rowH);
          final me = Neighbors.instance.myUid;
          return Stack(children: [
            InteractiveViewer(
              constrained: false,
              minScale: .5,
              maxScale: 2,
              boundaryMargin: const EdgeInsets.all(40),
              child: SizedBox(
                width: _w,
                height: h,
                child: Stack(children: [
                  Positioned.fill(child: CustomPaint(painter: _RegionPainter(list.length, _rowH))),
                  for (final (i, v) in list.indexed)
                    Positioned(
                      left: _slot(i, v.uid).dx - 60,
                      top: _slot(i, v.uid).dy - 50,
                      child: _marker(v, v.uid == me),
                    ),
                ]),
              ),
            ),
            if (widget.me.name.isEmpty && !_demo)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: cardDeco(),
                  child: Row(children: [
                    const Expanded(
                      child: Text('Đặt tên nông trại để làng của bạn hiện trên bản đồ.',
                          style: TextStyle(color: brown, fontWeight: FontWeight.w600)),
                    ),
                    PillButton('Đặt tên', dense: true, onTap: widget.onNameNeeded),
                  ]),
                ),
              ),
            if (list.isEmpty)
              _note('Chưa có làng nào khác. Mời bạn bè cùng chơi nhé!'),
            if (_opening) const Center(child: CircularProgressIndicator(color: Colors.white)),
          ]);
        },
      ),
    );
  }

  Widget _note(String text, {Widget? action}) => Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(18),
          decoration: cardDeco(),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: brown, fontWeight: FontWeight.w600)),
            if (action != null) ...[const SizedBox(height: 12), action],
          ]),
        ),
      );

  Widget _marker(VillageInfo v, bool mine) {
    const houses = ['🛖', '🏠', '🏠', '🏡', '🏘️'];
    return GestureDetector(
      onTap: () => _visit(v),
      child: SizedBox(
        width: 120,
        child: Column(children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mine ? const Color(0xFFFFF1C4) : const Color(0xEEFFF8E7),
              shape: BoxShape.circle,
              border: Border.all(color: mine ? gold : const Color(0xFFD9B97A), width: mine ? 3 : 2),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Text(houses[v.house.clamp(0, houses.length - 1)], style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: mine ? gold : const Color(0xE6FFF8E7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(mine ? '${v.name} (bạn)' : v.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: mine ? Colors.white : brown)),
          ),
          if (achById(v.title) != null)
            Text('${achById(v.title)!.icon} ${achById(v.title)!.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF8A2C0D))),
          Text('Cấp ${v.level}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2E5A12))),
        ]),
      ),
    );
  }
}

/// Fields, a winding river and dirt roads between the villages.
class _RegionPainter extends CustomPainter {
  final int n;
  final double rowH;
  _RegionPainter(this.n, this.rowH);

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF8FC25A));
    final rng = math.Random(7);
    // patchwork of rice fields
    for (var i = 0; i < (s.width * s.height / 6000).round(); i++) {
      final r = Rect.fromLTWH(rng.nextDouble() * s.width, rng.nextDouble() * s.height, 50 + rng.nextDouble() * 90,
          30 + rng.nextDouble() * 50);
      final col = [const Color(0xFF9CCB62), const Color(0xFFB5D46E), const Color(0xFF7FB54E), const Color(0xFFD8C36A)][i % 4];
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = col.withValues(alpha: .8));
    }
    // hills
    for (var i = 0; i < 6; i++) {
      final p = Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height);
      c.drawOval(Rect.fromCenter(center: p, width: 160, height: 70), Paint()..color = const Color(0x5536702A));
    }
    // river
    final river = Path()..moveTo(-20, s.height * .15);
    for (var y = 0.0; y <= s.height + 40; y += 120) {
      river.quadraticBezierTo(s.width * (.55 + .2 * math.sin(y / 170)), y + 60, s.width * (.5 + .25 * math.cos(y / 210)), y + 120);
    }
    c.drawPath(
        river,
        Paint()
          ..color = const Color(0xFF5DA9CF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 34
          ..strokeCap = StrokeCap.round);
    c.drawPath(
        river,
        Paint()
          ..color = const Color(0x55FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
    // roads along the rows
    final road = Paint()
      ..color = const Color(0xFFD9BE86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < (s.height / rowH).ceil(); row++) {
      final y = 175.0 + row * rowH;
      final p = Path()..moveTo(0, y);
      p.cubicTo(s.width * .3, y - 40, s.width * .6, y + 40, s.width, y - 10);
      c.drawPath(p, road);
    }
    // bamboo clumps
    for (var i = 0; i < 40; i++) {
      final p = Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height);
      c.drawCircle(p, 9, Paint()..color = const Color(0xFF4E8A2E));
      c.drawCircle(p + const Offset(7, 3), 7, Paint()..color = const Color(0xFF5F9E36));
    }
  }

  @override
  bool shouldRepaint(_RegionPainter old) => old.n != n;
}
