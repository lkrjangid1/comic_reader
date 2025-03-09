// lib/src/widgets/comic_viewer.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../models/comic_model.dart';

/// A widget that displays a comic book with pages that can be swiped through.
///
/// The [ComicViewer] uses [PhotoViewGallery] to provide a responsive and
/// interactive comic reading experience with zoom capabilities and page navigation.
/// It displays a full-screen comic viewer with optional controls for navigation.
class ComicViewer extends StatefulWidget {
  /// The comic model containing the comic data including pages to display.
  final ComicModel comic;
  
  /// The initial page index to display when the viewer is first opened.
  /// Defaults to 0 (first page).
  final int initialPage;
  
  /// Whether to show navigation controls like the app bar and page slider.
  /// Defaults to true.
  final bool showControls;
  
  /// The background color of the comic viewer.
  /// Defaults to black for a standard comic reading experience.
  final Color backgroundColor;
  
  /// Creates a comic viewer widget.
  ///
  /// The [comic] parameter is required and contains the comic data to display.
  /// [initialPage] specifies which page to show first (zero-indexed).
  /// [showControls] determines if navigation UI elements should be displayed.
  /// [backgroundColor] sets the viewer's background color.
  const ComicViewer({
    super.key,
    required this.comic,
    this.initialPage = 0,
    this.showControls = true,
    this.backgroundColor = Colors.black,
  });

  @override
  State<ComicViewer> createState() => _ComicViewerState();
}

/// The state class for [ComicViewer] that manages the page controller and UI state.
class _ComicViewerState extends State<ComicViewer> {
  /// Controls the current page being displayed and handles page transitions.
  late PageController _pageController;
  
  /// Tracks the index of the currently displayed page.
  late int _currentPage;
  
  /// Determines whether the navigation controls are currently visible.
  /// Controls are toggled by tapping on the comic page.
  bool _isControlsVisible = true;

  /// Initializes the state of the comic viewer.
  ///
  /// Sets up the page controller with the initial page provided in the widget
  /// and initializes the current page tracking variable.
  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  /// Cleans up resources when the widget is removed from the tree.
  ///
  /// Disposes the page controller to prevent memory leaks.
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Toggles the visibility of the navigation controls.
  ///
  /// This method is called when the user taps on the comic page.
  /// It switches the visibility state of the controls overlay.
  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  /// Builds the comic viewer UI.
  ///
  /// Creates a scaffold containing:
  /// - A [PhotoViewGallery] for displaying and interacting with comic pages
  /// - Navigation controls that appear at the top and bottom when visible
  /// - Page indicator and slider for navigation between pages
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
                color: const Color(0x80000000),
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
                backgroundColor: const Color(0x80000000),
                elevation: 0,
                title: Text(widget.comic.comicName),
              ),
            ),
        ],
      ),
    );
  }
}