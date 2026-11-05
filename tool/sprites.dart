// ignore_for_file: avoid_print
// Turns AI-generated art in art_src/ into game sprites in assets/sprites/.
//
//   dart run tool/sprites.dart            (all files)
//   dart run tool/sprites.dart nha_0 ga   (only these)
//
// For each art_src/<key>.(png|jpg|jpeg|webp):
//  1. background removal — kept as-is if the image already has real
//     transparency; otherwise the plain background (white, a flat colour or
//     a fake grey/white checkerboard) is flood-filled away from the borders,
//     with a soft edge so outlines do not look cut out;
//  2. trimmed to the visible object;
//  3. scaled down to its on-map size (see maxWidthFor) and written as PNG.
// Then it lists which expected sprites are still missing (see art/PROMPTS.md).
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

final expected = [
  // plots + crops (stage 1 seedling, 2 growing, 3 ripe)
  'ruong', 'luong',
  for (final c in ['lua', 'nep', 'rau', 'ngo', 'khoai', 'lac', 'dau', 'mia', 'ot', 'dua', 'cuc', 'dautuong', 'che', 'tam'])
    for (final s in [1, 2, 3]) '${c}_$s',
  // trees (+ _qua = with ripe fruit)
  for (final t in ['cay_chuoi', 'cay_xoai', 'cay_dua', 'cay_buoi', 'cay_vai', 'cay_nhan', 'cay_hong']) ...[t, '${t}_qua'],
  // animals + pens
  'ga', 'vit', 'lon', 'trau', 'bo', 'de',
  'chuong_ga', 'chuong_vit', 'chuong_lon', 'chuong_trau', 'chuong_bo', 'chuong_de', 'vuon_ong',
  'ao', 'may_xay', 'lo_banh', 'xuong_mia', 'xuong_ca', 'xuong_dau', 'xuong_che',
  'nha_0', 'nha_1', 'nha_2', 'nha_3', 'nha_4',
  'nha_kho_0', 'nha_kho_1', 'nha_kho_2',
  'gieng', 'cong_lang', 'tram_bom', 'tram_dien', 'truong', 'tram_y_te', 'cho_que', 'nha_van_hoa', 'dinh_lang',
  'rom_dong', 'chum', 'bu_nhin', 'cho', 'hoa_dao', 'tre', 'cay_da',
  'bui', 'da', 'goc_cay',
];

/// Optional pose sprites (eating / lying down); not counted as missing.
final optional = [
  for (final a in ['ga', 'vit', 'lon', 'trau', 'bo', 'de']) ...['${a}_an', '${a}_nam'],
];

/// Max width by on-map size: about 3x the largest zoom on a 3x phone.
int maxWidthFor(String key) {
  const animals = {'ga', 'vit', 'lon', 'trau', 'bo', 'de'};
  const big = {'cho_que', 'dinh_lang', 'truong', 'nha_van_hoa'};
  if (animals.contains(key) || animals.any((a) => key == '${a}_an' || key == '${a}_nam')) return 160;
  if (key.startsWith('item_')) return 128;
  if (key.startsWith('nha_') || big.contains(key)) return 512;
  if (key.startsWith('nha_kho')) return 400;
  if (key.startsWith('chuong_') || const {'ao', 'may_xay', 'lo_banh', 'xuong_mia', 'xuong_ca',
      'tram_bom', 'tram_y_te', 'cong_lang', 'cay_da', 'vuon_ong', 'xuong_dau', 'xuong_che'}.contains(key)) {
    return 400;
  }
  return 256;
}
const tol = 46.0;

void main(List<String> args) {
  final src = Directory('art_src');
  final out = Directory('assets/sprites')..createSync(recursive: true);
  if (!src.existsSync()) {
    stderr.writeln('art_src/ not found');
    exit(1);
  }
  final files = src.listSync().whereType<File>().where((f) {
    final n = f.uri.pathSegments.last.toLowerCase();
    return RegExp(r'\.(png|jpe?g|webp)$').hasMatch(n);
  }).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final key = name.substring(0, name.lastIndexOf('.')).toLowerCase();
    if (args.isNotEmpty && !args.contains(key)) continue;
    final decoded = img.decodeImage(f.readAsBytesSync());
    if (decoded == null) {
      print('!! $name: cannot decode');
      continue;
    }
    var im = decoded.convert(numChannels: 4, format: img.Format.uint8);
    final hadAlpha = _transparentShare(im) > .03;
    if (!hadAlpha) _removeBackground(im);
    im = _trim(im);
    final maxWidth = maxWidthFor(key);
    if (im.width > maxWidth) {
      im = img.copyResize(im, width: maxWidth, interpolation: img.Interpolation.cubic);
    }
    File('${out.path}/$key.png').writeAsBytesSync(img.encodePng(im, level: 9));
    final note = expected.contains(key) || optional.contains(key) || key.startsWith('item_') ? '' : '   (tên lạ — kiểm tra lại tên file?)';
    print('ok $key  ${im.width}x${im.height}  ${hadAlpha ? 'nền trong suốt sẵn' : 'đã xóa nền'}$note');
  }
  final have = out.listSync().map((e) => e.uri.pathSegments.last).where((n) => n.endsWith('.png')).map((n) => n.substring(0, n.length - 4)).toSet();
  final missing = expected.where((k) => !have.contains(k)).toList();
  print('\n${expected.length - missing.length}/${expected.length} sprites. Còn thiếu: ${missing.isEmpty ? 'không' : missing.join(', ')}');
}

