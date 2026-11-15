// Ngày và đêm: the farm follows the phone's clock. After sunset the village
// darkens, stars come out and the moon shows its real phase for the lunar
// day (no moon on mùng 1, full on rằm). Purely visual.

import 'dart:math' as math;

import 'calendar.dart';
import 'lunar.dart';
import 'weather.dart';

/// Dev screenshots (?hour=21.5 on web): pretend it is this time of day.
double? hourOverride;

/// Local time of day at [ms], in hours (0..24).
double hourAt(int ms) {
  final o = hourOverride;
  if (o != null) return o;
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return d.hour + d.minute / 60 + d.second / 3600;
}

double _smooth(double a, double b, double x) {
  final k = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return k * k * (3 - 2 * k);
}

/// How dark it is: 0 in the day, 1 deep in the night. Dusk 17:40–19:10,
/// dawn 4:50–6:15 (Vietnam's sun hardly moves across the year).
double nightAt(int ms) {
  final h = hourAt(ms);
  return h >= 12 ? _smooth(17.66, 19.16, h) : 1 - _smooth(4.83, 6.25, h);
}

/// Lunar day (1..30) of the night at [ms]: after midnight it is still the
/// evening's moon.
int moonDayAt(int ms) {
  final h = hourAt(ms);
  final day = calendarDay(ms);
  final d = h < 12 && calendarOverride == null ? day.subtract(const Duration(days: 1)) : day;
  return LunarDate.of(d).day;
}

/// The moon on lunar day [day]: lit fraction 0..1 and whether it is waxing
/// (lit on the right).
(double lit, bool waxing) moonPhase(int day) {
  final a = (day - 1 + .5) / 29.53 * 2 * math.pi;
  return ((1 - math.cos(a)) / 2, day <= 15);
}

/// "Trăng lưỡi liềm", "Trăng tròn"...
String moonName(int day) {
  if (day <= 1 || day >= 30) return 'Không trăng';
  if (day <= 5) return 'Trăng non lưỡi liềm';
  if (day <= 9) return 'Trăng thượng huyền';
  if (day <= 13) return 'Trăng gần tròn';
  if (day <= 16) return 'Trăng tròn';
  if (day <= 21) return 'Trăng khuyết dần';
  if (day <= 24) return 'Trăng hạ huyền';
  return 'Trăng tàn lưỡi liềm';
}

String moonIcon(int day) {
  if (day <= 1 || day >= 30) return '🌑';
  if (day <= 5) return '🌒';
  if (day <= 9) return '🌓';
  if (day <= 13) return '🌔';
  if (day <= 16) return '🌕';
  if (day <= 21) return '🌖';
  if (day <= 24) return '🌗';
  return '🌘';
}

/// "mùng 5", "rằm", "16"
String lunarDayName(int day) => day == 15 ? 'rằm' : day <= 10 ? 'mùng $day' : 'ngày $day';

/// The HUD's weather icon: a clear night shows tonight's moon, not the sun.
String skyIcon(Weather w, int ms) =>
    w == Weather.sunny && nightAt(ms) > .5 ? moonIcon(moonDayAt(ms)) : weatherIcon(w);

/// "Trời quang" at night instead of "Nắng đẹp".
String skyName(Weather w, int ms) => w == Weather.sunny && nightAt(ms) > .5 ? 'Đêm trời quang' : weatherName(w);
