import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart';
import 'package:veloxon/videoplayer/veloxon_controls.dart';
import 'package:window_manager/window_manager.dart'; // Provides [VideoController] & [Video] etc.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  // Necessary initialization for package:media_kit.
  MediaKit.ensureInitialized();

  runApp(MaterialApp(home: const MyScreen(), theme: ThemeData.dark()));
}

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});
  @override
  State<MyScreen> createState() => MyScreenState();
}

class MyScreenState extends State<MyScreen> {
  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    print('=== MyScreen initState called ===');
    _initPlayer();
    _listenToTracks();
  }

  void _listenToTracks() {
    // Poslouchat změny v tracks
    player.stream.tracks.listen((tracks) {
      print('=== Tracks Stream Update ===');
      print('Audio tracks: ${tracks.audio.length}');
      for (var track in tracks.audio) {
        print(
          '  - Audio: id=${track.id}, title=${track.title}, lang=${track.language}',
        );
      }
      print('Subtitle tracks: ${tracks.subtitle.length}');
      for (var track in tracks.subtitle) {
        print(
          '  - Subtitle: id=${track.id}, title=${track.title}, lang=${track.language}',
        );
      }
      print('Video tracks: ${tracks.video.length}');
      for (var track in tracks.video) {
        print('  - Video: id=${track.id}, title=${track.title}');
      }
    });

    // Poslouchat změny v aktuálním tracku
    player.stream.track.listen((track) {
      print('=== Track Selection Changed ===');
      print(
        'Audio: id=${track.audio.id}, title=${track.audio.title}, lang=${track.audio.language}',
      );
      print(
        'Subtitle: id=${track.subtitle.id}, title=${track.subtitle.title}, lang=${track.subtitle.language}',
      );
      print('Video: id=${track.video.id}, title=${track.video.title}');
    });
  }

  Future<void> _initPlayer() async {
    print('=== Opening media file ===');
    // Play a [Media] or [Playlist].
    await player.open(Media('asset:///assets/test2.mkv'));
    print('=== Media file opened ===');

    // Počkat na načtení tracks
    await Future.delayed(const Duration(seconds: 2));
    print('=== After 2 second delay ===');

    try {
      // Vypsat dostupné tracks do konzole
      final tracks = await player.stream.tracks.first;
      print('=== Manual Tracks Check ===');
      print('Audio tracks: ${tracks.audio.length}');
      for (var track in tracks.audio) {
        print(
          '  - Audio: id=${track.id}, title=${track.title}, lang=${track.language}',
        );
      }
      print('Subtitle tracks: ${tracks.subtitle.length}');
      for (var track in tracks.subtitle) {
        print(
          '  - Subtitle: id=${track.id}, title=${track.title}, lang=${track.language}',
        );
      }
      print('Video tracks: ${tracks.video.length}');
      for (var track in tracks.video) {
        print('  - Video: id=${track.id}, title=${track.title}');
      }
    } catch (e) {
      print('Error getting tracks: $e');
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 9.0 / 16.0,
          // Use [Video] widget to display video output.
          child: VeloxonPlayer(controller: controller),
        ),
      ),
    );
  }
}
