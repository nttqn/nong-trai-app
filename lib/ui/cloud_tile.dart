// "Lưu trữ đám mây" block in the ☰ menu: Google sign-in, sync status,
// sign-out, account deletion (Play policy), and the ad privacy choices.

import 'package:flutter/material.dart';

import '../services/ads.dart';
import '../services/cloud.dart';
import 'widgets.dart';

class CloudTile extends StatelessWidget {
  const CloudTile({super.key});

  static const _text = TextStyle(color: brown, height: 1.35);

  @override
  Widget build(BuildContext context) {
    final cs = CloudSave.instance;
    return ListenableBuilder(
      listenable: cs,
      builder: (context, _) {
        final children = <Widget>[];
        if (!cs.available) {
          children.add(const Text('Bản này chưa bật lưu trữ đám mây. Nông trại vẫn được lưu trên máy.', style: _text));
        } else if (cs.user == null) {
          children.addAll([
            const Text('Đăng nhập để lưu nông trại lên mây: cài lại game hay đổi điện thoại vẫn giữ nguyên.',
                style: _text),
            const SizedBox(height: 8),
            PillButton(cs.busy ? 'Đang đăng nhập…' : 'Đăng nhập Google',
                leading: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                onTap: cs.busy ? null : cs.signInGoogle),
          ]);
        } else {
          final t = cs.lastSync;
          final status = cs.busy
              ? 'Đang đồng bộ…'
              : t == null
                  ? 'Chưa đồng bộ'
                  : 'Đã lưu lên mây lúc ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          children.addAll([
            Text('☁️ ${cs.who}', style: _text.copyWith(fontWeight: FontWeight.w800)),
            Text(status, style: _text.copyWith(fontSize: 12.5, color: brownLight)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              PillButton('Đồng bộ ngay', dense: true, onTap: cs.busy ? null : cs.sync),
              PillButton('Đăng xuất', dense: true, color: const Color(0xFF8D6E4C), onTap: cs.busy ? null : cs.signOut),
            ]),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: cs.busy ? null : () => _confirmDelete(context),
                child: const Text('Xóa tài khoản và dữ liệu trên mây', style: TextStyle(color: red, fontSize: 12.5)),
              ),
            ),
          ]);
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ...children,
            ValueListenableBuilder<bool>(
              valueListenable: AdsService.instance.privacyOptionsRequired,
              builder: (_, need, _) => need
                  ? TextButton(
                      onPressed: AdsService.instance.showPrivacyOptions,
                      child: const Text('Tùy chọn quyền riêng tư quảng cáo', style: TextStyle(fontSize: 12.5)),
                    )
                  : const SizedBox.shrink(),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Xóa tài khoản?'),
        content: const Text(
            'Bản lưu trên mây và tài khoản trong game sẽ bị xóa vĩnh viễn. Nông trại trên máy này vẫn còn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Thôi')),
          TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Xóa', style: TextStyle(color: red))),
        ],
      ),
    );
    if (yes == true) await CloudSave.instance.deleteAccount();
  }
}
