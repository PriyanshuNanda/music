import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final _player = AudioPlayer();
  final _yt = YoutubeExplode();
  bool _isInitialized = false;
  final playingStateNotifier = ValueNotifier<bool>(false);

  void _updatePlayingState() {
    playingStateNotifier.value = _player.playing;
  }

  Future<void> init() async {
    try {
      if (!_isInitialized) {
        print('Initializing audio player...');

        // Configure for better performance
        await _player.setVolume(1.0);
        await _player.setAutomaticallyWaitsToMinimizeStalling(
          false,
        ); // Don't wait to minimize stalling since we're using minimal buffering
        await _player.setLoopMode(LoopMode.off);

        print('Audio configuration complete');

        // Listen for player state changes
        _player.playerStateStream.listen((state) {
          print('Player state changed: ${state.processingState}');
          _updatePlayingState(); // Update playing state whenever it changes

          switch (state.processingState) {
            case ProcessingState.loading:
              print('Loading audio...');
              break;
            case ProcessingState.completed:
              print('Playback completed');
              playingStateNotifier.value = false;
              break;
            case ProcessingState.idle:
              print('Player idle');
              playingStateNotifier.value = false;
              break;
            default:
              print('Processing state: ${state.processingState}');
          }
        });

        _isInitialized = true;
        print('Audio player initialized successfully');
      }
    } catch (e) {
      print('Error initializing audio player: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  StreamSubscription? _completionSubscription;

  Future<AudioStreamInfo?> _getAudioStream(String videoId) async {
    final receivePort = ReceivePort();
    late Isolate isolate;
    StreamManifest? manifest;

    try {
      isolate = await Isolate.spawn(
        _fetchManifest,
        {'videoId': videoId, 'sendPort': receivePort.sendPort},
        errorsAreFatal: true,
        onError: receivePort.sendPort,
      );

      // Wait for result or error
      final result = await receivePort.first;
      if (result is Exception) {
        throw result;
      }
      manifest = result as StreamManifest;

      // Get audio-only stream with optimal quality and format
      AudioStreamInfo? audioStream =
          manifest.audioOnly
              .where((s) => s.codec.mimeType == 'audio/webm')
              .withHighestBitrate();

      if (audioStream == null) {
        // Fallback to any audio stream if webm is not available
        audioStream = manifest.audioOnly.withHighestBitrate();
      }

      return audioStream;
    } catch (e) {
      print('Error fetching audio stream: $e');
      rethrow;
    } finally {
      receivePort.close();
      // isolate?.kill();
    }
  }

  static void _fetchManifest(Map<String, dynamic> args) async {
    final videoId = args['videoId'] as String;
    final SendPort sendPort = args['sendPort'];
    final yt = YoutubeExplode();

    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      sendPort.send(manifest);
    } catch (e) {
      sendPort.send(e);
    } finally {
      yt.close();
    }
  }

  Future<void> play(String videoId) async {
    int retryCount = 0;
    const maxRetries = 3;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        if (!_isInitialized) {
          await init();
        }

        // Cancel any existing completion subscription
        await _completionSubscription?.cancel();

        print(
          'Starting playback for videoId: $videoId (attempt ${retryCount + 1})',
        );
        // Properly stop and reset current playback
        await stop();
        await _player.seek(Duration.zero);

        // Get stream manifest in isolate with timeout
        final audioStream = await _getAudioStream(videoId).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Manifest fetch timeout'),
        );

        if (audioStream == null) {
          throw Exception('No suitable audio stream found');
        }

        print('Selected audio stream bitrate: ${audioStream.bitrate}');
        print('Selected audio codec: ${audioStream.codec.mimeType}');
        print('Starting audio playback...');
        print('Setting up audio source...');
        // Create audio source with proper MIME type
        final audioSource = AudioSource.uri(
          audioStream.url,
          headers: {
            'Content-Type': audioStream.codec.mimeType,
            'Accept': '*/*',
          },
        );

        // Configure and load audio
        // Configure and load audio with optimized buffering
        // Configure optimal buffering for streaming
        await _player.setAudioSource(
          audioSource,
          initialPosition: Duration.zero,
          preload: false, // Disable preloading to reduce buffering
        );

        // Wait for initial load
        await _player.load();
        print('Audio loaded successfully');

        final initialDuration = await _player.duration;
        print('Initial player duration: $initialDuration');

        // Configure playback with optimized settings
        await _player.setVolume(1.0);
        await _player.setSpeed(1.0);
        await _player.setSkipSilenceEnabled(false);
        await _player.setAutomaticallyWaitsToMinimizeStalling(false);
        print('Starting playback with optimized settings...');

        // Start playback
        await _player.play();
        print('Playback started successfully');
        _updatePlayingState();

        // Listen for playback completion
        _completionSubscription = _player.processingStateStream.listen((state) {
          if (state == ProcessingState.completed) {
            print('Playback completed naturally');
            _player.seek(Duration.zero);
          }
        });
      } catch (e) {
        print('Error during playback setup: $e');
        rethrow;
      }
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _updatePlayingState();
  }

  Future<void> resume() async {
    await _player.play();
    _updatePlayingState();
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  Future<void> dispose() async {
    await _completionSubscription?.cancel();
    _completionSubscription = null;
    _yt.close();
    playingStateNotifier.dispose();
    await _player.dispose();
    _isInitialized = false;
  }

  bool get isPlaying => _player.playing;
  Duration? get position => _player.position;
  Duration? get duration => _player.duration;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  AudioPlayer get player => _player;
}
