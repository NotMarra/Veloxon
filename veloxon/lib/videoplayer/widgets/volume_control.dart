import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:veloxon/ui/gradient_slider.dart';

class VolumeControl extends StatefulWidget {
  final Player player;
  final VoidCallback restartHideTimer;

  const VolumeControl({
    super.key,
    required this.player,
    required this.restartHideTimer,
  });

  @override
  State<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  double _previousVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: widget.player.stream.volume,
      builder: (context, snapshot) {
        double volumeRaw = snapshot.data ?? 100.0;
        double volume = volumeRaw / 100;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  if (volume > 0) {
                    _previousVolume = volume;
                    volume = 0.0;
                  } else {
                    volume = _previousVolume;
                  }
                  widget.player.setVolume(volume * 100);
                });
              },
              icon: Icon(
                volume > 0 ? LucideIcons.volume2 : LucideIcons.volumeX,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 120,
              child: Tooltip(
                message: "${(volume * 100).toInt()}%",
                enableTapToDismiss: false,
                exitDuration: Duration.zero,
                waitDuration: Duration.zero,
                ignorePointer: true,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                textStyle: const TextStyle(color: Colors.white),
                child: SliderTheme(
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
                    overlayColor: const Color(0x1e0090fc),
                  ),
                  child: Slider(
                    value: volume.clamp(0.0, 1.0),
                    onChanged: (newValue) {
                      setState(() {
                        widget.restartHideTimer();
                        volume = newValue;
                        if (newValue > 0) {
                          _previousVolume = newValue;
                        }
                        widget.player.setVolume(volume * 100);
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
