import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/services.dart';

import 'core/defs.dart';
import 'core/demo.dart';
import 'core/farm.dart';
import 'core/calendar.dart';
import 'core/weather.dart';
import 'render/sprites.dart';
import 'services/ads.dart';
import 'services/cloud.dart';
import 'services/leaderboard.dart';
import 'services/notify.dart';
import 'services/save.dart';
import 'services/sound.dart';
import 'ui/farm_screen.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SoundService.instance.init();
  runApp(const NongTraiApp());
}

class NongTraiApp extends StatelessWidget {
  const NongTraiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mùa Lúa Chín',
        navigatorKey: AdsService.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: green),
          useMaterial3: true,
        ),
        home: const _Boot(),
      );
}

class _Boot extends StatefulWidget {
  const _Boot();
  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  final _save = SaveService();
  Farm? _farm;
  int _gen = 0; // bumps when a cloud restore swaps the farm

  @override
  void initState() {
    super.initState();
    final q = kIsWeb ? Uri.base.queryParameters : const <String, String>{};
    final sprites = Sprites.load().timeout(const Duration(seconds: 10), onTimeout: () {});
    if (q['demo'] != null) {
      for (final w in Weather.values) {
        if (q['weather'] == w.name) weatherOverride = w;
      }
      if (q['day'] != null) calendarOverride = DateTime.tryParse(q['day']!);
      sprites.then((_) {
        if (mounted) {
          final f = demoFarm(int.parse(q['demo']!), house: int.tryParse(q['house'] ?? '') ?? -1);
          if (q['gift'] != null) f.loginDay = 0;
          if (q['yard'] == 'cover') f.yardCover = true;
          if (q['yard'] == 'dry') f.yardDry = FarmSeason.yardNeedMs;
          if (q['yard'] == 'empty') f.yard.clear();
          if (q['fest'] != null) demoFestivalDecos(f);
          // promo video capture: everything runs ?slow= times slower (the
          // recorder speeds the frames back up), so every frame is caught
          final slow = double.tryParse(q['slow'] ?? '');
          if (slow != null && slow > 1) {
            timeDilation = slow;
            final base = f.now();
            final wall0 = DateTime.now().millisecondsSinceEpoch;
            f.now = () => base + ((DateTime.now().millisecondsSinceEpoch - wall0) / slow).round();
          }
          // promo video: every field ripe, ready to swipe-harvest
          if (q['ripe'] != null) {
            for (final o in f.objs) {
              if (o.crop != null && (o.def.kind == BKind.paddy || o.def.kind == BKind.bed)) {
                o.end = f.now() - 1000;
                o.start = o.end - 60000;
              }
            }
          }
          if (q['memcard'] != null) {
            f.tickOrders();
            f.mem[q['memcard']!] = 1;
            f.memFresh.add(q['memcard']!);
          }
          if (q['hungry'] != null) {
            for (final o in f.objs) {
              if (o.def.kind == BKind.pen || o.type == 'cho') o.start = o.end = 0;
            }
          }
          setState(() => _farm = f);
        }
      });
      return;
    }
    final cloud = CloudSave.instance;
    Future.wait([_save.load(), sprites, cloud.init(), Leaderboard.instance.load()]).then((r) {
      if (!mounted) return;
      final farm = r[0] as Farm;
      _save.active = farm;
      setState(() => _farm = farm);
      cloud.current = () => _farm!;
      cloud.replace = _replace;
      SaveService.onSaved = cloud.queueUpload;
      // After the farm is on screen: the consent form needs a frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AdsService.instance.init();
        NotifyService.instance.init();
        cloud.start();
      });
    });
  }

  /// Swaps in the farm restored from the cloud.
  Future<void> _replace(Farm f) async {
    _save.active = f;
    await _save.saveNow(f, keepStamp: true);
    if (mounted) {
      setState(() {
        _farm = f;
        _gen++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_farm == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF8CC152),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🌾', style: TextStyle(fontSize: 64)),
            SizedBox(height: 12),
            Text('Mùa Lúa Chín',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            SizedBox(height: 18),
            CircularProgressIndicator(color: Colors.white),
          ]),
        ),
      );
    }
    return FarmScreen(_farm!, _save, key: ValueKey(_gen));
  }
}
