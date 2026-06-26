import 'audio_helper.dart';

AudioHelper getAudioHelper() => AudioHelperStub();

class AudioHelperStub implements AudioHelper {
  @override
  bool get isRecording => false;

  @override
  bool get isPlaying => false;

  @override
  Future<void> startRecording({void Function(String text)? onTranscriptionUpdated}) async {
    // No-op
  }

  @override
  Future<AudioRecordingResult> stopRecording() async {
    return AudioRecordingResult(audioUrl: '', transcription: '');
  }

  @override
  Future<void> play(
    String url, {
    required void Function(double progress, int currentSeconds, int totalSeconds) onProgress,
    required void Function() onComplete,
  }) async {
    // No-op
  }

  @override
  Future<void> pause() async {
    // No-op
  }

  @override
  Future<void> stop() async {
    // No-op
  }
}
