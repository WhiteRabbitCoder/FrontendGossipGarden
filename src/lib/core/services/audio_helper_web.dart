import 'dart:async';
import 'dart:html' as html;
import 'audio_helper.dart';

AudioHelper getAudioHelper() => AudioHelperWeb();

class AudioHelperWeb implements AudioHelper {
  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _chunks = [];
  html.SpeechRecognition? _speechRecognition;
  
  bool _isRecording = false;
  String _transcription = '';
  
  // Playback fields
  html.AudioElement? _audioElement;
  StreamSubscription? _timeUpdateSubscription;
  StreamSubscription? _endedSubscription;
  void Function(double, int, int)? _onProgress;
  void Function()? _onComplete;
  bool _isPlaying = false;
  String? _currentPlayingUrl;
  
  @override
  bool get isRecording => _isRecording;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> startRecording({void Function(String text)? onTranscriptionUpdated}) async {
    if (_isRecording) return;
    
    _chunks.clear();
    _transcription = '';
    
    try {
      // Request microphone access
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('mediaDevices no está disponible en este navegador.');
      }
      final stream = await mediaDevices.getUserMedia({'audio': true});
      _mediaRecorder = html.MediaRecorder(stream);
      _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null) {
          _chunks.add(blobEvent.data!);
        }
      });
      
      _mediaRecorder!.start();
      _isRecording = true;
      
      // Start speech recognition if supported
      if (html.SpeechRecognition.supported) {
        _speechRecognition = html.SpeechRecognition()
          ..continuous = true
          ..interimResults = true
          ..lang = 'es-ES'; // Español
          
        _speechRecognition!.onResult.listen((event) {
          final results = event.results;
          if (results != null && results.isNotEmpty) {
            // Combinar todos los segmentos de transcripción utilizando dynamic cast para evitar errores del compilador
            final fullTranscript = results.map((r) {
              final dynamic dynResult = r;
              return dynResult[0]?.transcript as String? ?? '';
            }).join(' ');
            _transcription = fullTranscript.trim();
            if (onTranscriptionUpdated != null) {
              onTranscriptionUpdated(_transcription);
            }
          }
        });
        
        _speechRecognition!.onError.listen((error) {
          print('Error en reconocimiento de voz: $error');
        });
        
        _speechRecognition!.start();
      } else {
        print('SpeechRecognition no es soportado en este navegador.');
      }
    } catch (e) {
      print('Error al iniciar grabación: $e');
      _isRecording = false;
      rethrow;
    }
  }

  @override
  Future<AudioRecordingResult> stopRecording() async {
    if (!_isRecording) {
      return AudioRecordingResult(audioUrl: '', transcription: '');
    }

    final completer = Completer<AudioRecordingResult>();

    if (_mediaRecorder != null) {
      _mediaRecorder!.addEventListener('stop', (event) async {
        // Detener los tracks del stream para liberar el micrófono
        _mediaRecorder!.stream?.getTracks().forEach((track) {
          track.stop();
        });

        final blob = html.Blob(_chunks, 'audio/webm');
        final audioUrl = html.Url.createObjectUrl(blob);
        
        final reader = html.FileReader();
        reader.readAsDataUrl(blob);
        await reader.onLoadEnd.first;
        final dataUrl = reader.result as String;
        final base64Audio = dataUrl.split(',').last;
        
        completer.complete(AudioRecordingResult(
          audioUrl: audioUrl,
          transcription: _transcription.isNotEmpty ? _transcription : 'Nota de voz',
          audioBase64: base64Audio,
        ));
      });

      _mediaRecorder!.stop();
    } else {
      completer.complete(AudioRecordingResult(
        audioUrl: '',
        transcription: _transcription.isNotEmpty ? _transcription : 'Nota de voz',
      ));
    }

    if (_speechRecognition != null) {
      _speechRecognition!.stop();
    }
    
    _isRecording = false;
    return completer.future;
  }

  @override
  Future<void> play(
    String url, {
    required void Function(double progress, int currentSeconds, int totalSeconds) onProgress,
    required void Function() onComplete,
  }) async {
    // Si ya se está reproduciendo la misma URL y está en pausa, reanudar
    if (_audioElement != null && _currentPlayingUrl == url && !_isPlaying) {
      _audioElement!.play();
      _isPlaying = true;
      return;
    }

    // Si se está reproduciendo otra URL, detenerla primero
    if (_audioElement != null) {
      await stop();
    }

    _currentPlayingUrl = url;
    _onProgress = onProgress;
    _onComplete = onComplete;
    
    _audioElement = html.AudioElement(url);
    
    _timeUpdateSubscription = _audioElement!.onTimeUpdate.listen((_) {
      final double duration = _audioElement!.duration.toDouble();
      final double current = _audioElement!.currentTime.toDouble();
      
      if (duration.isNaN || duration.isInfinite || duration == 0) {
        _onProgress?.call(0, current.toInt(), 0);
      } else {
        final progress = current / duration;
        _onProgress?.call(progress, current.toInt(), duration.toInt());
      }
    });

    _endedSubscription = _audioElement!.onEnded.listen((_) {
      _isPlaying = false;
      _onComplete?.call();
      stop();
    });

    _audioElement!.play();
    _isPlaying = true;
  }

  @override
  Future<void> pause() async {
    if (_audioElement != null && _isPlaying) {
      _audioElement!.pause();
      _isPlaying = false;
    }
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _currentPlayingUrl = null;
    
    _timeUpdateSubscription?.cancel();
    _endedSubscription?.cancel();
    
    if (_audioElement != null) {
      _audioElement!.pause();
      _audioElement!.remove();
      _audioElement = null;
    }
  }
}