double _transparentShare(img.Image im) {
  var n = 0;
  for (final p in im) {
    if (p.a < 20) n++;
  }
  return n / (im.width * im.height);
}

double _dist(num r, num g, num b, List<int> c) {
  final dr = r - c[0], dg = g - c[1], db = b - c[2];
  return math.sqrt(dr * dr + dg * dg + db * db);
}

void _removeBackground(img.Image im) {
  final w = im.width, h = im.height;
  // Dominant colours along the border (a checkerboard gives two).
  final buckets = <int, List<int>>{}; // key -> [count, rSum, gSum, bSum]
  var border = 0;
  void sample(int x, int y) {
    final p = im.getPixel(x, y);
    final k = (p.r.toInt() >> 4) << 8 | (p.g.toInt() >> 4) << 4 | (p.b.toInt() >> 4);
    final b = buckets.putIfAbsent(k, () => [0, 0, 0, 0]);
    b[0]++;
    b[1] += p.r.toInt();
    b[2] += p.g.toInt();
    b[3] += p.b.toInt();
    border++;
  }

  for (var x = 0; x < w; x++) {
    sample(x, 0);
    sample(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    sample(0, y);
    sample(w - 1, y);
  }
  final bg = [
    for (final b in buckets.values)
      if (b[0] >= border * .04) [b[1] ~/ b[0], b[2] ~/ b[0], b[3] ~/ b[0]],
  ];
  if (bg.isEmpty) return;
  double minD(int x, int y) {
    final p = im.getPixel(x, y);
    var d = double.infinity;
    for (final c in bg) {
      d = math.min(d, _dist(p.r, p.g, p.b, c));
    }
    return d;
  }

  final gone = List<bool>.filled(w * h, false);
  final queue = <int>[];
  void push(int x, int y) {
    final i = y * w + x;
    if (gone[i] || minD(x, y) > tol) return;
    gone[i] = true;
    queue.add(i);
  }

  for (var x = 0; x < w; x++) {
    push(x, 0);
    push(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    push(0, y);
    push(w - 1, y);
  }
  while (queue.isNotEmpty) {
    final i = queue.removeLast();
    final x = i % w, y = i ~/ w;
    if (x > 0) push(x - 1, y);
    if (x < w - 1) push(x + 1, y);
    if (y > 0) push(x, y - 1);
    if (y < h - 1) push(x, y + 1);
  }
  // Soft edge: pixels touching the background fade by how close they are
  // to the background colour.
  final edge = <int, int>{};
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (gone[i]) continue;
      final touches = (x > 0 && gone[i - 1]) || (x < w - 1 && gone[i + 1]) ||
          (y > 0 && gone[i - w]) || (y < h - 1 && gone[i + w]);
      if (!touches) continue;
      final d = minD(x, y);
      if (d < tol * 2.2) edge[i] = (255 * ((d - tol) / (tol * 1.2)).clamp(.15, 1.0)).round();
    }
  }
  for (var i = 0; i < w * h; i++) {
    if (gone[i]) im.getPixel(i % w, i ~/ w).a = 0;
  }
  edge.forEach((i, a) => im.getPixel(i % w, i ~/ w).a = a);
}

img.Image _trim(img.Image im) {
  var x0 = im.width, y0 = im.height, x1 = -1, y1 = -1;
  for (final p in im) {
    if (p.a > 10) {
      x0 = math.min(x0, p.x);
      y0 = math.min(y0, p.y);
      x1 = math.max(x1, p.x);
      y1 = math.max(y1, p.y);
    }
  }
  if (x1 < 0) return im;
  x0 = math.max(0, x0 - 2);
  y0 = math.max(0, y0 - 2);
  x1 = math.min(im.width - 1, x1 + 2);
  y1 = math.min(im.height - 1, y1 + 2);
  return img.copyCrop(im, x: x0, y: y0, width: x1 - x0 + 1, height: y1 - y0 + 1);
}
