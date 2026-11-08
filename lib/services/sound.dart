import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound effects (`tool/gen_audio.js`) and background music, two folk loops
/// that alternate (`tool/gen_music.js`). Separate on/off switches for each.
/// Every call is a safe no-op until loading finishes, when muted, or if an
/// asset fails to load.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const sfxFiles = [
    'tap', 'error', 'plant', 'harvest', 'pick', 'feed', 'sparkle', 'splash',
    'build', 'chop', 'remove', 'place', 'work', 'collect', 'coin', 'cash',
    'quest', 'levelup', 'ga', 'vit', 'lon', 'bo', 'trau', 'de', 'ong',
  ];
  static const tracks = ['dong_que', 'chieu_que'];

  final ValueNotifier<bool> sfxOn = ValueNotifier<bool>(true);
  final ValueNotifier<bool> musicOn = ValueNotifier<bool>(true);

  final Map<String, _Pool> _pools = {};
  final Map<String, DateTime> _last = {};
  AudioPlayer? _music;
  int _track = 0;
  bool _loaded = false; // a track is set on the music player
  bool _ready = false;
  bool _foreground = true;
  AppLifecycleListener? _lifecycle;

  static const _musicVolume = 0.42;

  /// iOS cannot play Ogg; everything else gets the gapless Ogg files.
  static String get _ext =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? 'm4a' : 'ogg';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      sfxOn.value = prefs.getBool('sfx_on') ?? true;
      musicOn.value = prefs.getBool('music_on') ?? true;
    } catch (_) {}
    // Nothing here needs audio focus; taking it would let each effect pause
    // the music on Android (and stop other apps' audio).
    if (!kIsWeb) {
      try {
        await AudioPlayer.global.setAudioContext(AudioContext(
          android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ));
      } catch (_) {}
    }
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.release);
      // One track ends -> the other one starts.
      p.onPlayerComplete.listen((_) {
        _track = (_track + 1) % tracks.length;
        _loaded = false;
        _applyMusic();
      });
      _music = p;
    } catch (_) {}
    _ready = true;
    _lifecycle ??= AppLifecycleListener(onStateChange: (s) {
      _foreground = s == AppLifecycleState.resumed;
      _applyMusic();
    });
    _applyMusic();
    for (final f in sfxFiles) {
      try {
        _pools[f] = await _Pool.create('audio/$f.wav', f == 'tap' || f == 'plant' ? 3 : 2)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('sfx $f failed: $e');
      }
    }
  }

  void _applyMusic() {
    final m = _music;
    if (m == null || !_ready) return;
    final should = musicOn.value && _foreground;
    if (!should) {
      if (m.state == PlayerState.playing) _guard(m.pause());
      return;
    }
    if (!_loaded) {
      _loaded = true;
      () async {
        try {
          await m.setVolume(_musicVolume);
          await m
              .setSource(AssetSource('audio/music/${tracks[_track]}.$_ext'))
              .timeout(const Duration(seconds: 8));
          if (musicOn.value && _foreground) await m.resume();
        } catch (_) {
          _loaded = false;
        }
      }();
      return;
    }
    if (m.state != PlayerState.playing) _guard(m.resume());
  }

  /// Plays effect [name] (a file in [sfxFiles]).
  void play(String name, {double volume = 1}) {
    // Browsers refuse audio before the first tap; effects follow taps, so
    // this is where blocked music gets going.
    if (kIsWeb) _applyMusic();
    if (!sfxOn.value) return;
    final now = DateTime.now();
    final last = _last[name];
    // Rapid repeats (planting a row in plant mode) collapse a little.
    if (last != null && now.difference(last).inMilliseconds < 60) return;
    _last[name] = now;
    _pools[name]?.start(volume);
  }

  Future<void> toggleSfx() async {
    sfxOn.value = !sfxOn.value;
    await _store('sfx_on', sfxOn.value);
  }

  Future<void> toggleMusic() async {
    musicOn.value = !musicOn.value;
    _applyMusic();
    await _store('music_on', musicOn.value);
  }

  static Future<void> _store(String k, bool v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(k, v);
    } catch (_) {}
  }

  static void _guard(Future<void>? f) {
    f?.catchError((Object _) {});
  }
}

/// A few players for one effect, used round-robin. On Android they use
/// SoundPool (low latency, and no completion callback — MediaPlayer's
/// completion re-prepare crashes some old phones).
class _Pool {
  _Pool._(this._players);
  final List<AudioPlayer> _players;
  int _next = 0;

  static Future<_Pool> create(String asset, int size) async {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final players = <AudioPlayer>[];
    for (var i = 0; i < size; i++) {
      final p = AudioPlayer();
      if (android) await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSource(AssetSource(asset));
      players.add(p);
    }
    return _Pool._(players);
  }

  void start(double volume) {
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    () async {
      try {
        // SoundPool never reports completion, so the player may still count
        // as playing; stop first or resume() is ignored.
        await p.stop();
        await p.setVolume(volume);
        await p.resume();
      } catch (_) {}
    }();
  }
}
