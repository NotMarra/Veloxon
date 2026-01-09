import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_video_thumbnail/get_video_thumbnail.dart';
import 'package:get_video_thumbnail/index.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloxon/ui/settings.dart';
import 'package:veloxon/utils/video_file.dart';
import 'package:veloxon/utils/video_scanner.dart';
import 'package:veloxon/videoplayer/veloxon_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class VideoFinder extends StatefulWidget {
  const VideoFinder({super.key});

  @override
  State<VideoFinder> createState() => _VideoFinderState();
}

class _VideoFinderState extends State<VideoFinder> {
  final VideoScanner _scanner = VideoScanner();
  final List<VideoFile> _allVideos = [];
  List<dynamic> _filteredItems = [];
  bool _isScanning = false;
  String _searchQuery = '';
  String _selectedExtension = 'All';
  final Map<String, String?> _thumbnailCache = {};

  String? _currentFolder;
  final List<String> _folderHistory = [];
  final List<String> _thumbnailQueue = [];
  bool _isGeneratingThumbnails = false;

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

  // --- LOGIKA SKENOVÁNÍ ---

  Future<void> _startScan() async {
    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _allVideos.clear();
      _filteredItems.clear();
      _thumbnailQueue.clear();
      _currentFolder = null;
      _folderHistory.clear();
    });

    try {
      await for (final video in _scanner.scanSavedPaths()) {
        if (mounted) {
          setState(() {
            _allVideos.add(video);
            _applyFilters();
          });
          _thumbnailQueue.add(video.path);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
        _processThumbnailQueue();
      }
    }
  }

  void _applyFilters() {
    var filtered = _allVideos.where((video) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          video.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesExtension =
          _selectedExtension == 'All' || video.extension == _selectedExtension;
      return matchesSearch && matchesExtension;
    }).toList();

    List<dynamic> newItems = [];

    if (_currentFolder == null) {
      // Režim ROOT: Seskupení do složek
      final Map<String, List<VideoFile>> groups = {};
      for (var v in filtered) {
        final dirPath = path.dirname(v.path);
        groups.putIfAbsent(dirPath, () => []).add(v);
      }

      newItems = groups.entries
          .map(
            (e) => FolderItem(
              name: path.basename(e.key),
              path: e.key,
              videoCount: e.value.length,
            ),
          )
          .toList();
    } else {
      // Režim SLOŽKA: Jen videa v této složce
      newItems = filtered
          .where((v) => path.dirname(v.path) == _currentFolder)
          .toList();
    }

    setState(() {
      _filteredItems = newItems;
    });
  }

  // --- NAVIGACE ---

  void _openFolder(FolderItem folder) {
    setState(() {
      if (_currentFolder != null) _folderHistory.add(_currentFolder!);
      _currentFolder = folder.path;
      _applyFilters();
    });
  }

  void _goBack() {
    setState(() {
      if (_folderHistory.isNotEmpty) {
        _currentFolder = _folderHistory.removeLast();
      } else {
        _currentFolder = null;
      }
      _applyFilters();
    });
  }

  // --- MINIATURY ---

  Future<void> _processThumbnailQueue() async {
    if (_isGeneratingThumbnails) return;
    _isGeneratingThumbnails = true;

    while (_thumbnailQueue.isNotEmpty) {
      final videoPath = _thumbnailQueue.removeAt(0);
      await _generateThumbnail(videoPath);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _isGeneratingThumbnails = false;
  }

  Future<void> _generateThumbnail(String videoPath) async {
    if (_thumbnailCache.containsKey(videoPath)) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final XFile? thumb = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );

      if (thumb != null && mounted) {
        setState(() => _thumbnailCache[videoPath] = thumb.path);
      }
    } catch (e) {
      if (mounted) setState(() => _thumbnailCache[videoPath] = null);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veloxon'),
        leading: _currentFolder != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              _startScan();
            },
          ),
          IconButton(
            onPressed: _isScanning ? null : _startScan,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_currentFolder != null) _buildBreadcrumb(),
          _buildStatusBar(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.black26,
      child: Text(
        "Složka: ${path.basename(_currentFolder!)}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xff0090fc),
      child: Row(
        children: [
          Text(
            'Položek: ${_filteredItems.length}',
            style: const TextStyle(color: Colors.white),
          ),
          const Spacer(),
          if (_isScanning)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        if (item is FolderItem) return _buildFolderCard(item);
        if (item is VideoFile) return _buildVideoCard(item);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFolderCard(FolderItem folder) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFolder(folder),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Icon(Icons.folder, size: 64, color: Colors.blue),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                folder.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${folder.videoCount} videos',
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(VideoFile video) {
    final thumb = _thumbnailCache[video.path];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(videoPath: video.path),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: thumb != null
                  ? Image.file(File(thumb), fit: BoxFit.cover)
                  : Container(
                      color: Colors.black87,
                      child: const Icon(Icons.play_circle_outline, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    _formatSize(video.size),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- POMOCNÉ TŘÍDY (Tyto třídy nesmí chybět!) ---

class FolderItem {
  final String name;
  final String path;
  final int videoCount;
  FolderItem({
    required this.name,
    required this.path,
    required this.videoCount,
  });
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
    player.open(Media(widget.videoPath));
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
