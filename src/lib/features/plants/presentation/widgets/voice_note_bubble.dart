import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/garden_colors.dart';

class VoiceNoteBubble extends StatefulWidget {
  final bool isUser;
  final int durationSeconds;
  final String timestamp;
  final List<double>? waveform;

  const VoiceNoteBubble({
    super.key,
    required this.isUser,
    required this.durationSeconds,
    required this.timestamp,
    this.waveform,
  });

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  int _currentSecond = 0;
  Timer? _timer;
  late List<double> _bars;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bars = widget.waveform ?? _generateWaveform();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  List<double> _generateWaveform() {
    final rng = Random(widget.durationSeconds * 7 + 13);
    return List.generate(36, (i) {
      // Edges quieter, middle louder — feels more natural
      final edge = sin(i / 36 * pi);
      return 0.15 + edge * 0.5 + rng.nextDouble() * 0.35;
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_currentSecond >= widget.durationSeconds) {
          t.cancel();
          setState(() {
            _isPlaying = false;
            _currentSecond = 0;
          });
        } else {
          setState(() => _currentSecond++);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
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
    final progress = widget.durationSeconds > 0
        ? _currentSecond / widget.durationSeconds
        : 0.0;

    final bgColor = isUser ? GardenColors.forest : Colors.white;
    final fgColor = isUser ? Colors.white : GardenColors.forest;
    final subColor =
        isUser ? Colors.white.withValues(alpha: 0.65) : GardenColors.dust;
    final unplayedColor = isUser
        ? Colors.white.withValues(alpha: 0.28)
        : GardenColors.dustLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 270),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              boxShadow: [
                if (!isUser)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
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
                              ? Colors.white.withValues(alpha: 0.18)
                              : GardenColors.sageLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
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
