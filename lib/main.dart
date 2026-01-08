import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:window_manager/window_manager.dart'; // Provides [VideoController] & [Video] etc.
import 'package:veloxon/ui/video_finder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  MediaKit.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veloxon',
      theme: ThemeData.dark(),
      home: const VideoFinder(),
    );
  }
}
