import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/ui/widgets.dart';

void main() {
  Future<(List<int>, Finder)> pumpButton(WidgetTester tester, int stock) async {
    final sold = <int>[];
    var left = stock;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: HoldRepeat(
            onFire: () {
              if (left < 1) return false;
              left--;
              sold.add(left);
              return left > 0;
            },
            builder: (tap) => PillButton('Bán 1', onTap: tap),
          ),
        ),
      ),
    ));
    return (sold, find.text('Bán 1'));
  }

  testWidgets('a tap sells one', (tester) async {
    final (sold, btn) = await pumpButton(tester, 50);
    await tester.tap(btn);
    await tester.pump(const Duration(seconds: 1));
    expect(sold.length, 1);
  });

  testWidgets('holding sells several, faster, and stops on release', (tester) async {
    final (sold, btn) = await pumpButton(tester, 50);
    final g = await tester.startGesture(tester.getCenter(btn));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sold, isEmpty); // not yet: a short press is a tap
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final n = sold.length;
    expect(n, greaterThan(8));
    expect(n, lessThan(50)); // not everything
    await g.up();
    await tester.pump(const Duration(seconds: 2));
    expect(sold.length, n); // released: no extra sale from the tap
  });

  testWidgets('stops when the stock runs out', (tester) async {
    final (sold, btn) = await pumpButton(tester, 5);
    final g = await tester.startGesture(tester.getCenter(btn));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    expect(sold.length, 5);
  });

  testWidgets('sliding the finger away (scrolling) stops it', (tester) async {
    final (sold, btn) = await pumpButton(tester, 50);
    final g = await tester.startGesture(tester.getCenter(btn));
    await tester.pump(const Duration(milliseconds: 700));
    await g.moveBy(const Offset(0, 40));
    final n = sold.length;
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await g.up();
    await tester.pump();
    expect(sold.length, n);
  });
}
