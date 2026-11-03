import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/demo.dart';
import 'core/farm.dart';
import 'services/save.dart';
import 'ui/farm_screen.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const NongTraiApp());
}

class NongTraiApp extends StatelessWidget {
  const NongTraiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Làng Quê Yên Bình',
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

  @override
  void initState() {
    super.initState();
    final q = kIsWeb ? Uri.base.queryParameters : const <String, String>{};
    if (q['demo'] != null) {
      _farm = demoFarm(int.parse(q['demo']!), house: int.tryParse(q['house'] ?? '') ?? -1);
      return;
    }
    _save.load().then((f) {
      if (mounted) setState(() => _farm = f);
    });
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
    return FarmScreen(_farm!, _save);
  }
}
