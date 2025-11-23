import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:veloxon/videoplayer/veloxon_top_bar.dart';
import 'package:veloxon/videoplayer/veloxon_bottom_bar.dart';
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

    if (!_isControlsVisible) {
      setState(() {
        _isControlsVisible = true;
        _hideCursor = false;
      });
    }

    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isControlsVisible = false;
          _hideCursor = true;
        });
      }
    });
  }

  void _stopHideTimer() {
    _hideTimer?.cancel();
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
      onPanUpdate: (_) => _restartHideTimer(),
      child: MouseRegion(
        onHover: (_) => _restartHideTimer(),
        onEnter: (_) => _restartHideTimer(),
        onExit: (_) =>
            _stopHideTimer(), // Pouze zastaví timer, neskryje controls
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
              restartHideTimer: _restartHideTimer,
              stopHideTimer: _stopHideTimer,
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
  final VoidCallback restartHideTimer;
  final VoidCallback stopHideTimer;

  const VeloxonControls({
    super.key,
    required this.controller,
    required this.isVisible,
    required this.onHide,
    required this.restartHideTimer,
    required this.stopHideTimer,
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
        duration: const Duration(milliseconds: 200),
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
                stops: const [0.0, 0.1, 0.5, 0.75, 1.0],
              ),
            ),
            child: Column(
              children: [
                const VeloxonTopBar(),
                const Expanded(child: SizedBox()),
                VeloxonBottomBar(
                  player: player,
                  restartHideTimer: widget.restartHideTimer,
                  stopHideTimer: widget.stopHideTimer,
                  onFullscreenToggle: _toggleFullscreen,
                  isFullscreen: _isFullscreen,
                  isControlsVisible: widget.isVisible,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
