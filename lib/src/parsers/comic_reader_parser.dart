// lib/src/parsers/comic_reader_parser.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/comic_model.dart';

/// Represents supported comic archive file formats.
///
/// This enum defines the underlying archive types used in comic book files:
/// * [zip] - Used for CBZ and ZIP comic archives
/// * [tar] - Used for CBT and TAR comic archives
enum ArchiveType {
  /// ZIP archive format, used in CBZ and ZIP files
  zip,

  /// TAR archive format, used in CBT and TAR files
  tar;

  @override
  String toString() => name;
}

/// Parser for extracting and processing comic book archive files.
///
/// This class provides functionality to:
/// * Parse various comic book archive formats (CBZ, CBT, ZIP, TAR)
/// * Extract images from these archives
/// * Create a structured [ComicModel] from the extracted content
///
/// Usage:
/// ```dart
/// final parser = ComicReaderParser();
/// final comicModel = await parser.pickAndParseComicFile('/path/to/comic.cbz');
/// ```
class ComicReaderParser {
  /// The name of the currently processing comic book.
  ///
  /// This is extracted from the filename without extension.
  String currentComicName = '';

  /// Parses a comic file and returns a [ComicModel] with extracted pages.
  ///
  /// This method:
  /// * Validates the file exists
  /// * Determines the file type from its extension
  /// * Extracts the comic name from the filename
  /// * Calls the appropriate parser based on file extension
  /// * Returns a [ComicModel] with sorted page paths and comic name
  ///
  /// Parameters:
  /// * [filePath] - The path to the comic file to be parsed
  ///
  /// Returns:
  /// * A [ComicModel] containing the list of extracted image paths and comic name
  ///
  /// Throws:
  /// * [FileSystemException] if the file doesn't exist
  /// * [Exception] for general parsing errors
  /// * [UnsupportedError] for unsupported file formats
  Future<ComicModel> pickAndParseComicFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final fileExt = path.extension(filePath).toLowerCase();
      currentComicName = path.basenameWithoutExtension(filePath);

      // Map comic extensions to their actual archive types for naming clarity
      final List<String> extractedFiles =
          await _parseArchiveByExtension(file, fileExt);

      // Sort files for proper reading order
      extractedFiles.sort();
      return ComicModel(
          comicPages: extractedFiles, comicName: currentComicName);
    } catch (e) {
      print('Error in pickAndParseComicFile: $e');
      throw Exception('Error parsing comic file: $e');
    }
  }

  /// Determines the appropriate parser based on file extension.
  ///
  /// Maps common comic book file extensions to their corresponding archive type
  /// and calls the appropriate extraction method.
  ///
  /// Parameters:
  /// * [file] - The comic file to parse
  /// * [fileExt] - The lowercase file extension (including the dot)
  ///
  /// Returns:
  /// * A list of paths to the extracted image files
  ///
  /// Throws:
  /// * [UnsupportedError] for unsupported file extensions
  Future<List<String>> _parseArchiveByExtension(
      File file, String fileExt) async {
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
        return await _extractArchive(
            file, '.cbw', ArchiveType.zip); // CBW is essentially ZIP
      default:
        throw UnsupportedError('Unsupported comic format: $fileExt');
    }
  }

  /// Renames a file while keeping its directory path unchanged.
  ///
  /// Parameters:
  /// * [file] - The file to rename
  /// * [newFileName] - The new filename (without path)
  ///
  /// Returns:
  /// * A [Future<File>] pointing to the renamed file
  Future<File> changeFileNameOnly(File file, String newFileName) {
    var path = file.path;
    var lastSeparator = path.lastIndexOf(Platform.pathSeparator);
    var newPath = path.substring(0, lastSeparator + 1) + newFileName;
    return file.rename(newPath);
  }

  /// Extracts an archive file with the appropriate decoder based on type.
  ///
  /// This method:
  /// * Renames the file to a sanitized version of the comic name
  /// * Reads the file bytes
  /// * Decodes the archive based on its type
  /// * Extracts image files from the archive
  ///
  /// Parameters:
  /// * [oldFile] - The original comic archive file
  /// * [fileType] - The original file extension (e.g., '.cbz')
  /// * [type] - The [ArchiveType] to use for decoding
  ///
  /// Returns:
  /// * A list of paths to the extracted image files
  ///
  /// Throws:
  /// * [Exception] if the file is empty or decoding fails
  Future<List<String>> _extractArchive(
      File oldFile, String fileType, ArchiveType type) async {
    try {
      File file = await changeFileNameOnly(
          oldFile,
          currentComicName
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
              archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
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
      throw Exception(
          'Failed to parse ${type.toString().toUpperCase()} archive: $e');
    }
  }

  /// Extracts only image files from the archive.
  ///
  /// This method:
  /// * Creates a temporary directory for the extracted files
  /// * Clears any previous extraction with the same name
  /// * Filters for only image files based on extension
  /// * Writes each image file to the temporary directory
  /// * Returns the paths to all extracted images
  ///
  /// Parameters:
  /// * [archive] - The decoded archive object
  /// * [archiveType] - The string representation of the archive type
  ///
  /// Returns:
  /// * A list of paths to the extracted image files
  ///
  /// Throws:
  /// * [Exception] if extraction fails
  Future<List<String>> _extractImageFiles(
      Archive archive, String archiveType) async {
    try {
      final List<String> extractedFiles = [];
      final tempDir = await getTemporaryDirectory();
      final archiveDirName =
          '${currentComicName}_$archiveType'; // Add archive type to folder name
      final comicDir = await Directory('${tempDir.path}/$archiveDirName')
          .create(recursive: true);

      // Clear previous files
      if (await comicDir.exists()) {
        await comicDir.delete(recursive: true);
        await comicDir.create(recursive: true);
      }

      // Valid image extensions
      final validExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.bmp'
      ];

      // Extract only image files
      for (final file in archive) {
        if (!file.isFile) continue;

        final fileName = file.name.toLowerCase();
        final isImageFile =
            validExtensions.any((ext) => fileName.endsWith(ext));

        if (isImageFile) {
          try {
            final data = file.content as List<int>;
            // Create a more descriptive filename that includes original path structure
            final sanitizedName = path
                .basename(file.name)
                .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
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
