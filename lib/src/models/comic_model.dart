// lib/src/models/comic_model.dart

/// A model class representing a comic book with pages and name.
///
/// This class provides functionality to convert between JSON and Dart objects,
/// making it suitable for data serialization and deserialization.
class ComicModel {
  /// List of comic page URLs or references.
  ///
  /// Each string in this list typically represents a path or URL to a comic page image.
  final List<String> comicPages;

  /// The name of the comic book.
  ///
  /// This string represents the title or name identifier for the comic.
  final String comicName;

  /// Creates a new [ComicModel] instance.
  ///
  /// Requires [comicPages] as a list of strings representing the comic pages
  /// and [comicName] as a string representing the name of the comic.
  ///
  /// Example:
  /// ```dart
  /// final comic = ComicModel(
  ///   comicPages: ['page1.jpg', 'page2.jpg', 'page3.jpg'],
  ///   comicName: 'My Awesome Comic',
  /// );
  /// ```
  ComicModel({
    required this.comicPages,
    required this.comicName,
  });

  /// Converts the [ComicModel] instance to a JSON map.
  ///
  /// Returns a [Map] with keys 'comicPages' and 'comicName' mapping to
  /// their respective values from this instance.
  ///
  /// This method is useful when storing the model data or sending it
  /// over a network.
  Map<String, dynamic> toJson() {
    return {
      'comicPages': comicPages,
      'comicName': comicName,
    };
  }

  /// Creates a [ComicModel] instance from a JSON map.
  ///
  /// The [json] parameter must contain the keys 'comicPages' and 'comicName'.
  /// The 'comicPages' value must be a list that can be converted to a list of strings.
  ///
  /// Throws an error if the required keys are missing or have incompatible types.
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'comicPages': ['page1.jpg', 'page2.jpg'],
  ///   'comicName': 'My Comic'
  /// };
  /// final comic = ComicModel.fromJson(json);
  /// ```
  factory ComicModel.fromJson(Map<String, dynamic> json) {
    return ComicModel(
      comicPages: List<String>.from(json['comicPages']),
      comicName: json['comicName'],
    );
  }
}
