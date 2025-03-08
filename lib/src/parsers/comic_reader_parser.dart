// lib/src/parsers/comic_reader_parser.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/comic_model.dart';

/// Enum to represent supported archive types
enum ArchiveType {
  zip,
  tar;
  
  @override
  String toString() => name;
}

class ComicReaderParser {
  String currentComicName = '';

  /// Parses a comic file and returns a ComicModel with extracted pages
  Future<ComicModel> pickAndParseComicFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final fileExt = path.extension(filePath).toLowerCase();
      currentComicName = path.basenameWithoutExtension(filePath);
      
      // Map comic extensions to their actual archive types for naming clarity
      final List<String> extractedFiles = await _parseArchiveByExtension(file, fileExt);
      
      // Sort files for proper reading order
      extractedFiles.sort();
      return ComicModel(comicPages: extractedFiles, comicName: currentComicName);
    } catch (e) {
      print('Error in pickAndParseComicFile: $e');
      throw Exception('Error parsing comic file: $e');
    }
  }

  /// Determines the appropriate parser based on file extension
  Future<List<String>> _parseArchiveByExtension(File file, String fileExt) async {
    switch (fileExt) {
      case '.cbz':
        return await _extractArchive(file, '.cbz', ArchiveType.zip);
      case '.zip':
        return await _extractArchive(file, '.zip', ArchiveType.zip);
      case '.cbt':
        return await _extractArchive(file, '.cbt', ArchiveType.tar);
      case '.tar':
        return await _extractArchive(file, '.tar', ArchiveType.tar);
      case '.cbw':
        return await _extractArchive(file, '.cbw', ArchiveType.zip); // CBW is essentially ZIP
      default:
        throw UnsupportedError('Unsupported comic format: $fileExt');
    }
  }

  Future<File> changeFileNameOnly(File file, String newFileName) {
    var path = file.path;
    var lastSeparator = path.lastIndexOf(Platform.pathSeparator);
    var newPath = path.substring(0, lastSeparator + 1) + newFileName;
    return file.rename(newPath);
  }

  /// Extracts an archive file with appropriate decoder based on type
  Future<List<String>> _extractArchive(File oldFile, String fileType, ArchiveType type) async {
    try {
      File file = await changeFileNameOnly(oldFile, currentComicName
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_')
          .replaceAll(fileType, '.${type.toString()}'));
      
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('File is empty');
      }
      
      Archive archive;
      final String typeStr = type.toString();
      
      try {
        switch (type) {
          case ArchiveType.zip:
            try {
              archive = ZipDecoder().decodeBytes(bytes);
            } catch (e) {
              // Fallback for large files
              final inputStream = InputFileStream(file.path);
              archive = ZipDecoder().decodeBuffer(inputStream);
              inputStream.close();
            }
            break;
          case ArchiveType.tar:
            archive = TarDecoder().decodeBytes(bytes);
            break;
        }
      } catch (e) {
        print('Error decoding $typeStr archive: $e');
        rethrow;
      }
      
      return await _extractImageFiles(archive, typeStr);
    } catch (e) {
      print('Error extracting $type archive: $e');
      throw Exception('Failed to parse ${type.toString().toUpperCase()} archive: $e');
    }
  }

  /// Extracts only image files from the archive
  Future<List<String>> _extractImageFiles(Archive archive, String archiveType) async {
    try {
      final List<String> extractedFiles = [];
      final tempDir = await getTemporaryDirectory();
      final archiveDirName = '${currentComicName}_$archiveType'; // Add archive type to folder name
      final comicDir = await Directory('${tempDir.path}/$archiveDirName')
          .create(recursive: true);

      // Clear previous files
      if (await comicDir.exists()) {
        await comicDir.delete(recursive: true);
        await comicDir.create(recursive: true);
      }

      // Valid image extensions
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
      
      // Extract only image files
      for (final file in archive) {
        if (!file.isFile) continue;
        
        final fileName = file.name.toLowerCase();
        final isImageFile = validExtensions.any((ext) => fileName.endsWith(ext));
        
        if (isImageFile) {
          try {
            final data = file.content as List<int>;
            // Create a more descriptive filename that includes original path structure
            final sanitizedName = path.basename(file.name).replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
            final filePath = '${comicDir.path}/$sanitizedName';
            
            await File(filePath).writeAsBytes(data);
            extractedFiles.add(filePath);
          } catch (e) {
            print('Failed to extract ${file.name}: $e');
            // Continue with other files
          }
        }
      }
      
      if (extractedFiles.isEmpty) {
        print('Warning: No image files found in $archiveType archive');
      }
      
      return extractedFiles;
    } catch (e) {
      print('Error extracting image files: $e');
      throw Exception('Error extracting images from archive: $e');
    }
  }
}