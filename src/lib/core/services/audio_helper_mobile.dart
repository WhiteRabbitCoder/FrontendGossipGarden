import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_helper.dart';

AudioHelper getAudioHelper() => AudioHelperMobile();

class AudioHelperMobile implements AudioHelper {
  final Record _audioRecorder = Record();
  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String _transcription = '';
  String? _recordedFilePath;
  
  Function(String text)? _onTranscriptionUpdated;

  AudioHelperMobile() {
    _initSpeech();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  Future<void> _initSpeech() async {
    await _speechToText.initialize();
  }

  @override
  bool get isRecording => _isRecording;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> startRecording({void Function(String text)? onTranscriptionUpdated}) async {
    _onTranscriptionUpdated = onTranscriptionUpdated;
    _transcription = '';

    if (await _audioRecorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      _recordedFilePath = '${tempDir.path}/audio_record_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        path: _recordedFilePath,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
      );
      _isRecording = true;

      // Iniciar reconocimiento de voz si está disponible
      if (_speechToText.isAvailable) {
        await _speechToText.listen(
          onResult: (result) {
            _transcription = result.recognizedWords;
            if (_onTranscriptionUpdated != null) {
              _onTranscriptionUpdated!(_transcription);
            }
          },
          localeId: 'es_ES',
        );
      }
    }
  }

  @override
  Future<AudioRecordingResult> stopRecording() async {
    if (!_isRecording) {
      return AudioRecordingResult(audioUrl: '', transcription: '');
    }

    final path = await _audioRecorder.stop();
    _isRecording = false;

    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    String? base64Audio;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64Audio = base64Encode(bytes);
      }
    }

    return AudioRecordingResult(
      audioUrl: path ?? '',
      transcription: _transcription.isNotEmpty ? _transcription : 'Nota de voz',
      audioBase64: base64Audio,
    );
  }

  @override
  Future<void> play(
    String url, {
    required void Function(double progress, int currentSeconds, int totalSeconds) onProgress,
    required void Function() onComplete,
  }) async {
    _audioPlayer.onPositionChanged.listen((position) async {
      final duration = await _audioPlayer.getDuration();
      if (duration != null && duration.inSeconds > 0) {
        onProgress(position.inMilliseconds / duration.inMilliseconds, position.inSeconds, duration.inSeconds);
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      onComplete();
    });

    Source source;
    if (url.startsWith('http')) {
      source = UrlSource(url);
    } else {
      source = DeviceFileSource(url);
    }
    
    await _audioPlayer.play(source);
    _isPlaying = true;
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }
}
