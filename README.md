# Comic Reader

A Flutter package for reading and parsing comic book archives such as CBZ, CBT, ZIP, and TAR files.

## Features

- Parse and extract comic files (CBZ, ZIP, CBT, TAR)
- Display comics with a smooth page navigation experience
- Zoom, pan, and scroll through comic pages
- Simple file picker integration
- Full-featured viewer with page controls
<img src="https://github.com/user-attachments/assets/6c89b041-fe50-4255-ab60-4e9c484de3ba" width="200" height="350">


## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  comic_reader: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Platform Configuration

### Android

Update your `android/app/src/main/AndroidManifest.xml` to include file read/write permissions:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

For Android 13 (API level 33) and above, you may need to add:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### iOS

Update your `ios/Runner/Info.plist` to include file access:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Need access to open comic files</string>
<key>UISupportsDocumentBrowser</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

## Usage

### Basic Example

```dart
import 'package:flutter/material.dart';
import 'package:comic_reader/comic_reader.dart';

class ComicReaderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comic Reader'),
      ),
      body: Center(
        child: ComicPicker(
          onComicLoaded: (comic) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComicViewer(comic: comic),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

### ComicViewer Widget

The `ComicViewer` widget displays a comic with page navigation controls:

```dart
ComicViewer(
  comic: myComicModel,         // Required: ComicModel to display
  initialPage: 0,              // Optional: Starting page index
  showControls: true,          // Optional: Show navigation controls
  backgroundColor: Colors.black, // Optional: Background color
)
```

### ComicPicker Widget

The `ComicPicker` widget provides a button to open the device's file picker:

```dart
ComicPicker(
  onComicLoaded: (ComicModel comic) {
    // Handle the loaded comic
  },
  allowedExtensions: ['.cbz', '.zip', '.cbt', '.tar'], // Optional: Allowed file extensions
  buttonText: 'Open Comic',    // Optional: Custom button text
  icon: Icon(Icons.book),      // Optional: Custom icon
  loadingWidget: CircularProgressIndicator(), // Optional: Custom loading widget
)
```

### Parser Usage

You can also use the parser directly:

```dart
final parser = ComicReaderParser();
final comic = await parser.pickAndParseComicFile('/path/to/comic.cbz');

// Access comic info
print('Comic name: ${comic.comicName}');
print('Number of pages: ${comic.comicPages.length}');
```

## Supported Formats

- CBZ (Comic Book ZIP)
- ZIP
- CBT (Comic Book TAR)
- TAR
- CBW (Comic Book Web - ZIP variant)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
