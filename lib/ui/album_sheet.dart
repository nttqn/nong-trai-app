// Album "Ký ức làng quê": a page of memory cards; tapping one opens the
// painting and its story (and the gift the first time).

import 'package:flutter/material.dart';

import '../core/farm.dart';
import '../core/memories.dart';
import 'sheets.dart' show Report;
import 'widgets.dart';

const _paper = Color(0xFFFBF3E2), _ink = Color(0xFF5B4128), _sepia = Color(0xFFB98A55);

/// The painting of a memory (`assets/memories/<id>.jpg`), or a warm sepia
/// card with its icon until the art exists.
class MemoryPicture extends StatelessWidget {
  final MemoryDef m;
  final bool locked;
  const MemoryPicture(this.m, {super.key, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: locked
              ? const [Color(0xFFD9D2C3), Color(0xFFBFB5A2)]
              : m.letter
                  ? const [Color(0xFFFFF8E8), Color(0xFFF1DFB8)]
                  : const [Color(0xFFF6D9A6), Color(0xFFD9A066)],
        ),
      ),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (_, c) => Text(locked ? '🔒' : m.icon, style: TextStyle(fontSize: c.maxHeight * .42)),
      ),
    );
    if (locked) return fallback;
    final pic = Image.asset('assets/memories/${m.id}.jpg',
        fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback, gaplessPlayback: true);
    return pic;
  }
}

class AlbumSheet extends StatefulWidget {
  final Farm farm;
  final Report report;
  const AlbumSheet(this.farm, this.report, {super.key});
  @override
  State<AlbumSheet> createState() => _AlbumSheetState();
}

class _AlbumSheetState extends State<AlbumSheet> {
  @override
  Widget build(BuildContext context) {
    final f = widget.farm;
    final open = memories.where((m) => f.mem.containsKey(m.id)).length;
    return Column(children: [
      SheetHeader('📖 Ký ức làng quê',
          trailing: Text('$open/${memories.length}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: _sepia, fontSize: 16))),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: Text('Mỗi chặng đường ở làng để lại một ký ức. Chạm để đọc, lần đầu đọc có quà.',
            style: TextStyle(fontSize: 12.5, color: brownLight)),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: .92, mainAxisSpacing: 10, crossAxisSpacing: 10),
          itemCount: memories.length,
          itemBuilder: (_, i) => _card(memories[i]),
        ),
      ),
    ]);
  }

  Widget _card(MemoryDef m) {
    final f = widget.farm;
    final st = f.mem[m.id] ?? 0;
    final locked = st == 0;
    return GestureDetector(
      onTap: locked
          ? () => widget.report('Chưa mở: ${m.hint}')
          : () => showMemory(context, f, m, widget.report).then((_) {
                if (mounted) setState(() {});
              }),
      child: Container(
        decoration: BoxDecoration(
          color: locked ? const Color(0xFFEDE6D8) : _paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: locked ? const Color(0xFFCFC4AE) : _sepia, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: MemoryPicture(m, locked: locked)),
              if (st == 1)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Mới 🎁', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 5),
          Text(locked ? '? ? ?' : m.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, color: locked ? brownLight : _ink, fontSize: 13.5)),
          Text(locked ? m.hint : (m.letter ? 'Thư nhà' : ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: brownLight)),
        ]),
      ),
    );
  }
}

/// The memory card: painting, title and story; the gift on first reading.
Future<void> showMemory(BuildContext context, Farm farm, MemoryDef m, Report report, {bool fresh = false}) {
  return showDialog(
    context: context,
    builder: (c) {
      final unread = farm.mem[m.id] == 1;
      return Dialog(
        backgroundColor: _paper,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: _sepia, width: 2)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (fresh)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('📖 Ký ức mới', textAlign: TextAlign.center,
                    style: TextStyle(color: _sepia, fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 1)),
              ),
            if (!m.letter)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(aspectRatio: 4 / 3, child: MemoryPicture(m)),
              ),
            const SizedBox(height: 10),
            Text(m.title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink)),
            const SizedBox(height: 8),
            if (m.letter)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF3),
                  border: Border.all(color: const Color(0xFFE2CFA6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(m.text,
                    style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF2F4A7A), fontStyle: FontStyle.italic)),
              )
            else
              Text(m.text, style: const TextStyle(fontSize: 14.5, height: 1.55, color: _ink)),
            const SizedBox(height: 14),
            Center(
              child: unread
                  ? PillButton('Nhận quà',
                      color: const Color(0xFFB7791F),
                      leading: Coin(m.coins, size: 13, color: Colors.white),
                      onTap: () {
                        report(farm.readMemory(m.id), ok: '+${fmtNum(m.coins)} xu từ ký ức "${m.title}"');
                        Navigator.pop(c);
                      })
                  : PillButton('Đóng', color: _sepia, onTap: () => Navigator.pop(c)),
            ),
          ]),
        ),
      );
    },
  );
}
