import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:veloxon/videoplayer/gradient_slider.dart';
import 'package:window_manager/window_manager.dart';

class VeloxonPlayer extends StatefulWidget {
  final VideoController controller;

  const VeloxonPlayer({super.key, required this.controller});

  @override
  State<VeloxonPlayer> createState() => _VeloxonPlayerState();
}

class _VeloxonPlayerState extends State<VeloxonPlayer> {
  Player get player => widget.controller.player;
  bool _isControlsVisible = true;
  bool _hideCursor = false;
  Timer? _hideTimer;

  void _restartHideTimer() {
    _hideTimer?.cancel();
    _isControlsVisible = true;
    _hideCursor = false;

    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _isControlsVisible = false;
        _hideCursor = true;
      });
    });

    setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          player.playOrPause();
        });
      },
      child: MouseRegion(
        onHover: (_) => _restartHideTimer(),
        onEnter: (_) => _restartHideTimer(),
        onExit: (_) => _isControlsVisible = false,
        cursor: _hideCursor
            ? SystemMouseCursors.none
            : SystemMouseCursors.basic,
        child: Stack(
          children: [
            Video(controller: widget.controller, controls: NoVideoControls),

            VeloxonControls(
              controller: widget.controller,
              isVisible: _isControlsVisible,
              onHide: () => setState(() => _isControlsVisible = false),
            ),
          ],
        ),
      ),
    );
  }
}

class VeloxonControls extends StatefulWidget {
  final VideoController controller;
  final bool isVisible;
  final VoidCallback onHide;

  const VeloxonControls({
    super.key,
    required this.controller,
    required this.isVisible,
    required this.onHide,
  });

  @override
  State<VeloxonControls> createState() => _VeloxonControlsState();
}

class _VeloxonControlsState extends State<VeloxonControls> {
  Player get player => widget.controller.player;
  bool _isFullscreen = false;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: widget.isVisible ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !widget.isVisible,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.1),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.9),
                ],
                stops: [0.0, 0.1, 0.5, 0.75, 1.0],
              ),
            ),
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),

                // Center controls
                Expanded(child: Center(child: _buildCenterControls())),

                // Bottom bar
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(LucideIcons.arrowLeft, color: Colors.white, size: 28),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Column();
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Duration>(
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
                              gradient: LinearGradient(
                                colors: [Color(0xff72c0ff), Color(0xff0090fc)],
                              ),
                            ),
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 6.0,
                            ),
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: 14.0,
                            ),
                            activeTrackColor: Color(0xff0090fc),
                            inactiveTrackColor: Colors.white.withAlpha(30),
                            thumbColor: Color(0xff0090fc),
                            overlayColor: Color(0xff0090fc).withAlpha(30),
                          ),
                          child: Slider(
                            value: value.clamp(0.0, 1.0),
                            onChanged: (newValue) {
                              final newPosition = Duration(
                                milliseconds:
                                    (newValue * duration.inMilliseconds)
                                        .toInt(),
                              );
                              player.seek(newPosition);
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: TextStyle(
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
            ),

            SizedBox(height: 8),

            Row(
              children: [
                StreamBuilder<bool>(
                  stream: player.stream.playing,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildControlButton(
                          icon: LucideIcons.stepBack,
                          onPressed: () async {
                            final position = await player.stream.position.first;
                            await player.seek(position - Duration(seconds: 10));
                          },
                        ),
                        _buildControlButton(
                          icon: isPlaying
                              ? LucideIcons.pause
                              : LucideIcons.play,
                          onPressed: () => player.playOrPause(),
                        ),
                        _buildControlButton(
                          icon: LucideIcons.stepForward,
                          onPressed: () async {
                            final position = await player.stream.position.first;
                            await player.seek(position + Duration(seconds: 10));
                          },
                        ),
                      ],
                    );
                  },
                ),
                StreamBuilder(
                  stream: player.stream.volume,
                  builder: (context, snapshot) {
                    final volume = snapshot.data ?? 100.0;

                    return IconButton(
                      onPressed: () {
                        player.setVolume(volume > 0 ? 0 : 100);
                      },
                      icon: Icon(
                        volume > 0 ? LucideIcons.volume2 : LucideIcons.volumeX,
                        color: Colors.white,
                      ),
                    );
                  },
                ),

                Spacer(),

                _buildSpeedButton(),

                IconButton(
                  onPressed: null, //TODO:settings
                  icon: Icon(LucideIcons.settings, color: Colors.white),
                ),

                IconButton(
                  onPressed: _toggleFullscreen,
                  icon: Icon(
                    _isFullscreen ? LucideIcons.minimize : LucideIcons.maximize,
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

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildSpeedButton() {
    return StreamBuilder<double>(
      stream: player.stream.rate,
      builder: (context, snapshot) {
        final rate = snapshot.data ?? 1.0;
        return TextButton(
          onPressed: () {
            _showSpeedMenu(player);
          },
          child: Text('${rate}x', style: const TextStyle(color: Colors.white)),
        );
      },
    );
  }

  void _showSpeedMenu(Player player) {
    showModalBottomSheet(
      context: context,
      // OPRAVA: Přidáno constraints pro správné zobrazení
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      builder: (context) {
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rychlost přehrávání',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...speeds.map((speed) {
                    return ListTile(
                      title: Text('${speed}x'),
                      onTap: () {
                        player.setRate(speed);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
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

  Future<void> _toggleFullscreen() async {
    _isFullscreen = !_isFullscreen;

    if (_isFullscreen) {
      await windowManager.setFullScreen(true);
    } else {
      await windowManager.setFullScreen(false);
    }

    setState(() {});
  }
}
