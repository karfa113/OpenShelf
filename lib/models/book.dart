import 'package:uuid/uuid.dart';

class Book {
  final String id;
  String name;
  List<String> genres;
  String author;
  String publisher;
  int pages;
  bool alreadyRead;
  DateTime? dateRead;
  DateTime dateAdded;
  bool isTBR;
  String? notes;
  String? imagePath;

  Book({
    String? id,
    required this.name,
    required this.genres,
    required this.author,
    required this.publisher,
    required this.pages,
    required this.alreadyRead,
    this.dateRead,
    DateTime? dateAdded,
    this.isTBR = false,
    this.notes,
    this.imagePath,
  })  : id = id ?? const Uuid().v4(),
        dateAdded = dateAdded ?? DateTime.now();

  Book copyWith({
    String? name,
    List<String>? genres,
    String? author,
    String? publisher,
    int? pages,
    bool? alreadyRead,
    DateTime? dateRead,
    bool? isTBR,
    String? notes,
    String? imagePath,
  }) {
    return Book(
      id: id,
      name: name ?? this.name,
      genres: genres ?? this.genres,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      pages: pages ?? this.pages,
      alreadyRead: alreadyRead ?? this.alreadyRead,
      dateRead: dateRead ?? this.dateRead,
      dateAdded: dateAdded,
      isTBR: isTBR ?? this.isTBR,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'genres': genres,
        'author': author,
        'publisher': publisher,
        'pages': pages,
        'alreadyRead': alreadyRead,
        'dateRead': dateRead?.toIso8601String(),
        'dateAdded': dateAdded.toIso8601String(),
        'isTBR': isTBR,
        'notes': notes,
        'imagePath': imagePath,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        genres: (json['genres'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        author: json['author'] as String? ?? '',
        publisher: json['publisher'] as String? ?? '',
        pages: (json['pages'] as num?)?.toInt() ?? 0,
        alreadyRead: json['alreadyRead'] as bool? ?? false,
        dateRead: json['dateRead'] == null
            ? null
            : DateTime.tryParse(json['dateRead'] as String),
        dateAdded: json['dateAdded'] == null
            ? DateTime.now()
            : DateTime.tryParse(json['dateAdded'] as String) ?? DateTime.now(),
        isTBR: json['isTBR'] as bool? ?? false,
        notes: json['notes'] as String?,
        imagePath: json['imagePath'] as String?,
      );
}
