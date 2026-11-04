// Thời tiết: the same for every player, changing every 3 hours. Rain makes
// crops planted under it grow faster; a dry spell slows them unless the
// village has the pump station (paddy) or the well (beds).

import 'dart:math' as math;

enum Weather { sunny, rain, drought }

const weatherBlockMs = 3 * 3600 * 1000;

/// Dev screenshots (?weather=rain on web): fixed weather.
Weather? weatherOverride;

/// Weather at time [ms] (epoch): about 55% sunny, 30% rain, 15% dry spell.
Weather weatherAt(int ms) {
  final o = weatherOverride;
  if (o != null) return o;
  final block = ms ~/ weatherBlockMs;
  final r = math.Random(block * 7919 + 13).nextInt(100);
  if (r < 30) return Weather.rain;
  if (r < 45) return Weather.drought;
  return Weather.sunny;
}

/// When the weather at [ms] changes.
int weatherEndsAt(int ms) => (ms ~/ weatherBlockMs + 1) * weatherBlockMs;

/// How much faster rain makes crops (fraction of the time saved).
const rainSpeed = .2;

/// How much longer crops take in a dry spell without irrigation.
const droughtSlow = .25;

String weatherIcon(Weather w) => switch (w) {
      Weather.sunny => '☀️',
      Weather.rain => '🌧️',
      Weather.drought => '🔥',
    };

String weatherName(Weather w) => switch (w) {
      Weather.sunny => 'Nắng đẹp',
      Weather.rain => 'Mưa rào',
      Weather.drought => 'Nắng hạn',
    };

String weatherDesc(Weather w) => switch (w) {
      Weather.sunny => 'Trời đẹp, cây lớn bình thường.',
      Weather.rain => 'Gieo trồng lúc trời mưa: cây lớn nhanh hơn ${(rainSpeed * 100).round()}%.',
      Weather.drought =>
        'Gieo trồng lúc nắng hạn: cây lâu hơn ${(droughtSlow * 100).round()}%, trừ khi làng có Trạm bơm (ruộng lúa) hoặc Giếng làng (luống rau).',
    };
