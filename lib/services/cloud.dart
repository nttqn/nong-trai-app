import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/farm.dart';
import '../core/sync_plan.dart';
import 'analytics.dart';
import 'leaderboard.dart';
import 'market.dart';
import 'neighbors.dart';

/// The account's copy of the farm, as read from Firestore.
class CloudCopy {
  final SaveInfo info;
  final String data;
  const CloudCopy(this.info, this.data);
}

/// Online save: the farm mirrored to Firestore under the signed-in player
/// (`farms/{uid}`), so reinstalling or changing phone keeps it.
///
/// Everything degrades to offline play: no Firebase config, no network or
/// a failed sign-in just leaves [available] or [user] unset.
class CloudSave extends ChangeNotifier {
  CloudSave._();
  static final CloudSave instance = CloudSave._();

  static const _ownerKey = 'cloud_owner', _syncedKey = 'cloud_synced_at';

  bool available = false;
  bool busy = false;
  User? user;
  String? message;
  DateTime? lastSync;

  /// Set when this device and the account both have a farm and the player
  /// must pick one.
  CloudCopy? conflict;

  /// The farm being played, and how to swap in a restored one; both set by
  /// the app shell.
  Farm Function()? current;
  Future<void> Function(Farm restored)? replace;

  bool _googleReady = false;
  Timer? _debounce;
  bool _dirty = false;
  AppLifecycleListener? _lifecycle;
  SharedPreferences? _prefs;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      // Android reads google-services.json through Gradle; throws when the
      // game was built without it.
      await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      available = true;
    } catch (e) {
      debugPrint('cloud save off: $e');
      return;
    }
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
    });
    _lifecycle ??= AppLifecycleListener(onPause: flush, onDetach: flush);
    notifyListeners();
  }

  /// Signed in on an earlier run: sync once the farm is on screen.
  void start() {
    if (available && user != null) unawaited(sync());
  }

  String get who => user?.email ?? user?.displayName ?? 'Đã đăng nhập';

  // ------------------------------------------------------------ sign-in

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  Future<bool> signInGoogle() async {
    if (!available || busy) return false;
    busy = true;
    message = null;
    notifyListeners();
    try {
      try {
        await _initGoogle();
        final account = await GoogleSignIn.instance.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null) throw StateError('no id token');
        await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) rethrow;
        // Credential Manager fails on some phones: use the browser flow.
        _logFail('gsi_${e.code.name}', e.description);
        await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
      }
      user = FirebaseAuth.instance.currentUser;
      Analytics.instance.log('login', {'method': 'google'});
      busy = false;
      await sync();
      return user != null;
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _logFail('gsi_${e.code.name}', e.description);
        message = 'Đăng nhập Google thất bại (${e.code.name})';
      }
    } on FirebaseAuthException catch (e) {
      _logFail('fb_${e.code}', e.message);
      message = e.code == 'web-context-canceled' || e.code == 'canceled'
          ? null
          : 'Không đăng nhập được (${e.code}), thử lại sau';
    } catch (e) {
      _logFail('other', e);
      message = 'Không đăng nhập được, thử lại sau';
    }
    busy = false;
    notifyListeners();
    return false;
  }

  void _logFail(String code, Object? detail) {
    final d = '$detail';
    Analytics.instance.log('signin_fail', {'code': code, 'detail': d.length > 90 ? d.substring(0, 90) : d});
  }

  Future<void> signOut() async {
    await flush();
    try {
      await FirebaseAuth.instance.signOut();
      if (_googleReady) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    user = null;
    conflict = null;
    lastSync = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ data

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance.collection('farms').doc(user!.uid);

  static SaveInfo _info(Farm f) => SaveInfo(f.savedAt, f.level, f.xp);

  bool get _mine => _prefs?.getString(_ownerKey) == user?.uid;
  int get _syncedAt => _mine ? (_prefs?.getInt(_syncedKey) ?? 0) : 0;

  Future<void> _markSynced(int savedAt) async {
    await _prefs?.setString(_ownerKey, user!.uid);
    await _prefs?.setInt(_syncedKey, savedAt);
    lastSync = DateTime.now();
  }

  Future<CloudCopy?> _fetch() async {
    final snap = await _doc.get().timeout(const Duration(seconds: 15));
    final m = snap.data();
    if (m == null || m['data'] is! String) return null;
    return CloudCopy(
      SaveInfo((m['savedAt'] as num?)?.toInt() ?? 0, (m['level'] as num?)?.toInt() ?? 1, (m['xp'] as num?)?.toInt() ?? 0),
      m['data'] as String,
    );
  }

  /// Compares this device's farm with the account's and acts on it.
  Future<void> sync() async {
    final f = current?.call();
    if (!available || user == null || busy || f == null) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      final cloud = await _fetch();
      final plan = planSync(local: _info(f), mine: _mine, syncedAt: _syncedAt, cloud: cloud?.info);
      switch (plan) {
        case SyncAction.upload:
          await _upload(f);
        case SyncAction.restore:
          await _restore(cloud!);
        case SyncAction.ask:
          conflict = cloud;
        case SyncAction.none:
          await _markSynced(f.savedAt);
      }
      if (conflict == null) {
        final cur = current?.call();
        if (cur != null) {
          Neighbors.instance.setMyName(cur.name);
          unawaited(Neighbors.instance.publish(cur));
          unawaited(Neighbors.instance.pull(cur, force: true));
        }
      }
    } catch (e) {
      debugPrint('sync failed: $e');
      message = 'Không kết nối được máy chủ, sẽ thử lại sau';
    }
    busy = false;
    notifyListeners();
  }

  Future<void> _upload(Farm f) async {
    await _doc.set({
      'data': jsonEncode(f.toJson()),
      'savedAt': f.savedAt,
      'level': f.level,
      'xp': f.xp,
      'coins': f.coins,
      'updated': FieldValue.serverTimestamp(),
    });
    await _markSynced(f.savedAt);
    await Leaderboard.instance.submit(f);
    Neighbors.instance.setMyName(f.name);
    await Neighbors.instance.publish(f);
  }

  Future<void> _restore(CloudCopy c) async {
    final farm = Farm.fromJson(jsonDecode(c.data) as Map<String, dynamic>);
    await replace?.call(farm);
    await _markSynced(farm.savedAt);
    unawaited(Leaderboard.instance.submit(farm));
    Analytics.instance.log('cloud_restore', {'level': farm.level});
  }

  /// The player chose the account's farm over this device's.
  Future<void> takeCloud() async {
    final c = conflict;
    conflict = null;
    if (c != null) {
      try {
        await _restore(c);
      } catch (e) {
        message = 'Bản lưu trên mây bị lỗi, giữ bản trên máy';
      }
    }
    notifyListeners();
  }

  /// The player chose this device's farm: it replaces the account's.
  Future<void> keepLocal() async {
    conflict = null;
    final f = current?.call();
    if (f != null && user != null) {
      try {
        await _upload(f);
      } catch (e) {
        message = 'Chưa tải lên được, sẽ thử lại sau';
      }
    }
    notifyListeners();
  }

  /// After every local save: upload at most every three minutes, and when
  /// the app goes to the background.
  void queueUpload() {
    if (!available || user == null || conflict != null || !_mine) return;
    _dirty = true;
    _debounce ??= Timer(const Duration(minutes: 3), flush);
  }

  Future<void> flush() async {
    _debounce?.cancel();
    _debounce = null;
    if (!available || user == null || !_dirty || conflict != null) return;
    final f = current?.call();
    if (f == null) return;
    _dirty = false;
    try {
      // never overwrite a bigger farm in the account without asking
      final c = await _fetch();
      if (c != null && c.info.level > f.level) {
        conflict = c;
        notifyListeners();
        return;
      }
      await _upload(f);
      notifyListeners();
    } catch (e) {
      // Firestore queues writes offline; anything else retries next save.
      _dirty = true;
      debugPrint('upload failed: $e');
    }
  }

  /// "Chơi lại từ đầu": the account's farm goes too, or the next sync
  /// would bring it straight back.
  Future<void> wipeCloudFarm() async {
    _debounce?.cancel();
    _debounce = null;
    _dirty = false;
    conflict = null;
    if (!available || user == null) return;
    await Leaderboard.instance.withdraw();
    await Neighbors.instance.withdraw();
    try {
      await _doc.delete().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('wipe failed: $e');
    }
    await _prefs?.remove(_ownerKey);
    await _prefs?.remove(_syncedKey);
  }

  /// Deletes the cloud farm and the account (Play policy: possible in the
  /// app). The farm on this device stays.
  Future<bool> deleteAccount() async {
    final u = user;
    if (!available || u == null || busy) return false;
    busy = true;
    message = null;
    _debounce?.cancel();
    _debounce = null;
    _dirty = false;
    notifyListeners();
    try {
      await Leaderboard.instance.withdraw();
      await Neighbors.instance.withdraw();
      await Market.instance.removeAll(u.uid);
      await _doc.delete();
      try {
        await u.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        await _initGoogle();
        final account = await GoogleSignIn.instance.authenticate();
        await u.reauthenticateWithCredential(GoogleAuthProvider.credential(idToken: account.authentication.idToken));
        await u.delete();
      }
      if (_googleReady) await GoogleSignIn.instance.signOut();
      await _prefs?.remove(_ownerKey);
      await _prefs?.remove(_syncedKey);
      user = null;
      conflict = null;
      lastSync = null;
      message = 'Đã xóa tài khoản và bản lưu trên mây. Nông trại trên máy vẫn còn.';
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('delete account failed: $e');
      message = 'Chưa xóa được tài khoản, thử lại sau.';
      busy = false;
      notifyListeners();
      return false;
    }
  }
}
