import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:veloxon/utils/video_file.dart';
import 'package:veloxon/utils/video_scanner.dart';
import 'package:veloxon/videoplayer/veloxon_player.dart';

class VideoFinder extends StatefulWidget {
  const VideoFinder({super.key});

  @override
  State<VideoFinder> createState() => _VideoFinderState();
}

class _VideoFinderState extends State<VideoFinder> {
  final VideoScanner _scanner = VideoScanner();
  final List<VideoFile> _allVideos = [];
  List<VideoFile> _filteredVideos = [];
  bool _isScanning = false;
  String _searchQuery = '';
  String _selectedExtension = 'All';
  final List<String> _extensions = [
    'All',
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.wmv',
  ];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _allVideos.clear();
      _filteredVideos.clear();
    });

    await for (final video in _scanner.scanAllDrives()) {
      setState(() {
        _allVideos.add(video);
        _applyFilters();
      });
    }

    setState(() {
      _isScanning = false;
    });
  }

  void _applyFilters() {
    _filteredVideos = _allVideos.where((video) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          video.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          video.path.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesExtension =
          _selectedExtension == 'All' || video.extension == _selectedExtension;

      return matchesSearch && matchesExtension;
    }).toList();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _playVideo(VideoFile video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoPath: video.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Veloxon'),
        actions: [
          IconButton(
            onPressed: _isScanning ? null : _startScan,
            icon: Icon(LucideIcons.refreshCcw),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(hintText: 'Search videos...'),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20),
                    const SizedBox(width: 8),
                    const Text('Format:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: _extensions.map((ext) {
                          return FilterChip(
                            label: Text(ext),
                            selected: _selectedExtension == ext,
                            onSelected: (selected) {
                              setState(() {
                                _selectedExtension = ext;
                                _applyFilters();
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Color(0xff0090fc),
            child: Row(
              children: [
                if (_isScanning) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text('Scanning...'),
                ] else ...[
                  const Icon(
                    Icons.check_circle,
                    color: Color.fromARGB(255, 0, 255, 8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('Found: ${_filteredVideos.length} videos'),
                ],
                const Spacer(),
                Text(
                  'Sum: ${_allVideos.length}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          Expanded(
            child: _filteredVideos.isEmpty && !_isScanning
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No videos...',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredVideos.length,
                    itemBuilder: (context, index) {
                      final video = _filteredVideos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple[700],
                            child: const Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            video.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                video.path,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.storage,
                                    size: 12,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatSize(video.size),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[900],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      video.extension,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.folder_open),
                            onPressed: () {
                              final dir = Directory(video.path).parent;
                              if (Platform.isWindows) {
                                Process.run('explorer', [dir.path]);
                              } else if (Platform.isMacOS) {
                                Process.run('open', [dir.path]);
                              } else {
                                Process.run('xdg-open', [dir.path]);
                              }
                            },
                          ),
                          onTap: () => _playVideo(video),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    debugPrint('=== VideoPlayerScreen initState called ===');
    _initPlayer();
    _listenToTracks();
  }

  void _listenToTracks() {
    player.stream.tracks.listen((tracks) {
      debugPrint('=== Tracks Stream Update ===');
      debugPrint('Audio tracks: ${tracks.audio.length}');
      for (var track in tracks.audio) {
        debugPrint(
          '  - Audio: id=${track.id}, title=${track.title}, lang=${track.language}',
        );
      }
      debugPrint('Subtitle tracks: ${tracks.subtitle.length}');
      for (var track in tracks.subtitle) {
        debugPrint(
          '  - Subtitle: id=${track.id}, title=${track.title}, lang=${track.language}',
        );
      }
      debugPrint('Video tracks: ${tracks.video.length}');
      for (var track in tracks.video) {
        debugPrint('  - Video: id=${track.id}, title=${track.title}');
      }
    });

    player.stream.track.listen((track) {
      debugPrint('=== Track Selection Changed ===');
      debugPrint(
        'Audio: id=${track.audio.id}, title=${track.audio.title}, lang=${track.audio.language}',
      );
      debugPrint(
        'Subtitle: id=${track.subtitle.id}, title=${track.subtitle.title}, lang=${track.subtitle.language}',
      );
      debugPrint('Video: id=${track.video.id}, title=${track.video.title}');
    });
  }

  Future<void> _initPlayer() async {
    debugPrint('=== Opening media file: ${widget.videoPath} ===');
    // Otevře vybrané video
    await player.open(Media(widget.videoPath));
    debugPrint('=== Media file opened ===');

    await Future.delayed(const Duration(seconds: 2));
    debugPrint('=== After 2 second delay ===');

    try {
      final tracks = await player.stream.tracks.first;
      debugPrint('=== Manual Tracks Check ===');
      debugPrint('Audio tracks: ${tracks.audio.length}');
      for (var track in tracks.audio) {
        debugPrint(
          '  - Audio: id=${track.id}, title=${track.title}, lang=${track.language}',
        );
      }
      debugPrint('Subtitle tracks: ${tracks.subtitle.length}');
      for (var track in tracks.subtitle) {
        debugPrint(
          '  - Subtitle: id=${track.id}, title=${track.title}, lang=${track.language}',
        );
      }
      debugPrint('Video tracks: ${tracks.video.length}');
      for (var track in tracks.video) {
        debugPrint('  - Video: id=${track.id}, title=${track.title}');
      }
    } catch (e) {
      debugPrint('Error getting tracks: $e');
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
          child: VeloxonPlayer(controller: controller),
        ),
      ),
    );
  }
}
