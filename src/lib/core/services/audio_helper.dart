import 'audio_helper_stub.dart'
    if (dart.library.html) 'audio_helper_web.dart';

abstract class AudioHelper {
  factory AudioHelper() => getAudioHelper();

  /// Inicia la grabación del micrófono y el reconocimiento de voz.
  Future<void> startRecording({void Function(String text)? onTranscriptionUpdated});

  /// Detiene la grabación y el reconocimiento, retornando el resultado (URL del audio y transcripción).
  Future<AudioRecordingResult> stopRecording();

  /// Indica si actualmente se está grabando.
  bool get isRecording;

  /// Reproduce un audio desde una URL (local en memoria o remota HTTP).
  Future<void> play(
    String url, {
    required void Function(double progress, int currentSeconds, int totalSeconds) onProgress,
    required void Function() onComplete,
  });

  /// Pausa la reproducción del audio actual.
  Future<void> pause();

  /// Detiene la reproducción del audio actual y reinicia el estado.
  Future<void> stop();

  /// Indica si actualmente se está reproduciendo audio.
  bool get isPlaying;
}

class AudioRecordingResult {
  final String audioUrl;
  final String transcription;
  final String? audioBase64;

  AudioRecordingResult({
    required this.audioUrl,
    required this.transcription,
    this.audioBase64,
  });
}
