// Daily login gift, achievements & titles, weather, tutorial banner.

import 'package:flutter/material.dart';

import '../core/achievements.dart';
import '../core/farm.dart';
import '../core/weather.dart';
import '../services/ads.dart';
import 'sheets.dart' show Report;
import 'widgets.dart';

// ------------------------------------------------------------------ login gift

Widget _rewardView(LoginReward r, {double size = 13}) => Wrap(
      spacing: 4,
      runSpacing: 2,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (r.coins > 0) Coin(r.coins, size: size),
        for (final e in r.goods.entries)
          Row(mainAxisSize: MainAxisSize.min, children: [
            ItemIcon(e.key, size: size + 9),
            Text('×${e.value}', style: TextStyle(fontSize: size - 1, fontWeight: FontWeight.w800, color: brown)),
          ]),
        if (r.xp > 0) Text('+${r.xp} KN', style: TextStyle(fontSize: size - 1, fontWeight: FontWeight.w800, color: greenDark)),
      ],
    );

/// The 7-day gift calendar; today's can be taken (and doubled by an ad).
Future<void> showLoginGift(BuildContext context, Farm farm) async {
  LoginReward? got;
  var doubled = false;
  final today = farm.loginNextDay;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => AlertDialog(
        backgroundColor: cream,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎁 Quà đăng nhập', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, color: brown)),
        content: SizedBox(
          width: 340,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Vào làng mỗi ngày để nhận quà. Bỏ một ngày là tính lại từ đầu!',
                textAlign: TextAlign.center, style: TextStyle(color: brownLight, fontSize: 12.5)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
              for (var d = 1; d <= 7; d++) _dayTile(d, farm.level, today: d == today, taken: d < today || (d == today && got != null)),
            ]),
          ]),
        ),
        actions: [
          Center(
            child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              if (got == null)
                PillButton('Nhận quà ngày $today', color: gold, onTap: () => set(() => got = farm.claimLogin()))
              else ...[
                if (!doubled)
                  ValueListenableBuilder<bool>(
                    valueListenable: AdsService.instance.rewardedReady,
                    builder: (_, ready, _) => ready
                        ? PillButton('📺 Nhân đôi', color: gold, onTap: () async {
                            if (await AdsService.instance.showRewarded('login_double')) {
                              farm.doubleLogin(got!);
                              set(() => doubled = true);
                            }
                          })
                        : const SizedBox.shrink(),
                  ),
                PillButton(doubled ? 'Tuyệt vời! (×2)' : 'Tuyệt vời!', onTap: () => Navigator.pop(c)),
              ],
            ]),
          ),
        ],
      ),
    ),
  );
}

Widget _dayTile(int d, int level, {required bool today, required bool taken}) {
  final r = loginReward(d, level);
  return Container(
    width: d == 7 ? 150 : 72,
    height: 84,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: taken ? const Color(0xFFE6F2D8) : (today ? const Color(0xFFFFF0B8) : Colors.white),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: today ? gold : const Color(0xFFD9B97A), width: today ? 2.5 : 1.5),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Text(taken ? '✅ Ngày $d' : 'Ngày $d',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: today ? const Color(0xFFD84315) : brown)),
      _rewardView(r, size: 11.5),
    ]),
  );
}

// ------------------------------------------------------------------ achievements

class AchievementsSheet extends StatefulWidget {
  final Farm farm;
  final Report report;
  const AchievementsSheet(this.farm, this.report, {super.key});
  @override
  State<AchievementsSheet> createState() => _AchievementsSheetState();
}

class _AchievementsSheetState extends State<AchievementsSheet> {
  Farm get f => widget.farm;

