// Local reminders ("Lúa chín rồi!"): scheduled when the player leaves,
// cancelled when they come back. No server; Android and iOS only.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/farm.dart';
import '../core/reminders.dart';

class NotifyService {
  NotifyService._();
  static final NotifyService instance = NotifyService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  final enabled = ValueNotifier(true);
  static const _prefKey = 'notify_on', _askedKey = 'notify_asked';

  bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!supported || _ready) return;
    try {
      final p = await SharedPreferences.getInstance();
      enabled.value = p.getBool(_prefKey) ?? true;
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notify'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('notifications unavailable: $e');
    }
  }

  /// Asks for permission once (Android 13+, iOS), after the player has
  /// played a little, not at first launch.
  Future<void> askOnce() async {
    if (!_ready || !enabled.value) return;
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_askedKey) ?? false) return;
      await p.setBool(_askedKey, true);
      await _ask();
    } catch (e) {
      debugPrint('notification permission: $e');
    }
  }

  Future<void> _ask() async {
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: false, sound: true);
  }

  Future<void> setEnabled(bool on) async {
    enabled.value = on;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_prefKey, on);
      if (on) await _ask();
      if (!on) await cancelAll();
    } catch (_) {}
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'farm_reminders',
      'Nhắc việc nông trại',
      channelDescription: 'Báo khi lúa chín, vật nuôi có sản phẩm, xưởng làm xong, quà đăng nhập',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Player left: schedule what will be ready while they are away.
  Future<void> scheduleFor(Farm f) async {
    if (!_ready || !enabled.value) return;
    try {
      await _plugin.cancelAll();
      for (final r in planReminders(f)) {
        await _plugin.zonedSchedule(
          id: r.id,
          scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, r.at),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: r.title,
          body: r.body,
        );
      }
    } catch (e) {
      debugPrint('schedule reminders failed: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
