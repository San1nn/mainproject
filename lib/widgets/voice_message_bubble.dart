import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mainproject/constants.dart';

/// A styled voice message bubble with play/pause, progress bar, and duration
class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final Duration duration;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.duration;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
        if (_isPlaying) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.value = 0;
        }
      }
    });

    _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _player.onDurationChanged.listen((duration) {
      if (mounted && duration.inMilliseconds > 0) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_position.inMilliseconds > 0 && _position < _totalDuration) {
        await _player.resume();
      } else {
        await _player.play(UrlSource(widget.audioUrl));
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inMilliseconds > 0
        ? _position.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    final accentColor = widget.isMe ? Colors.white : AppColors.primary;

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? accentColor.withValues(
                            alpha: 0.15 + _pulseController.value * 0.1,
                          )
                        : accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),

          // Progress + Duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform / Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      // Background bars (simulated waveform)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(20, (i) {
                          // Generate varied heights for waveform effect
                          final heights = [
                            0.3,
                            0.5,
                            0.7,
                            0.4,
                            0.9,
                            0.6,
                            0.8,
                            0.3,
                            0.7,
                            0.5,
                            0.6,
                            0.9,
                            0.4,
                            0.7,
                            0.5,
                            0.8,
                            0.3,
                            0.6,
                            0.4,
                            0.7,
                          ];
                          final barProgress = i / 20;
                          final isActive = barProgress <= progress;
                          return Container(
                            width: 3,
                            height: 20 * heights[i],
                            decoration: BoxDecoration(
                              color: isActive
                                  ? accentColor.withValues(alpha: 0.9)
                                  : accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Duration text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mic_rounded,
                          size: 12,
                          color: accentColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _isPlaying
                              ? _formatDuration(_position)
                              : _formatDuration(_totalDuration),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: accentColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    if (_isPlaying)
                      Text(
                        _formatDuration(_totalDuration),
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor.withValues(alpha: 0.4),
                        ),
                      ),
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
