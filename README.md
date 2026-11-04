# Mùa Lúa Chín – Nông Trại Làng Quê

Flutter farm game set in the Vietnamese countryside: buy land, grow rice and
cash crops, dig fish ponds, raise chickens/ducks/pigs/buffalo/cows, process
goods (gạo, bánh chưng, nước mắm...), fill villagers' orders, upgrade the house
from nhà tranh to biệt thự, and build "nông thôn mới" village projects that
give permanent bonuses.

- `lib/core/` — pure game logic (`farm.dart`), content tables (`defs.dart`),
  quest chain (`quests.dart`), dev demo farms (`demo.dart`).
- `lib/render/` — isometric art, all drawn in code (no image assets).
- `lib/ui/` — single game screen, panels and sheets.
- Real-time growth: timestamps are absolute, so the farm keeps growing offline.

Dev: web build accepts `?demo=0|1|2&house=0..4&zoom=1.4&fx=12&fy=9` for screenshots.
`flutter test` runs the rules tests.

## Âm thanh

- `node tool/gen_audio.js` — tổng hợp 23 hiệu ứng (gieo, gặt, hái, cho ăn, tiếng gà/vịt/lợn/bò/trâu, xây, xu, lên cấp…) vào `assets/audio/*.wav`.
- `node tool/gen_music.js` — soạn 2 bản nhạc nền đồng quê (sáo trúc, đàn bầu, đàn tranh, mõ, song lang, chim hót / dế kêu) vào `build/music/*.wav`; rồi `FFMPEG=<ffmpeg có libvorbis> node tool/encode_music.js` ghi `assets/audio/music/*.ogg` (Android) và `*.m4a` (iOS).
- Hai bản "Đồng quê" (ngày) và "Chiều quê" phát luân phiên; bật/tắt riêng nhạc và hiệu ứng trong menu ☰.
