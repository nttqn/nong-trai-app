// Âm lịch Việt Nam (UTC+7), 24 tiết khí and can chi, computed on the phone.
// Port of Hồ Ngọc Đức's astronomical algorithm, the same code as the
// "Lịch Âm Dương" app (scratch/lunar-calendar-app/lib/lunar).

import 'dart:math' as math;

class LunarCalendar {
  LunarCalendar._();

  /// Vietnam is UTC+7.
  static const int vnTimeZone = 7;

  static int _int(double d) => d.floor();

  /// Julian day number (noon convention) for a Gregorian/Julian solar date.
  static int jdFromDate(int dd, int mm, int yy) {
    final a = _int((14 - mm) / 12);
    final y = yy + 4800 - a;
    final m = mm + 12 * a - 3;
    var jd = dd +
        _int((153 * m + 2) / 5) +
        365 * y +
        _int(y / 4) -
        _int(y / 100) +
        _int(y / 400) -
        32045;
    if (jd < 2299161) {
      // Before Gregorian reform (Julian calendar).
      jd = dd + _int((153 * m + 2) / 5) + 365 * y + _int(y / 4) - 32083;
    }
    return jd;
  }

  /// Inverse of [jdFromDate]: returns (day, month, year).
  static (int, int, int) jdToDate(int jd) {
    int a, b, c;
    if (jd > 2299160) {
      a = jd + 32044;
      b = _int((4 * a + 3) / 146097);
      c = a - _int(b * 146097 / 4);
    } else {
      b = 0;
      c = jd + 32082;
    }
    final d = _int((4 * c + 3) / 1461);
    final e = c - _int(1461 * d / 4);
    final m = _int((5 * e + 2) / 153);
    final day = e - _int((153 * m + 2) / 5) + 1;
    final month = m + 3 - 12 * _int(m / 10);
    final year = b * 100 + d - 4800 + _int(m / 10);
    return (day, month, year);
  }

  /// Julian date (fractional day) of the k-th new moon after 1900-01-01,
  /// per the mean-motion + periodic-correction terms of the algorithm.
  static double _newMoon(int k) {
    final t = k / 1236.85;
    final t2 = t * t;
    final t3 = t2 * t;
    const dr = math.pi / 180;
    var jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;
    jd1 += 0.00033 * math.sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);

    final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final mpr = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;

    var c1 = (0.1734 - 0.000393 * t) * math.sin(m * dr) + 0.0021 * math.sin(2 * dr * m);
    c1 = c1 - 0.4068 * math.sin(mpr * dr) + 0.0161 * math.sin(dr * 2 * mpr);
    c1 = c1 - 0.0004 * math.sin(dr * 3 * mpr);
    c1 = c1 + 0.0104 * math.sin(dr * 2 * f) - 0.0051 * math.sin(dr * (m + mpr));
    c1 = c1 - 0.0074 * math.sin(dr * (m - mpr)) + 0.0004 * math.sin(dr * (2 * f + m));
    c1 = c1 - 0.0004 * math.sin(dr * (2 * f - m)) - 0.0006 * math.sin(dr * (2 * f + mpr));
    c1 = c1 + 0.0010 * math.sin(dr * (2 * f - mpr)) + 0.0005 * math.sin(dr * (2 * mpr + m));

