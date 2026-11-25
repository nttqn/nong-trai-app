import 'dart:convert';
import 'dart:io' show HttpClient, Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_version.dart';
import '../core/version.dart';
import '../ui/widgets.dart';
import 'analytics.dart';
import 'cloud.dart';

/// Cập nhật trong game (1.10.0, as in Kiếm Hiệp): asks the store whether a
/// newer build is out and offers it once a day (Android: Play's in-app
/// update; iOS: Apple's lookup, then the App Store page). The oldest
/// version still allowed to play is `min` in the Firestore document
/// `config/app` (written by hand in the console; `minIos` on iPhone when
/// set); below it the game is
/// blocked until the player updates.
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  bool _checked = false;

  /// The game's App Store page once the lookup found it (share links).
  String? appStoreUrl;

  /// [save] writes the farm before Play restarts the game.
  Future<void> check(BuildContext context, Future<void> Function() save) async {
    if (_checked || kIsWeb) return;
    if (Platform.isIOS) return _checkIos(context, save);
    if (!Platform.isAndroid) return;
    _checked = true;
    final min = await _minVersion();
    AppUpdateInfo? info;
    try {
      info = await InAppUpdate.checkForUpdate().timeout(const Duration(seconds: 8));
    } catch (e) {
      // Not installed from Play (a sideloaded or debug build), or offline.
      debugPrint('update check: $e');
    }
    if (mustUpdate(appVersion, min)) {
      if (context.mounted) await _block(context, info, save);
      return;
    }
    if (info == null || info.updateAvailability != UpdateAvailability.updateAvailable) return;
    final prefs = await SharedPreferences.getInstance();
    final n = DateTime.now();
    final today = '${n.year}-${n.month}-${n.day}';
    final plan = updatePlan(
      available: true,
      current: appVersion,
      min: min,
      snoozedToday: prefs.getString('update_snooze') == today,
    );
    if (plan == UpdatePlan.none || !context.mounted) return;
    if (!info.flexibleUpdateAllowed && !info.immediateUpdateAllowed) return;
    Analytics.instance.log('update_prompt', {'force': 0});
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Có bản cập nhật mới'),
        content: const Text(
          'Bản mới có thêm tính năng và sửa lỗi. Tải ngầm, vẫn chơi được trong lúc tải; '
          'xong sẽ khởi động lại game, nông trại được giữ nguyên.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để mai')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cập nhật')),
        ],
      ),
    );
    if (yes != true) {
      await prefs.setString('update_snooze', today);
      return;
    }
    try {
      if (info.flexibleUpdateAllowed) {
        final r = await InAppUpdate.startFlexibleUpdate();
        if (r != AppUpdateResult.success) return;
        // Downloaded: save, then let Play install and restart the game.
        await save();
        await InAppUpdate.completeFlexibleUpdate();
      } else {
        await save();
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('update: $e');
    }
  }

  static const _store = MethodChannel('nt/store');

  /// Bắt buộc cập nhật: this version is below `min`, so the farm is covered
  /// by a dialog that Back and taps outside cannot close. "Cập nhật" runs
  /// Play's update when Play already knows of it, otherwise opens the
  /// game's Play page; coming back without updating stays here.
  Future<void> _block(BuildContext context, AppUpdateInfo? info, Future<void> Function() save) async {
    Analytics.instance.log('update_prompt', {'force': 1});
    await save();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: cream,
          title: const Text('Cần cập nhật'),
          content: const Text(
            'Phiên bản $appVersion đã cũ. Hãy cập nhật bản mới trên Google Play để tiếp tục chơi. '
            'Nông trại của bạn được giữ nguyên.',
          ),
          actions: [
            TextButton(onPressed: () => _updateNow(info), child: const Text('Cập nhật')),
          ],
        ),
      ),
    );
  }

  Future<void> _updateNow(AppUpdateInfo? first) async {
    var info = first;
    try {
      // Play may have learned of the build since the game started.
      info = await InAppUpdate.checkForUpdate().timeout(const Duration(seconds: 8));
    } catch (_) {}
    if (info != null &&
        info.updateAvailability == UpdateAvailability.updateAvailable &&
        info.immediateUpdateAllowed) {
      try {
        // Restarts the game when done; closing Play's sheet returns here.
        await InAppUpdate.performImmediateUpdate();
        return;
      } catch (e) {
        debugPrint('immediate update: $e');
      }
    }
    try {
      await _store.invokeMethod<bool>('openStore');
    } catch (e) {
      debugPrint('open store: $e');
    }
  }

  // ------------------------------------------------------------------ iOS

  static const _bundleId = 'com.trungsmail.nongtrai';

  /// iOS has no in-app update: Apple's lookup gives the App Store's version
  /// and the game's page, which "Cập nhật" opens. The same `min` blocks.
  Future<void> _checkIos(BuildContext context, Future<void> Function() save) async {
    _checked = true;
    final (min, store) = await (_minVersion(), _appStore()).wait;
    if (store != null) appStoreUrl = store.url;
    final url = store?.url ?? 'https://apps.apple.com/vn/search?term=${Uri.encodeComponent('Mùa Lúa Chín')}';
    if (mustUpdate(appVersion, min)) {
      Analytics.instance.log('update_prompt', {'force': 1});
      await save();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: cream,
            title: const Text('Cần cập nhật'),
            content: const Text(
              'Phiên bản $appVersion đã cũ. Hãy cập nhật bản mới trên App Store để tiếp tục chơi. '
              'Nông trại của bạn được giữ nguyên.',
            ),
            actions: [
              TextButton(onPressed: () => _open(url), child: const Text('Cập nhật')),
            ],
          ),
        ),
      );
      return;
    }
    if (store == null || compareVersions(store.version, appVersion) <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final n = DateTime.now();
    final today = '${n.year}-${n.month}-${n.day}';
    if (prefs.getString('update_snooze') == today || !context.mounted) return;
    Analytics.instance.log('update_prompt', {'force': 0});
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Có bản cập nhật mới'),
        content: Text('Bản ${store.version} đã có trên App Store, với tính năng mới và sửa lỗi. '
            'Nông trại của bạn được giữ nguyên.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để mai')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cập nhật')),
        ],
      ),
    );
    if (yes == true) {
      await save();
      await _open(url);
    } else {
      await prefs.setString('update_snooze', today);
    }
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('open store: $e');
    }
  }

  /// The App Store's version of this game and its page; null when it is not
  /// listed (yet) or can't be read.
  Future<({String version, String url})?> _appStore() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.getUrl(Uri.parse(
          'https://itunes.apple.com/lookup?bundleId=$_bundleId&country=vn&t=${DateTime.now().millisecondsSinceEpoch}'));
      final res = await req.close().timeout(const Duration(seconds: 8));
      final body = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 8));
      final results = (jsonDecode(body) as Map)['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final r = results.first as Map;
      final v = r['version'], u = r['trackViewUrl'];
      if (v is! String || u is! String) return null;
      return (version: v, url: u);
    } catch (e) {
      debugPrint('app store lookup: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _minVersion() async {
    if (!CloudSave.instance.available) return null;
    try {
      final doc = await FirebaseFirestore.instance.doc('config/app').get().timeout(const Duration(seconds: 6));
      // iOS may have its own floor (`minIos`): App Review often lags Play
      final d = doc.data();
      final v = Platform.isIOS && d?['minIos'] is String ? d!['minIos'] : d?['min'];
      return v is String ? v : null;
    } catch (_) {
      return null;
    }
  }
}
