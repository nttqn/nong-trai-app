import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/demo.dart';
import 'package:nong_trai/ui/sheets.dart';

void main() {
  for (final stage in [1, 2, 3]) {
    testWidgets('orders sheet survives scrolling down and back up (stage $stage)', (t) async {
      final f = demoFarm(stage);
      await t.binding.setSurfaceSize(const Size(400, 800));
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 620, child: OrdersSheet(f, (msg, {ok}) {})),
        ),
      ));
      await t.pump();
      for (var i = 0; i < 3; i++) {
        await t.fling(find.byType(ListView), const Offset(0, -900), 3000);
        await t.pumpAndSettle();
        await t.fling(find.byType(ListView), const Offset(0, 1500), 4000);
        await t.pumpAndSettle();
      }
      expect(t.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    });
  }
}
