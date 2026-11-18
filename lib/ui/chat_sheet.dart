// 💬 Kênh Thế Giới: the last hundred messages of every farmer, one message
// per two minutes each (lib/services/chat.dart).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/chat.dart';
import '../core/farm.dart';
import '../services/chat.dart';
import '../services/cloud.dart';
import 'leaderboard_sheet.dart';
import 'widgets.dart';

/// Opens the chat as a bottom sheet that rises above the keyboard.
Future<void> showChatSheet(BuildContext context, Farm farm) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        final kb = mq.viewInsets.bottom;
        final h = math.min(mq.size.height * .85, mq.size.height - kb - mq.padding.top - 8);
        return Padding(
          padding: EdgeInsets.only(bottom: kb),
          child: Container(
            height: h,
            decoration: const BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(top: BorderSide(color: Color(0xFFD9B97A), width: 3)),
            ),
            child: SafeArea(top: false, bottom: kb == 0, child: ChatSheet(farm)),
          ),
        );
      },
    );

class ChatSheet extends StatefulWidget {
  final Farm farm;
  const ChatSheet(this.farm, {super.key});
  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _input = TextEditingController();
  Timer? _tick;
  bool _sending = false;

  ChatService get chat => ChatService.instance;
  CloudSave get cs => CloudSave.instance;
  Farm get farm => widget.farm;

