import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veloxon/utils/video_file.dart';

class VideoScanner {
  static const List<String> videoExtensions = [
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.mpg',
    '.mpeg',
    '.3gp',
  ];

  Stream<VideoFile> scanAllDrives() async* {
    if (Platform.isWindows) {
      for (var letter in 'CDEFGHOJKLMNOPQRSTUVWXYZ'.split('')) {
        final drive = Directory('$letter:\\');
        if (await drive.exists()) {
          yield* scanDirectory(drive);
        }
      }
    }
  }

  // Přidej do třídy VideoScanner v video_scanner.dart
  Stream<FileSystemEntity> listDirectoryContents(String pathStr) async* {
    final dir = Directory(pathStr);
    if (await dir.exists()) {
      yield* dir.list(recursive: false); // Pouze aktuální úroveň
    }
  }

  Stream<VideoFile> scanSavedPaths() async* {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pathsToScan = prefs.getStringList('scanned_paths') ?? [];

    if (pathsToScan.isEmpty) return;

    for (var pathStr in pathsToScan) {
      final dir = Directory(pathStr);
      if (await dir.exists()) {
        yield* scanDirectory(dir);
      }
    }
  }

  Stream<VideoFile> scanDirectory(Directory dir) async* {
    try {
      await for (final entity in dir.list(recursive: false)) {
        try {
          if (entity is File) {
            final ext = path.extension(entity.path).toLowerCase();
            if (videoExtensions.contains(ext)) {
              final stat = await entity.stat();
              yield VideoFile(
                name: path.basename(entity.path),
                path: entity.path,
                extension: ext,
                size: stat.size,
                modified: stat.modified,
              );
            }
          } else if (entity is Directory) {
            yield* scanDirectory(entity);
          }
        } catch (e) {
          print("Chyba při přístupu k souboru: $e"); // Přidat logování
          continue;
        }
      }
    } catch (e) {
      print("Chyba při přístupu k adresáři ${dir.path}: $e");
    }
  }
}
