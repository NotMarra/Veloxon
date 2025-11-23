import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:veloxon/ui/menu_anchor.dart';

class SettingsMenu extends StatefulWidget {
  final Player player;
  final VoidCallback stopHideTimer;
  final VoidCallback restartHideTimer;

  const SettingsMenu({
    super.key,
    required this.player,
    required this.stopHideTimer,
    required this.restartHideTimer,
  });

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  MenuController? _settingsMenuController;
  Track? _currentTrack;

  @override
  void initState() {
    super.initState();
    widget.player.stream.track.listen((track) {
      if (mounted) {
        setState(() {
          _currentTrack = track;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: widget.player.stream.tracks,
      builder: (context, tracksSnapshot) {
        final tracks = tracksSnapshot.data;

        return VeloxonIconMenuAnchor(
          icon: LucideIcons.settings,
          onControllerCreated: (controller) {
            _settingsMenuController = controller;
          },
          onOpen: widget.stopHideTimer,
          onClose: widget.restartHideTimer,
          menuChildren: [
            _buildAudioTrackSubmenu(tracks),
            _buildSubtitleSubmenu(tracks),
          ],
        );
      },
    );
  }

  Widget _buildAudioTrackSubmenu(Tracks? tracks) {
    final audioTracks =
        tracks?.audio
            .where((track) => track.id != 'auto' && track.id != 'no')
            .toList() ??
        [];

    final currentTrack = _currentTrack?.audio ?? AudioTrack.auto();

    return VeloxonSubmenuAnchor(
      label: 'Audio Track',
      icon: LucideIcons.audioLines,
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            await widget.player.setAudioTrack(AudioTrack.auto());
            await Future.delayed(const Duration(milliseconds: 100));
            _settingsMenuController?.close();
          },
          style: MenuItemButton.styleFrom(
            backgroundColor: currentTrack.id == 'auto'
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ...audioTracks.map((track) {
          final isSelected = currentTrack.id == track.id;
          final label = track.title ?? track.language ?? 'Track ${track.id}';

          return MenuItemButton(
            onPressed: () async {
              await widget.player.setAudioTrack(track);
              await Future.delayed(const Duration(milliseconds: 100));
              _settingsMenuController?.close();
            },
            style: MenuItemButton.styleFrom(
              backgroundColor: isSelected
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            leadingIcon: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : const SizedBox(width: 18),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubtitleSubmenu(Tracks? tracks) {
    final subtitleTracks =
        tracks?.subtitle
            .where((track) => track.id != 'auto' && track.id != 'no')
            .toList() ??
        [];

    final currentTrack = _currentTrack?.subtitle ?? SubtitleTrack.no();

    return VeloxonSubmenuAnchor(
      label: 'Subtitles',
      icon: LucideIcons.captions,
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            await widget.player.setSubtitleTrack(SubtitleTrack.no());
            await Future.delayed(const Duration(milliseconds: 100));
            _settingsMenuController?.close();
          },
          style: MenuItemButton.styleFrom(
            backgroundColor: currentTrack.id == 'no'
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        MenuItemButton(
          onPressed: () async {
            await widget.player.setSubtitleTrack(SubtitleTrack.auto());
            await Future.delayed(const Duration(milliseconds: 100));
            _settingsMenuController?.close();
          },
          style: MenuItemButton.styleFrom(
            backgroundColor: currentTrack.id == 'auto'
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ...subtitleTracks.map((track) {
          final isSelected = currentTrack.id == track.id;
          final label = track.title ?? track.language ?? 'Track ${track.id}';

          return MenuItemButton(
            onPressed: () async {
              await widget.player.setSubtitleTrack(track);
              await Future.delayed(const Duration(milliseconds: 100));
              _settingsMenuController?.close();
            },
            style: MenuItemButton.styleFrom(
              backgroundColor: isSelected
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            leadingIcon: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : const SizedBox(width: 18),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ],
    );
  }
}
