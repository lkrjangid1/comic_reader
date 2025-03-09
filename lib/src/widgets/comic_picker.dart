// lib/src/widgets/comic_picker.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/comic_model.dart';
import '../parsers/comic_reader_parser.dart';

/// A widget that allows users to select and load comic files.
///
/// This widget provides a button that, when pressed, opens a file picker dialog
/// configured to select only comic files with the specified extensions.
/// Once a file is selected, it is parsed into a [ComicModel] and passed to the
/// provided callback.
///
/// Features:
/// * Customizable button appearance with icon and text
/// * Configurable list of allowed file extensions
/// * Custom loading indicator support
/// * Automatic error handling with SnackBar notifications
class ComicPicker extends StatefulWidget {
  /// Callback function that is called when a comic file is successfully loaded.
  ///
  /// This function receives the parsed [ComicModel] containing comic pages and name.
  final Function(ComicModel) onComicLoaded;

  /// List of file extensions that can be selected from the file picker.
  ///
  /// Default extensions include: '.cbz', '.zip', '.cbt', '.tar', '.cbw'
  /// Extensions should include the leading dot.
  final List<String> allowedExtensions;

  /// Custom icon to display on the picker button.
  ///
  /// If not provided, defaults to [Icons.book].
  final Widget? icon;

  /// Custom text to display on the picker button.
  ///
  /// If not provided, defaults to 'Pick Comic File'.
  final String? buttonText;

  /// Custom widget to display while loading.
  ///
  /// If not provided, defaults to a centered [CircularProgressIndicator].
  final Widget? loadingWidget;
  
  /// Creates a new [ComicPicker] widget.
  ///
  /// The [onComicLoaded] callback is required and will be called when a
  /// comic file is successfully selected and parsed.
  ///
  /// Example:
  /// ```dart
  /// ComicPicker(
  ///   onComicLoaded: (comicModel) {
  ///     // Handle the loaded comic
  ///     setState(() {
  ///       currentComic = comicModel;
  ///     });
  ///   },
  ///   buttonText: 'Select a Comic',
  ///   icon: Icon(Icons.file_open),
  /// )
  /// ```
  const ComicPicker({
    super.key,
    required this.onComicLoaded,
    this.allowedExtensions = const ['.cbz', '.zip', '.cbt', '.tar', '.cbw'],
    this.icon,
    this.buttonText,
    this.loadingWidget,
  });

  @override
  State<ComicPicker> createState() => _ComicPickerState();
}

/// The state class for [ComicPicker].
///
/// Manages the loading state and file picking logic.
class _ComicPickerState extends State<ComicPicker> {
  /// Flag indicating whether a comic file is currently being loaded.
  bool _isLoading = false;

  /// Opens a file picker dialog and processes the selected comic file.
  ///
  /// This method:
  /// 1. Shows a loading indicator
  /// 2. Opens the file picker with configured allowed extensions
  /// 3. Parses the selected file using [ComicReaderParser]
  /// 4. Calls [onComicLoaded] with the parsed [ComicModel]
  /// 5. Shows an error message if anything fails
  /// 6. Hides the loading indicator when complete
  Future<void> _pickComicFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions
            .map((e) => e.replaceAll('.', ''))
            .toList(),
      );

      if (result != null && result.files.single.path != null) {
        final parser = ComicReaderParser();
        final comicModel = await parser.pickAndParseComicFile(result.files.single.path!);
        
        if (mounted) {
          widget.onComicLoaded(comicModel);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comic: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? 
        const Center(child: CircularProgressIndicator());
    }

    return ElevatedButton.icon(
      onPressed: _pickComicFile,
      icon: widget.icon ?? const Icon(Icons.book),
      label: Text(widget.buttonText ?? 'Pick Comic File'),
    );
  }
}