    double deltaT;
    if (t < -11) {
      deltaT = 0.001 + 0.000839 * t + 0.0002261 * t2 - 0.00000845 * t3 - 0.000000081 * t * t3;
    } else {
      deltaT = -0.000278 + 0.000265 * t + 0.000262 * t2;
    }
    return jd1 + c1 - deltaT;
  }

  /// True solar longitude (radians, normalized to [0, 2π)) at the given
  /// Julian day number.
  static double _sunLongitude(double jdn) {
    final t = (jdn - 2451545.0) / 36525;
    final t2 = t * t;
    const dr = math.pi / 180;
    final m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2;
    final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(dr * m);
    dl = dl + (0.019993 - 0.000101 * t) * math.sin(dr * 2 * m) + 0.000290 * math.sin(dr * 3 * m);
    var l = (l0 + dl) * dr;
    l = l - math.pi * 2 * _int(l / (math.pi * 2));
    return l;
  }

  /// Sun longitude expressed in 30-degree "solar month" slots (0-11), as
  /// observed at local midnight for the given Julian day number.
  static int _sunLongitudeSlot(int dayNumber, int timeZone) {
    return _int(_sunLongitude(dayNumber - 0.5 - timeZone / 24) / math.pi * 6);
  }

  /// Julian day number of the k-th new moon, in local time for [timeZone].
  static int _newMoonDay(int k, int timeZone) {
    return _int(_newMoon(k) + 0.5 + timeZone / 24);
  }

  /// Julian day number of the start of lunar month 11 (which always
  /// contains the winter solstice) for solar year [yy].
  static int _lunarMonth11(int yy, int timeZone) {
    final off = jdFromDate(31, 12, yy) - 2415021;
    final k = _int(off / 29.530588853);
    var nm = _newMoonDay(k, timeZone);
    final sunLong = _sunLongitudeSlot(nm, timeZone);
    if (sunLong >= 9) {
      nm = _newMoonDay(k - 1, timeZone);
    }
    return nm;
  }

  /// How many lunar months after month 11 the leap month falls, for the
  /// leap year whose month-11 starts at Julian day [a11].
  static int _leapMonthOffset(int a11, int timeZone) {
    final k = _int((a11 - 2415021.076998695) / 29.530588853 + 0.5);
    var last = 0;
    var i = 1;
    var arc = _sunLongitudeSlot(_newMoonDay(k + i, timeZone), timeZone);
    do {
      last = arc;
      i++;
      arc = _sunLongitudeSlot(_newMoonDay(k + i, timeZone), timeZone);
    } while (arc != last && i < 14);
    return i - 1;
  }

  /// Converts a solar (Gregorian) date to its lunar equivalent.
  ///
  /// Returns (lunarDay, lunarMonth, lunarYear, isLeapMonth).
  static (int, int, int, bool) solarToLunar(int dd, int mm, int yy,
      {int timeZone = vnTimeZone}) {
    final dayNumber = jdFromDate(dd, mm, yy);
    final k = _int((dayNumber - 2415021.076998695) / 29.530588853);
    var monthStart = _newMoonDay(k + 1, timeZone);
    if (monthStart > dayNumber) {
      monthStart = _newMoonDay(k, timeZone);
    }
    var a11 = _lunarMonth11(yy, timeZone);
    int b11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = yy;
      b11 = a11;
      a11 = _lunarMonth11(yy - 1, timeZone);
    } else {
      lunarYear = yy + 1;
      b11 = _lunarMonth11(yy + 1, timeZone);
    }
    final lunarDay = dayNumber - monthStart + 1;
    final diff = _int((monthStart - a11) / 29);
    var lunarLeap = false;
    var lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
      final leapMonthDiff = _leapMonthOffset(a11, timeZone);
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        if (diff == leapMonthDiff) {
          lunarLeap = true;
        }
      }
    }
    if (lunarMonth > 12) {
      lunarMonth -= 12;
    }
    if (lunarMonth >= 11 && diff < 4) {
      lunarYear -= 1;
    }
    return (lunarDay, lunarMonth, lunarYear, lunarLeap);
  }

  /// Converts a lunar date back to its solar equivalent. Returns null if
  /// [lunarLeap] is requested for a month that wasn't actually leap in
  /// [lunarYear].
  static (int, int, int)? lunarToSolar(
      int lunarDay, int lunarMonth, int lunarYear, bool lunarLeap,
      {int timeZone = vnTimeZone}) {
    int a11, b11;
    if (lunarMonth < 11) {
      a11 = _lunarMonth11(lunarYear - 1, timeZone);
      b11 = _lunarMonth11(lunarYear, timeZone);
    } else {
      a11 = _lunarMonth11(lunarYear, timeZone);
      b11 = _lunarMonth11(lunarYear + 1, timeZone);
    }
    final k = _int(0.5 + (a11 - 2415021.076998695) / 29.530588853);
    var off = lunarMonth - 11;
    if (off < 0) {
      off += 12;
    }
    if (b11 - a11 > 365) {
      final leapOff = _leapMonthOffset(a11, timeZone);
      var leapMonth = leapOff - 2;
      if (leapMonth < 0) {
        leapMonth += 12;
      }
      if (lunarLeap && lunarMonth != leapMonth) {
        return null;
      } else if (lunarLeap || off >= leapOff) {
        off += 1;
      }
    }
    final monthStart = _newMoonDay(k + off, timeZone);
    return jdToDate(monthStart + lunarDay - 1);
  }

  /// Tiết khí (0 = Xuân phân … 23 = Kinh trập) in force on a solar date:
  /// the sun's longitude in 15° steps at local noon.
  static int solarTerm(int dd, int mm, int yy, {int timeZone = vnTimeZone}) {
    final jd = jdFromDate(dd, mm, yy);
    return _int(_sunLongitude(jd - timeZone / 24) / math.pi * 12) % 24;
  }
}

/// A day of the lunar calendar.
class LunarDate {
  final int day, month, year;
  final bool leap;
  const LunarDate(this.day, this.month, this.year, this.leap);

  factory LunarDate.of(DateTime d) {
    final (dd, mm, yy, leap) = LunarCalendar.solarToLunar(d.day, d.month, d.year);
    return LunarDate(dd, mm, yy, leap);
  }

  /// "16/9" (with "nhuận" for a leap month).
  String get short => '$day/$month${leap ? ' nhuận' : ''}';

  /// "Bính Ngọ"
  String get yearName => canChiYear(year);

  @override
  String toString() => '$short/$year';
}

const _can = ['Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'];
const _chi = ['Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'];

String canChiYear(int y) => '${_can[(y + 6) % 10]} ${_chi[(y + 8) % 12]}';

/// Solar date of a lunar day (null if that leap month does not exist).
DateTime? solarOf(int day, int month, int year, {bool leap = false}) {
  final r = LunarCalendar.lunarToSolar(day, month, year, leap);
  return r == null ? null : DateTime(r.$3, r.$2, r.$1);
}

const solarTermNames = [
  'Xuân phân', 'Thanh minh', 'Cốc vũ', 'Lập hạ', 'Tiểu mãn', 'Mang chủng',
  'Hạ chí', 'Tiểu thử', 'Đại thử', 'Lập thu', 'Xử thử', 'Bạch lộ',
  'Thu phân', 'Hàn lộ', 'Sương giáng', 'Lập đông', 'Tiểu tuyết', 'Đại tuyết',
  'Đông chí', 'Tiểu hàn', 'Đại hàn', 'Lập xuân', 'Vũ thủy', 'Kinh trập',
];
