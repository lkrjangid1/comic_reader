// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:comic_reader/comic_reader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comic Reader Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ComicModel? _currentComic;

  void _openComic(ComicModel comic) {
    setState(() {
      _currentComic = comic;
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicViewer(comic: comic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comic Reader Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ComicPicker(
              onComicLoaded: _openComic,
              buttonText: 'Open Comic Book',
              icon: const Icon(Icons.book),
            ),
            const SizedBox(height: 20),
            if (_currentComic != null)
              Text(
                'Last opened: ${_currentComic!.comicName}\n'
                '${_currentComic!.comicPages.length} pages',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}