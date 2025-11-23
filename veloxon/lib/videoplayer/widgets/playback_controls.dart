import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';

class PlaybackControls extends StatelessWidget {
  final Player player;

  const PlaybackControls({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.stepBack, color: Colors.white),
              onPressed: () async {
                final position = await player.stream.position.first;
                await player.seek(
                  position - const Duration(seconds: 10),
                );
              },
            ),
            IconButton(
              icon: Icon(
                isPlaying ? LucideIcons.pause : LucideIcons.play,
                color: Colors.white,
              ),
              onPressed: () => player.playOrPause(),
            ),
            IconButton(
              icon: const Icon(LucideIcons.stepForward, color: Colors.white),
              onPressed: () async {
                final position = await player.stream.position.first;
                await player.seek(
                  position + const Duration(seconds: 10),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
