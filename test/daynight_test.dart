import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/daynight.dart';

int at(int h, [int m = 0]) => DateTime(2026, 11, 15, h, m).millisecondsSinceEpoch;

void main() {
  test('night follows the local clock', () {
    expect(nightAt(at(12)), 0);
    expect(nightAt(at(16)), 0);
    expect(nightAt(at(18, 20)), inExclusiveRange(0, 1));
    expect(nightAt(at(21)), 1);
    expect(nightAt(at(2)), 1);
    expect(nightAt(at(5, 30)), inExclusiveRange(0, 1));
    expect(nightAt(at(7)), 0);
  });

  test('moon phase by lunar day', () {
    expect(moonPhase(1).$1, lessThan(.03));
    expect(moonPhase(15).$1, greaterThan(.97));
    expect(moonPhase(8).$1, closeTo(.5, .1));
    expect(moonPhase(8).$2, isTrue);
    expect(moonPhase(23).$2, isFalse);
    expect(moonName(15), 'Trăng tròn');
    expect(lunarDayName(15), 'rằm');
  });

  test('after midnight it is still the evening moon', () {
    // 15/11/2026 is 7/10 âm lịch (Bính Ngọ)
    expect(moonDayAt(at(21)), 7);
    expect(moonDayAt(at(2)), 6);
  });
}
