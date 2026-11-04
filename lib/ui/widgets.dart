import 'package:flutter/material.dart';

import '../core/defs.dart';
import '../core/farm.dart';

const cream = Color(0xFFFFF8E7), creamDark = Color(0xFFF3E6C4);
const brown = Color(0xFF5A3D1E), brownLight = Color(0xFF8A6A40);
const green = Color(0xFF5E9E2F), greenDark = Color(0xFF3F7A1C);
const gold = Color(0xFFF2B630), red = Color(0xFFD9534F);

class ItemIcon extends StatelessWidget {
  final String id;
  final double size;
  const ItemIcon(this.id, {super.key, this.size = 34});
  @override
  Widget build(BuildContext context) {
    final d = item(id);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: d.color.withValues(alpha: .55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(d.icon, style: TextStyle(fontSize: size * .55)),
    );
  }
}

/// "icon ×n" with the player's stock, red when short.
class NeedChip extends StatelessWidget {
  final String id;
  final int need, have;
  final double size;
  const NeedChip(this.id, this.need, this.have, {super.key, this.size = 30});
  @override
  Widget build(BuildContext context) {
    final ok = have >= need;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ItemIcon(id, size: size),
        Text('$have/$need',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ok ? greenDark : red)),
      ]),
    );
  }
}

class Coin extends StatelessWidget {
  final int n;
  final double size;
  final Color? color;
  /// Big amounts as 2,97tr / 296k (HUD).
  final bool short;
  const Coin(this.n, {super.key, this.size = 14, this.color, this.short = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text('🪙', style: TextStyle(fontSize: size)),
        const SizedBox(width: 2),
        Text(short ? fmtShort(n) : fmtNum(n),
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color ?? brown)),
      ]);
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Widget? leading;
  final bool dense;
  const PillButton(this.label,
      {super.key, this.onTap, this.color = green, this.leading, this.dense = false});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color : Colors.grey.shade400,
      borderRadius: BorderRadius.circular(20),
      elevation: enabled ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 16, vertical: dense ? 6 : 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            Text(label,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: dense ? 12.5 : 14)),
          ]),
        ),
      ),
    );
  }
}

/// Rounded cream card used by panels and sheets.
BoxDecoration cardDeco({Color color = cream}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD9B97A), width: 2),
      boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 8, offset: Offset(0, 3))],
    );

class SheetHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SheetHeader(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: brown))),
          ?trailing,
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: brownLight)),
        ]),
      );
}

Future<T?> showFarmSheet<T>(BuildContext context, Widget Function(BuildContext) builder,
    {double height = .72}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * height,
      decoration: const BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: Color(0xFFD9B97A), width: 3)),
      ),
      child: SafeArea(top: false, child: builder(ctx)),
    ),
  );
}
