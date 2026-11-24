import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/app_version.dart';

void main() {
  test('appVersion matches pubspec.yaml', () {
    final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    expect(line.split(':')[1].trim().split('+').first, appVersion);
  });
}
