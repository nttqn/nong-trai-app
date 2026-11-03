# Làng Quê Yên Bình (working title)

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
