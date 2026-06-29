import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gossip_garden/core/services/audio_helper.dart';
import '../../../../core/theme/garden_colors.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../../core/theme/garden_text_styles.dart';

class VoiceNoteBubble extends StatefulWidget {
  final bool isUser;
  final int durationSeconds;
  final String timestamp;
  final List<double>? waveform;
  final String? transcription;
  final String? audioUrl;

  const VoiceNoteBubble({
    super.key,
    required this.isUser,
    required this.durationSeconds,
    required this.timestamp,
    this.waveform,
    this.transcription,
    this.audioUrl,
  });

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  int _currentSecond = 0;
  double _progress = 0.0;
  late int _durationSeconds;
  Timer? _timer;
  late List<double> _bars;
  late AnimationController _pulseController;
  late final AudioHelper _audioHelper;

  @override
  void initState() {
    super.initState();
    _audioHelper = AudioHelper();
    _durationSeconds = widget.durationSeconds;
    _bars = widget.waveform ?? _generateWaveform();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  List<double> _generateWaveform() {
    final rng = Random(_durationSeconds * 7 + 13);
    return List.generate(36, (i) {
      final edge = sin(i / 36 * pi);
      return 0.15 + edge * 0.5 + rng.nextDouble() * 0.35;
    });
  }

  void _togglePlay() async {
    final url = widget.audioUrl;
    if (url == null || url.isEmpty) {
      _simulatePlayback();
      return;
    }

    if (_isPlaying) {
      await _audioHelper.pause();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    } else {
      if (mounted) {
        setState(() => _isPlaying = true);
      }
      await _audioHelper.play(
        url,
        onProgress: (progress, currentSeconds, totalSeconds) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _currentSecond = currentSeconds;
              if (totalSeconds > 0) {
                _durationSeconds = totalSeconds;
              }
            });
          }
        },
        onComplete: () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentSecond = 0;
              _progress = 0.0;
            });
          }
        },
      );
    }
  }

  void _simulatePlayback() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_currentSecond >= _durationSeconds) {
          t.cancel();
          setState(() {
            _isPlaying = false;
            _currentSecond = 0;
            _progress = 0.0;
          });
        } else {
          setState(() {
            _currentSecond++;
            _progress = _currentSecond / _durationSeconds;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioHelper.stop();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.isUser;
    final progress = _progress;

    final bgColor = isUser ? GardenColors.leafGreen.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.85);
    final fgColor = const Color(0xFF2E382E); // Gris oscuro botánico
    final subColor = GardenColors.inkSoft.withValues(alpha: 0.7);
    final unplayedColor = isUser
        ? const Color(0xFF2E382E).withValues(alpha: 0.15)
        : GardenColors.dustLight;

    return Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: GardenColors.ink, width: 1.5),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 0),
          bottomRight: Radius.circular(isUser ? 0 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: GardenColors.ink.withValues(alpha: 0.15),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Play / Pause button
              GestureDetector(
                onTap: _togglePlay,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF2E382E).withValues(alpha: 0.08)
                        : GardenColors.sageLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: fgColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Waveform
              Expanded(
                child: _Waveform(
                  bars: _bars,
                  progress: progress,
                  playedColor: fgColor,
                  unplayedColor: unplayedColor,
                ),
              ),
            ],
          ),
          if (widget.transcription != null && widget.transcription!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: MarkdownBody(
                data: widget.transcription!,
                styleSheet: MarkdownStyleSheet(
                  p: GardenTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF2E382E),
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                  strong: GardenTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF2E382E),
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 5),
          Row(
            children: [
              // Mic icon small
              Icon(Icons.mic, size: 11, color: subColor),
              const SizedBox(width: 3),
              Text(
                _formatTime(_currentSecond),
                style: TextStyle(fontSize: 11, color: subColor),
              ),
              const Spacer(),
              Text(
                widget.timestamp,
                style: TextStyle(fontSize: 11, color: subColor),
              ),
              if (isUser) ...[
                const SizedBox(width: 4),
                Icon(Icons.done_all_rounded, size: 14, color: subColor),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  final List<double> bars;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  const _Waveform({
    required this.bars,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(bars.length, (i) {
          final played = i / bars.length <= progress;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FractionallySizedBox(
                heightFactor: bars[i].clamp(0.1, 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: played ? playedColor : unplayedColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
