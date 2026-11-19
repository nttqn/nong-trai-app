import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/services/play_verify.dart';

void main() {
  test('the Play licence key parses and rejects a forged signature', () {
    final v = PlayVerifier.fromBase64(playLicenseKey);
    expect(v, isNotNull);
    expect(v!.verify('{"orderId":"GPA.fake","productId":"bo_quang_cao"}', 'AAAA'), isFalse);
  });
}
