import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:veloxon/videoplayer/veloxon_top_bar.dart';
import 'package:veloxon/videoplayer/veloxon_bottom_bar.dart';
import 'package:veloxon/utils/ass_parser.dart';
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
  SubtitleViewConfiguration? _subtitleConfig;
  String? _currentMediaPath;

  @override
  void initState() {
    super.initState();
    _setupSubtitleRendering();
    _listenToMediaChanges();
  }

  void _listenToMediaChanges() {
    // Listen to media changes
    player.stream.playlist.listen((playlist) {
      if (playlist.medias.isNotEmpty) {
        final mediaUri = playlist.medias[playlist.index].uri;
        _currentMediaPath = _extractFilePath(mediaUri);
      }
    });
  }

  String? _extractFilePath(String uri) {
    // Extract file path from URI
    if (uri.startsWith('file:///')) {
      return Uri.parse(uri).toFilePath();
    } else if (uri.startsWith('asset:///')) {
      // Asset files cannot be loaded directly
      return null;
    }
    return uri;
  }

  void _setupSubtitleRendering() {
    // Listen to subtitle track changes
    player.stream.track.listen((track) async {
      final subtitle = track.subtitle;

      // No subtitles or auto
      if (subtitle.id == 'no' || subtitle.id == 'auto') {
        if (mounted) {
          setState(() {
            _subtitleConfig = _getDefaultSubtitleConfig();
          });
        }
        return;
      }

      // Detect subtitle type based on title or id
      final title = subtitle.title?.toLowerCase() ?? '';
      final lang = subtitle.language?.toLowerCase() ?? '';
      final id = subtitle.id.toLowerCase();

      final isAssFormat =
          title.contains('.ass') ||
          title.contains('.ssa') ||
          lang.contains('ass') ||
          id.contains('ass');

      if (isAssFormat && _currentMediaPath != null) {
        // Try to find and load ASS file
        final assStyle = await _loadAssSubtitleStyle(
          subtitle,
          _currentMediaPath!,
        );

        if (mounted) {
          setState(() {
            if (assStyle != null) {
              // Use styling from ASS file
              _subtitleConfig = SubtitleViewConfiguration(
                style: assStyle.toTextStyle(),
                padding: assStyle.padding,
                textAlign: assStyle.textAlign,
              );
            } else {
              // If ASS loading failed, use default
              _subtitleConfig = _getDefaultSubtitleConfig();
            }
          });
        }
      } else {
        // For SRT or other formats use uniform styling
        if (mounted) {
          setState(() {
            _subtitleConfig = _getDefaultSubtitleConfig();
          });
        }
      }
    });
  }

  SubtitleViewConfiguration _getDefaultSubtitleConfig() {
    return SubtitleViewConfiguration(
      style: const TextStyle(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(1.5, 1.5),
            blurRadius: 4.0,
            color: Colors.black,
          ),
          Shadow(
            offset: Offset(-1.5, -1.5),
            blurRadius: 4.0,
            color: Colors.black,
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 40, right: 40, bottom: 80),
      textAlign: TextAlign.center,
    );
  }

  Future<AssStyle?> _loadAssSubtitleStyle(
    SubtitleTrack track,
    String mediaPath,
  ) async {
    try {
      // Find ASS file based on subtitle track
      final assFile = await _findAssSubtitleFile(mediaPath, track);

      if (assFile == null || !await assFile.exists()) {
        print('ASS file not found for track: ${track.title}');
        return null;
      }

      // Load ASS file content
      final assContent = await assFile.readAsString();

      // Parse styling
      final assStyle = AssParser.parseStyle(assContent);
      print('ASS styling loaded from: ${assFile.path}');

      return assStyle;
    } catch (e) {
      print('Error loading ASS style: $e');
      return null;
    }
  }

  Future<File?> _findAssSubtitleFile(
    String mediaPath,
    SubtitleTrack track,
  ) async {
    final mediaFile = File(mediaPath);
    final mediaDir = mediaFile.parent;
    final mediaBaseName = mediaFile.path.substring(
      0,
      mediaFile.path.lastIndexOf('.'),
    );

    // Possible ASS file names
    final possibleNames = <String>[
      // Same name as video
      '$mediaBaseName.ass',
      '$mediaBaseName.ssa',
    ];

    // Add variants with language
    if (track.language != null) {
      possibleNames.add('$mediaBaseName.${track.language}.ass');
      possibleNames.add('$mediaBaseName.${track.language}.ssa');
    }

    // Add variant from title
    if (track.title != null && track.title!.contains('.')) {
      possibleNames.add('${mediaDir.path}/${track.title}');
    }

    // Try to find existing file
    for (final name in possibleNames) {
      final file = File(name);
      if (await file.exists()) {
        return file;
      }
    }

    return null;
  }

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
            _stopHideTimer(), // Only stops timer, doesn't hide controls
        cursor: _hideCursor
            ? SystemMouseCursors.none
            : SystemMouseCursors.basic,
        child: Stack(
          children: [
            _subtitleConfig != null
                ? Video(
                    controller: widget.controller,
                    controls: NoVideoControls,
                    subtitleViewConfiguration: _subtitleConfig!,
                  )
                : Video(
                    controller: widget.controller,
                    controls: NoVideoControls,
                  ),
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
      // Hide title bar and maximize window
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setFullScreen(true);
    } else {
      // Restore title bar and exit fullscreen
      await windowManager.setFullScreen(false);
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    }

    setState(() {});
  }
}
