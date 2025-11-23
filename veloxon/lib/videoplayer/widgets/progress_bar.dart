import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:veloxon/ui/gradient_slider.dart';

class ProgressBar extends StatelessWidget {
  final Player player;
  final VoidCallback restartHideTimer;

  const ProgressBar({
    super.key,
    required this.player,
    required this.restartHideTimer,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: player.stream.duration,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final value = duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.0,
                    trackShape: GradientRectSliderTrackShape(
                      gradient: const LinearGradient(
                        colors: [Color(0xff72c0ff), Color(0xff0090fc)],
                      ),
                    ),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14.0,
                    ),
                    activeTrackColor: const Color(0xff0090fc),
                    inactiveTrackColor: Colors.white.withAlpha(30),
                    thumbColor: const Color(0xff0090fc),
                    overlayColor: const Color(0xff0090fc).withAlpha(30),
                  ),
                  child: Slider(
                    value: value.clamp(0.0, 1.0),
                    onChanged: (newValue) {
                      restartHideTimer();
                      final newPosition = Duration(
                        milliseconds: (newValue * duration.inMilliseconds)
                            .toInt(),
                      );
                      player.seek(newPosition);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