  @override
  void initState() {
    super.initState();
    chat.addListener(_changed);
    cs.addListener(_changed);
    chat.open();
    // The countdown on the send button.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && chat.wait > Duration.zero) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    chat.removeListener(_changed);
    cs.removeListener(_changed);
    chat.close();
    _input.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _toast(String s) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(s), duration: const Duration(seconds: 2)));

  Future<void> _send() async {
    if (_sending) return;
    if (!chat.rulesAccepted && !await _showRules(ask: true)) return;
    if (!mounted) return;
    if (farm.name.trim().isEmpty) {
      _toast('Đặt tên nông trại để bà con biết ai đang nói');
      await askFarmName(context, farm);
      if (farm.name.trim().isEmpty || !mounted) return;
    }
    setState(() => _sending = true);
    final err = await chat.send(farm, _input.text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      _toast(err);
    } else {
      _input.clear();
      FocusScope.of(context).unfocus();
    }
  }

  /// The channel's rules; with [ask], true once the player agrees.
  Future<bool> _showRules({bool ask = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Quy tắc Kênh Thế Giới'),
        content: SingleChildScrollView(
          child: Text(
            '• Mọi người chơi đều đọc được tin của bạn, kèm tên nông trại và cấp.\n'
            '• Mỗi người gửi một tin mỗi ${chatCooldown.inMinutes} phút, tối đa $chatMaxLen chữ.\n'
            '• Không chửi bới, xúc phạm, quấy rối, phân biệt, nội dung người lớn, lừa đảo, '
            'quảng cáo hay để lộ thông tin cá nhân. Từ tục bị tự động che.\n'
            '• Chạm vào tin của người khác để Báo cáo hoặc Chặn. Tài khoản vi phạm sẽ bị cấm chat '
            'và tin bị xoá.\n'
            '• Tin cũ tự xoá sau ${chatKeep.inDays} ngày.',
            style: const TextStyle(color: brown, fontSize: 13.5, height: 1.35),
          ),
        ),
        actions: [
          if (ask) TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ask ? 'Đồng ý' : 'Đóng')),
        ],
      ),
    );
    if (ask && ok == true) await chat.acceptRules();
    return ok == true;
  }

  Future<void> _actions(ChatMsg m) async {
    final pick = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: cream,
        title: Text(m.name, style: const TextStyle(color: brown, fontWeight: FontWeight.w900)),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'report'),
            child: const Row(children: [
              Icon(Icons.flag_rounded, color: red),
              SizedBox(width: 10),
              Text('Báo cáo tin này', style: TextStyle(color: brown)),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'block'),
            child: const Row(children: [
              Icon(Icons.block_rounded, color: brownLight),
              SizedBox(width: 10),
              Flexible(child: Text('Chặn người này (ẩn mọi tin của họ)', style: TextStyle(color: brown))),
            ]),
          ),
        ],
      ),
    );
    if (pick == 'report') {
      await chat.report(m);
      _toast('Đã báo cáo, cảm ơn bạn. Tin đã được ẩn.');
    } else if (pick == 'block') {
      await chat.block(m.uid);
      _toast('Đã chặn ${m.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SheetHeader(
        '💬 Kênh Thế Giới',
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: brownLight),
          color: cream,
          onSelected: (v) {
            if (v == 'rules') _showRules();
            if (v == 'unblock') chat.unblockAll();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'rules', child: Text('Quy tắc kênh chat')),
            if (chat.blocked.isNotEmpty)
              PopupMenuItem(value: 'unblock', child: Text('Bỏ chặn ${chat.blocked.length} người')),
          ],
        ),
      ),
      Expanded(child: _list()),
      Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: creamDark, width: 1.5))),
        child: _inputRow(),
      ),
    ]);
  }

  Widget _center(String s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(s, textAlign: TextAlign.center, style: const TextStyle(color: brownLight)),
        ),
      );

  Widget _list() {
    if (!chat.available) return _center('Kênh chat cần kết nối máy chủ, bản này chưa bật.');
    if (chat.error != null) return _center(chat.error!);
    final rows = chat.visible;
    if (chat.loading && rows.isEmpty) return const Center(child: CircularProgressIndicator(color: green));
    if (rows.isEmpty) return _center('Chưa có tin nào. Chào bà con một câu!');
    final me = chat.myUid;
    // Reversed so it opens at the newest and new lines push up from below.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final m = rows[rows.length - 1 - i];
        return _row(m, m.uid == me);
      },
    );
  }

  String _time(int at) {
    final t = DateTime.fromMillisecondsSinceEpoch(at);
    final n = DateTime.now();
    final hm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (t.year == n.year && t.month == n.month && t.day == n.day) return hm;
    return '${t.day}/${t.month} $hm';
  }

  Widget _row(ChatMsg m, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: mine ? null : () => _actions(m),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: EdgeInsets.only(bottom: 6, left: mine ? 36 : 0, right: mine ? 0 : 36),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 7),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFFE4F2D2) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: mine ? green.withValues(alpha: .55) : const Color(0xFFE2CFA4), width: 1.2),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: mine ? '${m.name} (bạn)' : m.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: greenDark, fontSize: 13)),
                    TextSpan(text: '  Cấp ${m.level}', style: const TextStyle(color: brownLight, fontSize: 11)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(_time(m.at), style: const TextStyle(color: brownLight, fontSize: 11)),
            ]),
            const SizedBox(height: 2),
            Text(m.text, style: const TextStyle(color: brown, fontSize: 14.5, height: 1.25)),
          ]),
        ),
      ),
    );
  }

  Widget _inputRow() {
    if (!chat.available) return const SizedBox.shrink();
    if (!chat.canSend) {
      return Row(children: [
        const Expanded(
          child: Text('Đăng nhập Google để gửi tin (dùng chung tài khoản lưu đám mây).',
              style: TextStyle(color: brown, fontSize: 12.5)),
        ),
        PillButton(cs.busy ? '…' : 'Đăng nhập', dense: true, onTap: cs.busy ? null : cs.signInGoogle),
      ]);
    }
    if (chat.banned) {
      return const Text('Tài khoản của bạn đã bị cấm chat.', style: TextStyle(color: red, fontWeight: FontWeight.w700));
    }
    final w = chat.wait;
    final can = !_sending && w == Duration.zero;
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _input,
          maxLength: chatMaxLen,
          style: const TextStyle(color: brown, fontSize: 14.5),
          textInputAction: TextInputAction.send,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => _send(),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            hintText: w > Duration.zero ? 'Soạn sẵn, gửi được sau ${chatWaitLabel(w)}' : 'Nói gì đó với bà con…',
            hintStyle: const TextStyle(color: brownLight, fontSize: 13.5),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFD9B97A), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: green, width: 1.8),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        height: 44,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: green,
            disabledBackgroundColor: creamDark,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          onPressed: can ? _send : null,
          icon: Icon(w > Duration.zero ? Icons.hourglass_bottom_rounded : Icons.send_rounded, size: 18),
          label: Text(w > Duration.zero ? chatWaitLabel(w) : 'Gửi',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    ]);
  }
}
