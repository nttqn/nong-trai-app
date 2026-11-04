// The main (and only) game screen: pannable farm map + HUD + panels.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/defs.dart';
import '../core/farm.dart';
import '../core/quests.dart';
import '../core/weather.dart';
import '../render/farm_painter.dart';
import '../render/iso.dart' show clearTextCache;
import '../services/ads.dart';
import '../services/analytics.dart';
import '../services/cloud.dart';
import '../services/notify.dart';
import '../services/save.dart';
import '../services/sound.dart';
import 'cloud_tile.dart';
import 'extras.dart';
import 'leaderboard_sheet.dart';
import 'world_map.dart';
import '../services/neighbors.dart';
import 'panels.dart';
import 'quest_sheet.dart';
import 'sheets.dart';
import 'widgets.dart';

class FarmScreen extends StatefulWidget {
  final Farm farm;
  final SaveService save;
  const FarmScreen(this.farm, this.save, {super.key});
  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Farm get farm => widget.farm;
  late final Ticker _ticker;
  final _clock = ValueNotifier(0.0);
  final _view = ViewState();
  final _cache = GroundCache();
  final _tc = TransformationController();
  bool _placedCamera = false;
  Size _screen = Size.zero;

  Obj? _sel;
  int? _lotSel;
  String? _plantCrop;
  String? _placeType;
  Obj? _moving;
  String? _toast;
  bool _toastErr = false;
  Timer? _toastTimer, _hud;
  int _lastRev = -1;
  final List<int> _levelUps = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    farm.onLevelUp = (l) {
      _levelUps.add(l);
      Analytics.instance.levelUp(l);
    };
    AdsService.instance.playerLevel = () => farm.level;
    farm.onEvent = (name, params) {
      Analytics.instance.log(name, params);
      if (name == 'order_delivered') AdsService.instance.onOrderDelivered(farm.level);
    };
    CloudSave.instance.addListener(_onCloud);
    Neighbors.instance.addListener(_onNeighbors);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onCloud();
      Future.delayed(const Duration(milliseconds: 1500), _maybeLoginGift);
    });
    farm.onSound = (c) => SoundService.instance.play(c);
    _ticker = createTicker((e) {
      final prev = _clock.value;
      _clock.value = e.inMicroseconds / 1e6;
      if (kIsWeb && prev < 12 && prev.floor() != _clock.value.floor()) clearTextCache();
      if (farm.fx.isNotEmpty) {
        for (final f in farm.fx) {
          _view.floats.add(FloatFx(f, _clock.value));
        }
        farm.fx.clear();
      }
      if (farm.rev != _lastRev) {
        if (farm.tutCheck()) SoundService.instance.play('quest');
        _lastRev = farm.rev;
        widget.save.schedule(farm);
        if (mounted) setState(() {});
        if (_levelUps.isNotEmpty) _showLevelUp();
      }
    })..start();
    _hud = Timer.periodic(const Duration(seconds: 1), (_) {
      farm.tickOrders();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CloudSave.instance.removeListener(_onCloud);
    Neighbors.instance.removeListener(_onNeighbors);
    _ticker.dispose();
    _hud?.cancel();
    _toastTimer?.cancel();
    widget.save.saveNow(farm);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
      widget.save.saveNow(farm);
      if (s == AppLifecycleState.paused) NotifyService.instance.scheduleFor(farm);
    } else if (s == AppLifecycleState.resumed) {
      NotifyService.instance.cancelAll();
      Neighbors.instance.pull(farm);
      _maybeLoginGift();
    }
  }

  // ---------------------------------------------------------------- daily gift
  bool _giftOpen = false;

  /// Today's login gift, once the tutorial is over and nothing else is up.
  Future<void> _maybeLoginGift() async {
    if (!mounted || _giftOpen || _askingCloud || farm.tutActive || farm.loginClaimed) {
      if (mounted && !farm.tutActive && farm.level >= 2) NotifyService.instance.askOnce();
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _giftOpen = true;
    await showLoginGift(context, farm);
    _giftOpen = false;
    if (mounted) setState(() {});
    if (farm.level >= 2) NotifyService.instance.askOnce();
  }

  // ---------------------------------------------------------------- feedback
  void _report(String? err, {String? ok}) {
    if (err != null) {
      _say(err, error: true);
      SoundService.instance.play('error');
      HapticFeedback.lightImpact();
    } else if (ok != null) {
      _say(ok);
    }
    setState(() {});
  }

  void _say(String s, {bool error = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toast = s;
      _toastErr = error;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _showLevelUp() async {
    final l = _levelUps.removeAt(0);
    _levelUps.clear();
    SoundService.instance.play('levelup');
    final unlocked = <String>[
      for (final c in crops.values)
        if (c.level == l) '🌱 ${c.name}',
      for (final b in buildings.values)
        if (b.level == l && b.kind != BKind.obstacle && b.kind != BKind.paddy && b.kind != BKind.bed)
          '${b.kind == BKind.project ? '🏛️' : '🏗️'} ${b.name}',
      for (final f in fishes.values)
        if (f.level == l) '🐟 ${f.name}',
      for (final r in recipes.values)
        if (r.level == l) '🍳 ${item(r.product).name}',
    ];
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🎉 Lên cấp $l!', textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, color: brown)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Coin(20 * l, size: 18),
          const SizedBox(height: 10),
          if (unlocked.isNotEmpty) ...[
            const Text('Mở khóa mới:', style: TextStyle(fontWeight: FontWeight.w800, color: brownLight)),
            const SizedBox(height: 4),
            for (final u in unlocked) Text(u, style: const TextStyle(color: brown, fontWeight: FontWeight.w600)),
          ],
        ]),
        actions: [
          Center(
            child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              ValueListenableBuilder<bool>(
                valueListenable: AdsService.instance.rewardedReady,
                builder: (_, ready, _) => ready
                    ? PillButton('📺 Nhân đôi',
                        color: gold,
                        leading: Coin(20 * l, size: 12, color: Colors.white),
                        onTap: () async {
                          Navigator.pop(c);
                          if (await AdsService.instance.showRewarded('levelup_double')) farm.bonusCoins(20 * l);
                        })
                    : const SizedBox.shrink(),
              ),
              PillButton('Tuyệt vời!', onTap: () => Navigator.pop(c)),
            ]),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- neighbours
  bool _showingVisits = false;

  Future<void> _onNeighbors() async {
    final nb = Neighbors.instance;
    if (!mounted || _showingVisits || nb.inbox.isEmpty) return;
    _showingVisits = true;
    final lines = List<String>.of(nb.inbox);
    nb.inbox.clear();
    SoundService.instance.play('quest');
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('📬 Tin trong làng', style: TextStyle(fontWeight: FontWeight.w900, color: brown)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(l, style: const TextStyle(color: brown, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 4),
          const Text('Đặt bù nhìn, nuôi chó giữ nhà để bắt kẻ hái trộm!', style: TextStyle(color: brownLight, fontSize: 12.5)),
        ]),
        actions: [Center(child: PillButton('Biết rồi', onTap: () => Navigator.pop(c)))],
      ),
    );
    _showingVisits = false;
    if (Neighbors.instance.inbox.isNotEmpty) _onNeighbors();
  }

  void _openMap() {
    SoundService.instance.play('tap');
    _select(null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => WorldMapScreen(farm, onNameNeeded: () => askFarmName(ctx, farm))),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // ---------------------------------------------------------------- cloud
  bool _askingCloud = false;
  String? _cloudMsg;

  void _onCloud() {
    final cs = CloudSave.instance;
    if (!mounted) return;
    if (cs.message != null && cs.message != _cloudMsg) {
      _cloudMsg = cs.message;
      _say(cs.message!, error: true);
    }
    if (cs.conflict != null && !_askingCloud) _askCloud();
  }

  Future<void> _askCloud() async {
    final cs = CloudSave.instance;
    final c = cs.conflict;
    if (c == null) return;
    _askingCloud = true;
    final when = DateTime.fromMillisecondsSinceEpoch(c.info.savedAt);
    String ago(DateTime t) {
      final d = DateTime.now().difference(t);
      if (d.inMinutes < 1) return 'vừa xong';
      if (d.inHours < 1) return '${d.inMinutes} phút trước';
      if (d.inDays < 1) return '${d.inHours} giờ trước';
      return '${d.inDays} ngày trước';
    }

    Widget option(String title, String sub, VoidCallback onTap, Color color) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(sub, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                ]),
              ),
            ),
          ),
        );
    final cloud = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Chọn nông trại', style: TextStyle(fontWeight: FontWeight.w900, color: brown)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Tài khoản ${cs.who} đã có một nông trại khác với nông trại trên máy này. Giữ bản nào? Bản còn lại sẽ bị thay thế.',
              style: const TextStyle(color: brown)),
          option('☁️ Bản trên mây', 'Cấp ${c.info.level} · lưu ${ago(when)}', () => Navigator.pop(d, true), green),
          option('📱 Bản trên máy này', 'Cấp ${farm.level} · đang chơi', () => Navigator.pop(d, false), const Color(0xFF8D6E4C)),
        ]),
      ),
    );
    _askingCloud = false;
    if (cloud == true) {
      await cs.takeCloud();
    } else {
      await cs.keepLocal();
      if (mounted) _say('Đã lưu nông trại này lên tài khoản');
    }
  }

  // ---------------------------------------------------------------- camera
  void _placeCamera(Size s) {
    if (_placedCamera || s.isEmpty) return;
    _placedCamera = true;
    final q = kIsWeb ? Uri.base.queryParameters : const <String, String>{};
    final scale = double.tryParse(q['zoom'] ?? '') ?? (s.width / 560).clamp(.55, 1.3);
    final focus = worldIso.p(double.tryParse(q['fx'] ?? '') ?? 12, double.tryParse(q['fy'] ?? '') ?? 9);
    _tc.value = Matrix4.identity()
      ..translateByDouble(s.width / 2 - focus.dx * scale, s.height * .46 - focus.dy * scale, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  (int, int) _viewCenterTile() {
    final p = _tc.toScene(Offset(_screen.width / 2, _screen.height * .45));
    final (gx, gy) = worldIso.toGrid(p);
    return (gx.floor(), gy.floor());
  }

  // ---------------------------------------------------------------- taps
  void _tap(Offset p) {
    final (gxf, gyf) = worldIso.toGrid(p);
    final gx = gxf.floor(), gy = gyf.floor();
    if (_placeType != null || _moving != null) {
      final d = bdef(_placeType ?? _moving!.type);
      setState(() {
        _view.ghostX = Farm.snapX(d.id, (gx - (d.w - 1) / 2).round());
        _view.ghostY = (gy - (d.h - 1) / 2).round();
      });
      return;
    }
    final o = hitTest(farm, p, _view);
    if (_plantCrop != null) {
      if (o != null && (o.def.kind == BKind.paddy || o.def.kind == BKind.bed)) {
        if (o.crop == null) {
          final c = crops[_plantCrop]!;
          if (farm.cropFits(o, c)) {
            final err = farm.plant(o, _plantCrop!);
            if (err != null) _report(err);
            return;
          }
        } else if (farm.isReady(o)) {
          _report(farm.harvest(o));
          return;
        } else {
          return;
        }
      }
      setState(() => _plantCrop = null);
    }
    if (o == null) {
      if (gx >= 0 && gy >= 0 && gx < mapSize && gy < mapSize &&
          !farm.owned(gx, gy) && Farm.terrain(gx, gy) != 'water') {
        SoundService.instance.play('tap');
        _select(null, lot: Farm.lotOf(gx, gy));
      } else {
        _select(null);
      }
      return;
    }
    if (!farm.owned(o.x, o.y) && o.def.kind == BKind.obstacle) {
      _select(null, lot: Farm.lotOf(o.x, o.y));
      return;
    }
    // quick actions on ready things
    switch (o.def.kind) {
      case BKind.paddy || BKind.bed:
        if (o.crop != null && farm.isReady(o)) {
          final err = farm.harvest(o);
          _report(err);
          if (err == null) {
            // stay in a "harvest then replant" flow
            _select(o);
          }
          return;
        }
      case BKind.pen:
        if (farm.isReady(o)) {
          _report(farm.collect(o));
          _select(o);
          return;
        }
      case BKind.pond:
        if (o.crop != null && farm.isReady(o)) {
          _report(farm.catchFish(o));
          _select(o);
          return;
        }
      case BKind.tree:
        if (farm.isReady(o)) {
          _report(farm.pickTree(o));
          _select(o);
          return;
        }
      case BKind.factory:
        if (farm.readyJobs(o) > 0) _report(farm.collectJobs(o));
      default:
    }
    if (o != _sel) {
      final a = o.def.kind == BKind.pen && o.count > 0 ? animalForPen(o.type) : null;
      SoundService.instance.play(a?.id ?? 'tap', volume: a != null ? .6 : 1);
    }
    _select(o);
  }

  void _select(Obj? o, {int? lot}) {
    setState(() {
      _sel = o;
      _view.selected = o;
      _lotSel = lot;
    });
  }

  void _startPlace(String type) {
    final (cx, cy) = _viewCenterTile();
    final d = bdef(type);
    setState(() {
      _select(null);
      _plantCrop = null;
      _placeType = type;
      _view.ghostType = type;
      _view.ghostX = Farm.snapX(d.id, cx - d.w ~/ 2);
      _view.ghostY = cy - d.h ~/ 2;
      _nudgeGhost(type);
    });
  }

  /// Move the ghost to the nearest valid spot so the first preview is useful.
  void _nudgeGhost(String type, {int? ignore}) {
    final sx = _view.ghostX, sy = _view.ghostY;
    for (var r = 0; r < 14; r++) {
      for (var dx = -r; dx <= r; dx++) {
        for (var dy = -r; dy <= r; dy++) {
          if (math.max(dx.abs(), dy.abs()) != r) continue;
          if (farm.canPlace(type, sx + dx, sy + dy, ignore: ignore)) {
            _view.ghostX = sx + dx;
            _view.ghostY = sy + dy;
            return;
          }
        }
      }
    }
  }

  void _confirmPlace() {
    if (_moving != null) {
      final err = farm.move(_moving!, _view.ghostX, _view.ghostY);
      if (err != null) return _report(err);
      final o = _moving!;
      _cancelPlace();
      _select(o);
      return;
    }
    final type = _placeType!;
    final err = farm.build(type, _view.ghostX, _view.ghostY);
    if (err != null) return _report(err);
    final d = bdef(type);
    // keep placing plots/trees/decor in a row for convenience
    if ((d.kind == BKind.paddy || d.kind == BKind.bed || d.kind == BKind.deco) && farm.canBuy(type) == null) {
      setState(() => _nudgeGhost(type));
      return;
    }
    _cancelPlace();
    final placed = farm.objs.last;
    if (placed.type == type) _select(placed);
  }

  void _cancelPlace() {
    setState(() {
      _placeType = null;
      _moving = null;
      _view.ghostType = null;
      _view.moving = null;
    });
  }

  void _startMove(Obj o) {
    setState(() {
      _select(null);
      _moving = o;
      _view.moving = o;
      _view.ghostX = o.x;
      _view.ghostY = o.y;
    });
  }

  // ---------------------------------------------------------------- sheets
  Future<void> _openShop() async {
    SoundService.instance.play('tap');
    _select(null);
    final type = await showFarmSheet<String>(context, (_) => ShopSheet(farm));
    if (type != null) _startPlace(type);
  }

  Future<void> _openProjects() async {
    SoundService.instance.play('tap');
    _select(null);
    final type = await showFarmSheet<String>(context, (_) => ProjectsSheet(farm, _report), height: .8);
    if (type != null) _startPlace(type);
  }

  void _openStorage() {
    SoundService.instance.play('tap');
    _select(null);
    showFarmSheet(context, (_) => StorageSheet(farm, _report));
  }

  void _openOrders() {
    SoundService.instance.play('tap');
    _select(null);
    showFarmSheet(context, (_) => OrdersSheet(farm, _report), height: .78);
  }

  void _openMenu() {
    SoundService.instance.play('tap');
    final snd = SoundService.instance;
    showFarmSheet(
      context,
      (c) => ListView(padding: const EdgeInsets.all(8), children: [
        const SheetHeader('Lưu trữ đám mây'),
        const CloudTile(),
        const SheetHeader('Âm thanh'),
        ValueListenableBuilder<bool>(
          valueListenable: snd.musicOn,
          builder: (_, on, _) => SwitchListTile(
            dense: true,
            activeThumbColor: green,
            title: const Text('🎵 Nhạc nền đồng quê', style: TextStyle(color: brown, fontWeight: FontWeight.w700)),
            value: on,
            onChanged: (_) => snd.toggleMusic(),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: snd.sfxOn,
          builder: (_, on, _) => SwitchListTile(
            dense: true,
            activeThumbColor: green,
            title: const Text('🔔 Hiệu ứng âm thanh', style: TextStyle(color: brown, fontWeight: FontWeight.w700)),
            value: on,
            onChanged: (_) => snd.toggleSfx(),
          ),
        ),
        const SheetHeader('Thông báo'),
        ValueListenableBuilder<bool>(
          valueListenable: NotifyService.instance.enabled,
          builder: (_, on, _) => SwitchListTile(
            dense: true,
            activeThumbColor: green,
            title: const Text('🔔 Nhắc khi lúa chín, có quà', style: TextStyle(color: brown, fontWeight: FontWeight.w700)),
            value: on,
            onChanged: (v) => NotifyService.instance.setEnabled(v),
          ),
        ),
        const SheetHeader('Hướng dẫn'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '• Chạm ô ruộng/luống trống để gieo giống, chạm tiếp các ô khác để gieo nhanh.\n'
            '• Cây chín thì chạm để thu hoạch. Mọi thứ vẫn lớn khi bạn tắt game.\n'
            '• Lúa cho thóc và rơm: thóc nuôi gà vịt, xay ra gạo và cám; rơm nuôi trâu bò.\n'
            '• Trâu cho phân chuồng: bón cho cây đang lớn để rút ngắn một nửa thời gian.\n'
            '• Giao đơn hàng cho bà con để có nhiều xu và kinh nghiệm.\n'
            '• Góp xu và nông sản xây công trình nông thôn mới: mỗi công trình cho một lợi ích lâu dài.\n'
            '• Nâng cấp nhà để kho chứa được nhiều hơn. Mua thêm đất bằng biển "Mua đất".\n'
            '• Thời tiết (góc trên) đổi 3 giờ một lần: gieo lúc mưa thì cây lớn nhanh, nắng hạn thì chậm nếu thiếu trạm bơm, giếng.\n'
            '• Từ cấp 7 có chợ phiên: bày hàng thừa lên sạp (🛒 trong Kho) cho người chơi khác mua.\n'
            '• Kéo hai ngón để phóng to/thu nhỏ bản đồ.\n'
            '• Đăng nhập Google để lưu nông trại lên mây, đổi máy không mất.',
            style: TextStyle(color: brown, height: 1.45),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: c,
                builder: (d) => AlertDialog(
                  title: const Text('Chơi lại từ đầu?'),
                  content: const Text('Toàn bộ nông trại hiện tại sẽ bị xóa, kể cả bản lưu trên mây.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Thôi')),
                    TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Xóa và chơi lại')),
                  ],
                ),
              );
              if (yes == true) {
                await widget.save.reset();
                await CloudSave.instance.wipeCloudFarm();
                SystemNavigator.pop();
              }
            },
            child: const Text('Chơi lại từ đầu', style: TextStyle(color: red)),
          ),
        ),
      ]),
      height: .75,
    );
  }

  Future<void> _onBack() async {
    if (_placeType != null || _moving != null) return _cancelPlace();
    if (_plantCrop != null) return setState(() => _plantCrop = null);
    if (_sel != null || _lotSel != null) return _select(null);
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Rời nông trại?'),
        content: const Text('Cây trồng và vật nuôi vẫn tiếp tục lớn khi bạn đi vắng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ở lại')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Thoát')),
        ],
      ),
    );
    if (yes == true) {
      await widget.save.saveNow(farm);
      SystemNavigator.pop();
    }
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final placing = _placeType != null || _moving != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF9FCB63),
        body: LayoutBuilder(builder: (context, cons) {
          _screen = cons.biggest;
          _placeCamera(_screen);
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
                  child: CustomPaint(
                    size: const Size(worldW, worldH),
                    painter: FarmPainter(farm, _view, _clock, _cache),
                  ),
                ),
              ),
            ),
            Positioned(left: 0, right: 0, top: 0, child: SafeArea(child: _hudBar())),
            if (_toast != null)
              Positioned(
                left: 24,
                right: 24,
                top: MediaQuery.of(context).padding.top + 108,
                child: IgnorePointer(child: _toastView()),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (farm.tutActive && !placing)
                    TutorialBanner(farm, onSkip: _skipTutorial, onFinish: _finishTutorial),
                  if (_plantCrop != null) _modeBanner('🌱 Đang gieo ${crops[_plantCrop]!.name} — chạm các ô trống', () => setState(() => _plantCrop = null)),
                  if (!placing && _sel != null && farm.objs.contains(_sel))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                      child: ObjPanel(farm, _sel!, PanelActions(_report, (c) => setState(() {
                            _plantCrop = c;
                            _select(null);
                          }), _startMove, () => _select(null), () => setState(() {}))),
                    ),
                  if (!placing && _lotSel != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                      child: LotPanel(farm, _lotSel!, _report, () => _select(null)),
                    ),
                  placing ? _placeBar() : _bottomBar(),
                ]),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _toastView() => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _toastErr ? const Color(0xEEB23B32) : const Color(0xEE3F7A1C),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_toast!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
        ),
      );

  Widget _hudBar() {
    final need = xpToNext(farm.level);
    final q = farm.currentQuest;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // level, coins and storage shrink to fit so the menu button never
          // leaves the screen on narrow phones or with big numbers
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
          // level + xp
          Container(
            height: 40,
            padding: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: const Color(0xE6FFF8E7), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD9B97A), width: 1.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFF1E88E5), shape: BoxShape.circle),
                child: Text('${farm.level}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 64,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: farm.xp / need, minHeight: 7, color: const Color(0xFF42A5F5), backgroundColor: creamDark),
                  ),
                  const SizedBox(height: 2),
                  Text('${farm.xp}/$need', style: const TextStyle(fontSize: 10, color: brownLight, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
          const SizedBox(width: 6),
          _chip(Coin(farm.coins, size: 15, short: true)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _openStorage,
            child: _chip(Text('📦 ${farm.stored}/${farm.storageCap}',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: farm.stored >= farm.storageCap ? red : brown))),
          ),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _openMenu,
            child: _chip(const Icon(Icons.menu_rounded, color: brown, size: 22)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: q == null ? const SizedBox.shrink() : _questChip(q))),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _openLeaderboard,
            child: _chip(const Text('🏆', style: TextStyle(fontSize: 19))),
          ),
        ]),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Flexible(
            child: _chip(Flexible(
              child: Text('🏘️ ${villageTitle(farm.projects.length)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: brown)),
            ), small: true),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => showWeather(context, farm),
            child: _chip(Text(weatherIcon(farm.weather), style: const TextStyle(fontSize: 19))),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _openAchievements,
            child: _badged(_chip(const Text('🏅', style: TextStyle(fontSize: 19))), farm.achReadyCount),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _openMap,
            child: _chip(const Text('🗺️', style: TextStyle(fontSize: 19))),
          ),
        ]),
      ]),
    );
  }

  void _openAchievements() {
    SoundService.instance.play('tap');
    _select(null);
    showFarmSheet(context, (_) => AchievementsSheet(farm, _report), height: .82).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _skipTutorial() {
    farm.tutFinish();
    setState(() {});
    _maybeLoginGift();
  }

  void _finishTutorial() {
    SoundService.instance.play('quest');
    farm.tutFinish();
    setState(() {});
    _maybeLoginGift();
  }

  Widget _badged(Widget child, int n) => Stack(clipBehavior: Clip.none, children: [
        child,
        if (n > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(10)),
              child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ),
      ]);

  void _openLeaderboard() {
    SoundService.instance.play('tap');
    _select(null);
    showFarmSheet(context, (_) => LeaderboardSheet(farm), height: .8);
  }

  void _claimQuest() {
    final q = farm.currentQuest;
    if (q == null || !farm.questDone) return;
    farm.claimQuest();
    _say('Nhận ${q.coins} xu thưởng nhiệm vụ!');
  }

  void _openQuests() {
    SoundService.instance.play('tap');
    _select(null);
    showFarmSheet(context, (_) => QuestSheet(farm, _claimQuest), height: .75);
  }

  Widget _questChip(QuestDef q) => GestureDetector(
            onTap: farm.questDone ? _claimQuest : _openQuests,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              decoration: BoxDecoration(
                color: farm.questDone ? const Color(0xF0FFE082) : const Color(0xE6FFF8E7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: farm.questDone ? gold : const Color(0xFFD9B97A), width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('📜', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(q.text,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: brown, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                if (farm.questDone)
                  const Text('Nhận 🎁', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD84315)))
                else
                  Text('${math.min(farm.questValue(q), q.target)}/${q.target}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: greenDark)),
              ]),
            ),
          );

  Widget _chip(Widget child, {bool small = false}) => Container(
        height: small ? 26 : 40,
        padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12),
        decoration: BoxDecoration(
          color: const Color(0xE6FFF8E7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9B97A), width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [child]),
      );

  Widget _modeBanner(String label, VoidCallback close) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        decoration: BoxDecoration(color: const Color(0xEE3F7A1C), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
          IconButton(onPressed: close, icon: const Icon(Icons.close_rounded, color: Colors.white)),
        ]),
      );

  Widget _bottomBar() {
    final deliverable = farm.orders.where(farm.canDeliver).length +
        farm.daily.where((o) => o.waitUntil >= 0 && o.need.entries.every((e) => farm.countOf(e.key) >= e.value)).length;
    final tut = farm.tutStep;
    Widget btn(String icon, String label, VoidCallback onTap, {int badge = 0, bool hint = false}) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                  if (hint)
                    Container(
                      width: 42,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE082),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE65100), width: 2),
                      ),
                    ),
                  Text(icon, style: const TextStyle(fontSize: 26)),
                  if (badge > 0)
                    Positioned(
                      right: -10,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(10)),
                        child: Text('$badge',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ]),
                Text(label,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: brown)),
              ]),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: cardDeco(),
      child: Row(children: [
        btn('🏗️', 'Xây dựng', _openShop, hint: tut == Tut.build),
        btn('📦', 'Kho & Chợ', _openStorage),
        btn('📋', 'Đơn hàng', _openOrders, badge: deliverable, hint: tut == Tut.order),
        btn('🏛️', 'Nông thôn mới', _openProjects),
      ]),
    );
  }

  Widget _placeBar() {
    final type = _placeType ?? _moving!.type;
    final d = bdef(type);
    final ok = farm.canPlace(type, _view.ghostX, _view.ghostY, ignore: _moving?.id);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: cardDeco(),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_moving != null ? 'Di chuyển ${d.name}' : d.name,
                style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 15)),
            Text(ok ? 'Chạm bản đồ để chọn chỗ khác' : 'Chỗ này không đặt được — chạm chỗ khác',
                style: TextStyle(fontSize: 12, color: ok ? brownLight : red)),
            if (_placeType != null) Coin(farm.buildCost(type), size: 12.5),
          ]),
        ),
        PillButton('Hủy', color: brownLight, onTap: _cancelPlace),
        const SizedBox(width: 8),
        PillButton(_moving != null ? 'Đặt' : 'Xây', onTap: ok ? _confirmPlace : null),
      ]),
    );
  }
}
