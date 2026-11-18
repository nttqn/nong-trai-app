import 'package:flutter_test/flutter_test.dart';
import 'package:nong_trai/core/chat.dart';

void main() {
  test('swear words are starred, everyday words are not', () {
    expect(chatCensor('đm thằng này'), '** thằng này');
    expect(chatCensor('Vui quá VCL!'), 'Vui quá ***!');
    expect(chatCensor('địttt'), '*****');
    // Unaccented look-alikes of swears are ordinary Vietnamese.
    expect(chatCensor('lon nuoc, cac ban, buoi sang'), 'lon nuoc, cac ban, buoi sang');
    expect(chatCensor('Ai bán lúa nếp cẩm không?'), 'Ai bán lúa nếp cẩm không?');
  });

  test('messages are one trimmed line within the limit', () {
    expect(chatClean('  chào\n\nbà   con  '), 'chào bà con');
    expect(chatClean('   '), '');
    expect(chatClean('a' * 300).length, chatMaxLen);
    // An emoji straddling the limit is dropped whole, not split.
    expect(chatClean('${'a' * (chatMaxLen - 1)}😀'), 'a' * (chatMaxLen - 1));
  });

  test('cooldown', () {
    const t = 1000000000;
    expect(chatWait(null, t), Duration.zero);
    expect(chatWait(t, t), chatCooldown);
    expect(chatWait(t, t + chatCooldown.inMilliseconds), Duration.zero);
    expect(chatWaitLabel(const Duration(minutes: 1, seconds: 32)), '1:32');
    expect(chatWaitLabel(const Duration(milliseconds: 59500)), '1:00');
  });

  test('messages read from the database', () {
    final m = ChatMsg.fromMap('k', {'uid': 'u', 'name': 'Trại vcl', 'level': 44, 'text': 'đm', 'at': 5});
    expect(m, isNotNull);
    expect(m!.text, '**');
    expect(m.name, 'Trại ***');
    expect(ChatMsg.fromMap('k', 'junk'), isNull);
    expect(ChatMsg.fromMap('k', {'uid': 'u'}), isNull);
  });
}
