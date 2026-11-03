import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/demo.dart';
import 'core/farm.dart';
import 'render/sprites.dart';
import 'services/ads.dart';
import 'services/cloud.dart';
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
        title: 'Làng Quê Yên Bình',
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
      sprites.then((_) {
        if (mounted) {
          setState(() => _farm = demoFarm(int.parse(q['demo']!), house: int.tryParse(q['house'] ?? '') ?? -1));
        }
      });
      return;
    }
    final cloud = CloudSave.instance;
    Future.wait([_save.load(), sprites, cloud.init()]).then((r) {
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
            Text('Làng Quê Yên Bình',
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