  @override
  Widget build(BuildContext context) {
    final titles = f.earnedTitles;
    final list = [...achievements]..sort((a, b) {
        int rank(AchDef x) => f.achReady(x) ? 0 : (f.achTier(x) >= x.tiers.length ? 2 : 1);
        return rank(a).compareTo(rank(b));
      });
    return Column(children: [
      SheetHeader('🏅 Thành tựu', trailing: Coin(f.coins, size: 15)),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: cardDeco(color: const Color(0xFFFFF6DD)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Danh hiệu hiện trên bản đồ làng',
                  style: TextStyle(fontWeight: FontWeight.w900, color: brown)),
              const SizedBox(height: 6),
              if (titles.isEmpty)
                const Text('Nhận bậc đầu tiên của một thành tựu để có danh hiệu.',
                    style: TextStyle(color: brownLight, fontSize: 12.5))
              else
                Wrap(spacing: 6, runSpacing: 6, children: [
                  _titleChip('', 'Không hiện'),
                  for (final a in titles) _titleChip(a.id, '${a.icon} ${a.title}'),
                ]),
            ]),
          ),
          const SizedBox(height: 8),
          for (final a in list) _card(a),
        ]),
      ),
    ]);
  }

  Widget _titleChip(String id, String label) {
    final on = f.title == id;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: on ? Colors.white : brown, fontSize: 12.5)),
      selected: on,
      selectedColor: green,
      backgroundColor: Colors.white,
      showCheckmark: false,
      onSelected: (_) {
        widget.report(f.setTitle(id), ok: id.isEmpty ? 'Đã ẩn danh hiệu' : 'Danh hiệu mới: $label');
        setState(() {});
      },
    );
  }

  Widget _card(AchDef a) {
    final tier = f.achTier(a);
    final maxed = tier >= a.tiers.length;
    final target = a.tiers[maxed ? a.tiers.length - 1 : tier];
    final v = a.value(f);
    final ready = f.achReady(a);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: cardDeco(color: ready ? const Color(0xFFFFF3C4) : (maxed ? const Color(0xFFE8F5E1) : Colors.white)),
      child: Row(children: [
        Text(a.icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w900, color: brown, fontSize: 14.5)),
              ),
              const SizedBox(width: 6),
              Text('${'★' * tier}${'☆' * (a.tiers.length - tier)}',
                  style: const TextStyle(color: Color(0xFFF2A900), fontSize: 14)),
            ]),
            Text('${a.what}: ${fmtNum(v)}/${fmtNum(target)}',
                style: const TextStyle(color: brownLight, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (v / target).clamp(0.0, 1.0),
                minHeight: 6,
                color: ready || maxed ? gold : green,
                backgroundColor: creamDark,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        if (maxed)
          const Text('Hoàn thành', style: TextStyle(color: greenDark, fontWeight: FontWeight.w900, fontSize: 12))
        else
          PillButton('Nhận',
              dense: true,
              color: gold,
              leading: Coin(achCoins[tier], size: 11, color: Colors.white),
              onTap: ready
                  ? () {
                      widget.report(f.claimAch(a),
                          ok: tier == 0 ? 'Mở danh hiệu "${a.title}"!' : 'Nhận ${fmtNum(achCoins[tier])} xu thưởng!');
                      setState(() {});
                    }
                  : null),
      ]),
    );
  }
}

// ------------------------------------------------------------------ weather

Future<void> showWeather(BuildContext context, Farm farm) {
  final now = farm.now();
  final w = weatherAt(now);
  final ends = weatherEndsAt(now);
  final next = weatherAt(ends);
  return showDialog(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('${weatherIcon(w)} ${weatherName(w)}',
          textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: brown)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(weatherDesc(w), textAlign: TextAlign.center, style: const TextStyle(color: brown, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text('Còn ${fmtTime(ends - now)} · Tiếp theo: ${weatherIcon(next)} ${weatherName(next)}',
            textAlign: TextAlign.center, style: const TextStyle(color: brownLight, fontSize: 12.5)),
        const SizedBox(height: 6),
        const Text('Thời tiết giống nhau ở mọi làng, đổi 3 giờ một lần. Chỉ ảnh hưởng cây gieo lúc đó.',
            textAlign: TextAlign.center, style: TextStyle(color: brownLight, fontSize: 12)),
      ]),
      actions: [Center(child: PillButton('Biết rồi', onTap: () => Navigator.pop(c)))],
    ),
  );
}

// ------------------------------------------------------------------ tutorial

/// "Hướng dẫn" card for new players; [hint] says what to tap.
class TutorialBanner extends StatelessWidget {
  final Farm farm;
  final VoidCallback onSkip, onFinish;
  const TutorialBanner(this.farm, {super.key, required this.onSkip, required this.onFinish});

  static String text(Tut s) => switch (s) {
        Tut.plant => 'Chào mừng về làng! Chạm vào ô ruộng có mũi tên, chọn Lúa để gieo mạ.',
        Tut.harvest => 'Lúa đang lớn (khoảng 2 phút, mọi thứ vẫn lớn khi tắt game). Chín rồi thì chạm để gặt!',
        Tut.order => 'Mở 📋 Đơn hàng bên dưới, giao một đơn cho bà con để lấy xu và kinh nghiệm. Thiếu hàng thì trồng thêm nhé.',
        Tut.build => 'Bấm 🏗️ Xây dựng để làm thêm ruộng, luống rau hoặc chuồng trại.',
        Tut.end => 'Giỏi lắm! Làm theo 📜 nhiệm vụ ở góc trên để nhận thưởng. Chúc bạn vui với làng quê!',
      };

  @override
  Widget build(BuildContext context) {
    final s = farm.tutStep;
    if (s == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: cardDeco(color: const Color(0xFFFFF3C4)),
      child: Row(children: [
        const Text('👩‍🌾', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Hướng dẫn ${s.index + 1}/${Tut.values.length}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFFD84315))),
            Text(text(s), style: const TextStyle(color: brown, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
        if (s == Tut.end)
          PillButton('Chơi thôi!', dense: true, onTap: onFinish)
        else
          TextButton(onPressed: onSkip, child: const Text('Bỏ qua', style: TextStyle(color: brownLight))),
      ]),
    );
  }
}
