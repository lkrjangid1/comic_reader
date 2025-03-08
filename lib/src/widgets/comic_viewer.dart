// lib/src/widgets/comic_viewer.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../models/comic_model.dart';

class ComicViewer extends StatefulWidget {
  final ComicModel comic;
  final int initialPage;
  final bool showControls;
  final Color backgroundColor;
  
  const ComicViewer({
    Key? key,
    required this.comic,
    this.initialPage = 0,
    this.showControls = true,
    this.backgroundColor = Colors.black,
  }) : super(key: key);

  @override
  State<ComicViewer> createState() => _ComicViewerState();
}

class _ComicViewerState extends State<ComicViewer> {
  late PageController _pageController;
  late int _currentPage;
  bool _isControlsVisible = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.comic.comicPages.isEmpty) {
      return const Center(child: Text('No pages found'));
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Stack(
        children: [
          // Comic pages
          GestureDetector(
            onTap: _toggleControls,
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(widget.comic.comicPages[index])),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              itemCount: widget.comic.comicPages.length,
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null ? 0 : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              ),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              backgroundDecoration: BoxDecoration(color: widget.backgroundColor),
            ),
          ),
          
          // Controls
          if (widget.showControls && _isControlsVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicator
                    Text(
                      'Page ${_currentPage + 1} of ${widget.comic.comicPages.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8.0),
                    
                    // Page slider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Slider(
                        value: _currentPage.toDouble(),
                        min: 0,
                        max: (widget.comic.comicPages.length - 1).toDouble(),
                        divisions: widget.comic.comicPages.length - 1,
                        onChanged: (double value) {
                          _pageController.jumpToPage(value.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // App bar with title
          if (widget.showControls && _isControlsVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.5),
                elevation: 0,
                title: Text(widget.comic.comicName),
              ),
            ),
        ],
      ),
    );
  }
}