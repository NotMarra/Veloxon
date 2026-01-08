import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:veloxon/videoplayer/widgets/playback_controls.dart';
import 'package:veloxon/videoplayer/widgets/progress_bar.dart';
import 'package:veloxon/videoplayer/widgets/settings_menu.dart';
import 'package:veloxon/videoplayer/widgets/speed_control.dart';
import 'package:veloxon/videoplayer/widgets/volume_control.dart';

class VeloxonBottomBar extends StatefulWidget {
  final Player player;
  final VoidCallback restartHideTimer;
  final VoidCallback stopHideTimer;
  final VoidCallback onFullscreenToggle;
  final bool isFullscreen;
  final bool isControlsVisible;

  const VeloxonBottomBar({
    super.key,
    required this.player,
    required this.restartHideTimer,
    required this.stopHideTimer,
    required this.onFullscreenToggle,
    required this.isFullscreen,
    required this.isControlsVisible,
  });

  @override
  State<VeloxonBottomBar> createState() => _VeloxonBottomBarState();
}

class _VeloxonBottomBarState extends State<VeloxonBottomBar> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressBar(
              player: widget.player,
              restartHideTimer: widget.restartHideTimer,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                PlaybackControls(player: widget.player),
                VolumeControl(
                  player: widget.player,
                  restartHideTimer: widget.restartHideTimer,
                ),
                const Spacer(),
                SpeedControl(
                  player: widget.player,
                  stopHideTimer: widget.stopHideTimer,
                  restartHideTimer: widget.restartHideTimer,
                ),
                SettingsMenu(
                  player: widget.player,
                  stopHideTimer: widget.stopHideTimer,
                  restartHideTimer: widget.restartHideTimer,
                ),
                IconButton(
                  onPressed: widget.onFullscreenToggle,
                  icon: Icon(
                    widget.isFullscreen
                        ? LucideIcons.minimize
                        : LucideIcons.maximize,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
