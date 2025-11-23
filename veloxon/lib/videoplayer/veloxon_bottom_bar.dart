import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:veloxon/ui/gradient_slider.dart';
import 'package:veloxon/ui/menu_anchor.dart';

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
  double _previousVolume = 1.0;
  MenuController? _speedMenuController;
  MenuController? _settingsMenuController;

  @override
  void didUpdateWidget(VeloxonBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Zavřít menu pouze když se controls změní z visible na invisible
    if (oldWidget.isControlsVisible && !widget.isControlsVisible) {
      if (_speedMenuController != null && _speedMenuController!.isOpen) {
        _speedMenuController!.close();
      }
      if (_settingsMenuController != null && _settingsMenuController!.isOpen) {
        _settingsMenuController!.close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressBar(),
            const SizedBox(height: 8),
            _buildControlsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
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
                      widget.restartHideTimer();
                      final newPosition = Duration(
                        milliseconds: (newValue * duration.inMilliseconds)
                            .toInt(),
                      );
                      widget.player.seek(newPosition);
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

  Widget _buildControlsRow() {
    return Row(
      children: [
        _buildPlaybackControls(),
        _buildVolumeControl(),
        const Spacer(),
        _buildSpeedControl(),
        _buildSettingsMenu(),
        IconButton(
          onPressed: widget.onFullscreenToggle,
          icon: Icon(
            widget.isFullscreen ? LucideIcons.minimize : LucideIcons.maximize,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return StreamBuilder<bool>(
      stream: widget.player.stream.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.stepBack, color: Colors.white),
              onPressed: () async {
                final position = await widget.player.stream.position.first;
                await widget.player.seek(
                  position - const Duration(seconds: 10),
                );
              },
            ),
            IconButton(
              icon: Icon(
                isPlaying ? LucideIcons.pause : LucideIcons.play,
                color: Colors.white,
              ),
              onPressed: () => widget.player.playOrPause(),
            ),
            IconButton(
              icon: const Icon(LucideIcons.stepForward, color: Colors.white),
              onPressed: () async {
                final position = await widget.player.stream.position.first;
                await widget.player.seek(
                  position + const Duration(seconds: 10),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeControl() {
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

  Widget _buildSpeedControl() {
    return StreamBuilder<double>(
      stream: widget.player.stream.rate,
      builder: (context, snapshot) {
        final rate = snapshot.data ?? 1.0;
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

        return VeloxonMenuAnchor<double>(
          label: '${rate}x',
          currentValue: rate,
          items: speeds
              .map((speed) => VeloxonMenuItem(label: '${speed}x', value: speed))
              .toList(),
          onChanged: (newSpeed) {
            widget.player.setRate(newSpeed);
          },
          onControllerCreated: (controller) {
            _speedMenuController = controller;
          },
        );
      },
    );
  }

  Widget _buildSettingsMenu() {
    return MenuAnchor(
      controller: _settingsMenuController,
      onOpen: () {
        // Zastavit hide timer když se menu otevře
        widget.stopHideTimer();
      },
      onClose: () {
        // Restartovat hide timer když se menu zavře
        widget.restartHideTimer();
      },
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(
          Colors.black.withValues(alpha: 0.9),
        ),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      builder: (context, controller, child) {
        _settingsMenuController ??= controller;
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(LucideIcons.settings, color: Colors.white),
        );
      },
      menuChildren: [_buildAudioTrackSubmenu(), _buildSubtitleSubmenu()],
    );
  }

  Widget _buildAudioTrackSubmenu() {
    return StreamBuilder<Track>(
      stream: widget.player.stream.track,
      builder: (context, snapshot) {
        final currentTrack = snapshot.data?.audio ?? AudioTrack.auto();

        return StreamBuilder<Tracks>(
          stream: widget.player.stream.tracks,
          builder: (context, tracksSnapshot) {
            final tracks = tracksSnapshot.data;
            final audioTracks = tracks?.audio ?? [];

            return VeloxonSubmenuAnchor(
              label: 'Audio Track',
              icon: LucideIcons.audioLines,
              menuChildren: [
                // Auto option
                MenuItemButton(
                  onPressed: () {
                    widget.player.setAudioTrack(AudioTrack.auto());
                  },
                  style: MenuItemButton.styleFrom(
                    backgroundColor: currentTrack.id == 'auto'
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  leadingIcon: currentTrack.id == 'auto'
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : const SizedBox(width: 18),
                  child: Text(
                    'Auto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: currentTrack.id == 'auto'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                // Available audio tracks
                ...audioTracks.map((track) {
                  final isSelected = currentTrack.id == track.id;
                  final label =
                      track.title ?? track.language ?? 'Track ${track.id}';

                  return MenuItemButton(
                    onPressed: () {
                      widget.player.setAudioTrack(track);
                    },
                    style: MenuItemButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    leadingIcon: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : const SizedBox(width: 18),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSubtitleSubmenu() {
    return StreamBuilder<Track>(
      stream: widget.player.stream.track,
      builder: (context, snapshot) {
        final currentTrack = snapshot.data?.subtitle ?? SubtitleTrack.no();

        return StreamBuilder<Tracks>(
          stream: widget.player.stream.tracks,
          builder: (context, tracksSnapshot) {
            final tracks = tracksSnapshot.data;
            final subtitleTracks = tracks?.subtitle ?? [];

            return VeloxonSubmenuAnchor(
              label: 'Subtitles',
              icon: LucideIcons.captions,
              menuChildren: [
                // No subtitles option
                MenuItemButton(
                  onPressed: () {
                    widget.player.setSubtitleTrack(SubtitleTrack.no());
                  },
                  style: MenuItemButton.styleFrom(
                    backgroundColor: currentTrack.id == 'no'
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  leadingIcon: currentTrack.id == 'no'
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : const SizedBox(width: 18),
                  child: Text(
                    'Off',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: currentTrack.id == 'no'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                // Auto option
                MenuItemButton(
                  onPressed: () {
                    widget.player.setSubtitleTrack(SubtitleTrack.auto());
                  },
                  style: MenuItemButton.styleFrom(
                    backgroundColor: currentTrack.id == 'auto'
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  leadingIcon: currentTrack.id == 'auto'
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : const SizedBox(width: 18),
                  child: Text(
                    'Auto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: currentTrack.id == 'auto'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                // Available subtitle tracks
                ...subtitleTracks.map((track) {
                  final isSelected = currentTrack.id == track.id;
                  final label =
                      track.title ?? track.language ?? 'Track ${track.id}';

                  return MenuItemButton(
                    onPressed: () {
                      widget.player.setSubtitleTrack(track);
                    },
                    style: MenuItemButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    leadingIcon: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : const SizedBox(width: 18),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }),
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
