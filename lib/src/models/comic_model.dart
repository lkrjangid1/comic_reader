// lib/src/models/comic_model.dart
class ComicModel {
  final List<String> comicPages;
  final String comicName;

  ComicModel({
    required this.comicPages,
    required this.comicName,
  });

  Map<String, dynamic> toJson() {
    return {
      'comicPages': comicPages,
      'comicName': comicName,
    };
  }

  factory ComicModel.fromJson(Map<String, dynamic> json) {
    return ComicModel(
      comicPages: List<String>.from(json['comicPages']),
      comicName: json['comicName'],
    );
  }
}