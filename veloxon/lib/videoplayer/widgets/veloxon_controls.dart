import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:veloxon/videoplayer/veloxon_bottom_bar.dart';
import 'package:veloxon/videoplayer/veloxon_top_bar.dart';
import 'package:window_manager/window_manager.dart';

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
                  player: widget.controller.player,
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
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setFullScreen(true);
    } else {
      await windowManager.setFullScreen(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    }

    setState(() {});
  }
}
