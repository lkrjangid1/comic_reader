// lib/src/widgets/comic_picker.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/comic_model.dart';
import '../parsers/comic_reader_parser.dart';

class ComicPicker extends StatefulWidget {
  final Function(ComicModel) onComicLoaded;
  final List<String> allowedExtensions;
  final Widget? icon;
  final String? buttonText;
  final Widget? loadingWidget;
  
  const ComicPicker({
    Key? key,
    required this.onComicLoaded,
    this.allowedExtensions = const ['.cbz', '.zip', '.cbt', '.tar', '.cbw'],
    this.icon,
    this.buttonText,
    this.loadingWidget,
  }) : super(key: key);

  @override
  State<ComicPicker> createState() => _ComicPickerState();
}

class _ComicPickerState extends State<ComicPicker> {
  bool _isLoading = false;

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