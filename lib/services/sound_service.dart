import 'package:audioplayers/audioplayers.dart';

/// Plays short sound effects for game-like feedback.
///
/// Call [init] once at app startup (after WidgetsFlutterBinding.ensureInitialized)
/// to pre-load each sound into a dedicated [AudioPlayer] with [ReleaseMode.stop].
///
/// Using a persistent player per track (rather than creating a new one per call)
/// is the fix for Samsung devices where rapid AudioPlayer construction causes
/// the Android audio HAL to silently drop sounds.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _enabled = true;
  bool _initialized = false;

  void setEnabled(bool v) => _enabled = v;

  AudioPlayer? _increment;
  AudioPlayer? _undo;
  AudioPlayer? _questComplete;
  AudioPlayer? _levelUp;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Configure the global Android audio context for short game sound effects.
    // AndroidAudioFocus.none prevents us from stealing audio focus from music,
    // and AndroidContentType.sonification / AndroidUsageType.game tell Samsung's
    // audio HAL to route through the game sound path, bypassing Dolby Atmos
    // post-processing that can delay or silence short clips.
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
            stayAwake: false,
            isSpeakerphoneOn: false,
          ),
        ),
      );
    } catch (_) {
      // Older Android versions may not support all options; silently continue.
    }

    // Pre-load one player per track.  ReleaseMode.stop keeps the native
    // MediaPlayer / ExoPlayer instance alive between plays so subsequent
    // play calls have no cold-start latency.
    _increment = await _makePlayer('sounds/progress_up.wav');
    _undo = await _makePlayer('sounds/progress_down.wav');
    _questComplete = await _makePlayer('sounds/quest_complete.wav');
    _levelUp = await _makePlayer('sounds/level_up.wav');
  }

  static Future<AudioPlayer?> _makePlayer(String asset) async {
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSourceAsset(asset);
      return p;
    } catch (_) {
      return null;
    }
  }

  Future<void> _play(AudioPlayer? player) async {
    if (!_enabled || player == null) return;
    try {
      // Stop any in-progress playback, seek to start, then resume.
      // On Samsung ExoPlayer the stop→seek→resume sequence is more reliable
      // than calling play() again (which re-parses the source).
      await player.stop();
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      // Silently skip on platform errors.
    }
  }

  Future<void> playIncrement() => _play(_increment);
  Future<void> playUndo() => _play(_undo);
  Future<void> playQuestComplete() => _play(_questComplete);
  Future<void> playLevelUp() => _play(_levelUp);
}
