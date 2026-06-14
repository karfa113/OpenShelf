import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/storage_service.dart';

class LibraryFilter {
  final String query;
  final String? author;
  final String? publisher;
  final Set<String> genres;
  final bool? readStatus; // null = all; true = read; false = unread
  final bool thisMonthOnly;
  final SortKey sort;

  const LibraryFilter({
    this.query = '',
    this.author,
    this.publisher,
    this.genres = const {},
    this.readStatus,
    this.thisMonthOnly = false,
    this.sort = SortKey.dateAddedDesc,
  });

  LibraryFilter copyWith({
    String? query,
    Object? author = _unset,
    Object? publisher = _unset,
    Set<String>? genres,
    Object? readStatus = _unset,
    bool? thisMonthOnly,
    SortKey? sort,
  }) {
    return LibraryFilter(
      query: query ?? this.query,
      author: identical(author, _unset) ? this.author : author as String?,
      publisher:
          identical(publisher, _unset) ? this.publisher : publisher as String?,
      genres: genres ?? this.genres,
      readStatus:
          identical(readStatus, _unset) ? this.readStatus : readStatus as bool?,
      thisMonthOnly: thisMonthOnly ?? this.thisMonthOnly,
      sort: sort ?? this.sort,
    );
  }

  bool get isEmpty =>
      query.isEmpty &&
      author == null &&
      publisher == null &&
      genres.isEmpty &&
      readStatus == null &&
      !thisMonthOnly;

  static const _unset = Object();
}

enum SortKey { dateAddedDesc, dateAddedAsc, nameAsc, pagesDesc }

class LibraryProvider extends ChangeNotifier {
  final StorageService _storage;
  final List<Book> _books = [];
  bool _loaded = false;
  bool get loaded => _loaded;

  LibraryProvider(this._storage);

  Future<void> load() async {
    final list = await _storage.loadBooks();
    _books
      ..clear()
      ..addAll(list);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _storage.saveBooks(_books);

  List<Book> get all => List.unmodifiable(_books);

  List<Book> get library =>
      _books.where((b) => !b.isTBR).toList()
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  List<Book> get tbr =>
      _books.where((b) => b.isTBR).toList()
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  // CRUD ---------------------------------------------------------------------

  Future<void> addBook(Book book) async {
    _books.add(book);
    notifyListeners();
    await _persist();
  }

  Future<void> updateBook(Book book) async {
    final idx = _books.indexWhere((b) => b.id == book.id);
    if (idx == -1) return;
    _books[idx] = book;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteBook(String id) async {
    _books.removeWhere((b) => b.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> moveTbrToLibrary(String id) async {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    _books[idx] = _books[idx].copyWith(isTBR: false);
    notifyListeners();
    await _persist();
  }

  Future<void> setRead(String id, bool read, {DateTime? date}) async {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    _books[idx] = _books[idx].copyWith(
      alreadyRead: read,
      dateRead: read ? (date ?? DateTime.now()) : null,
    );
    notifyListeners();
    await _persist();
  }

  // Stats --------------------------------------------------------------------

  int get totalBooks => library.length;
  int get totalRead => library.where((b) => b.alreadyRead).length;
  int get tbrCount => tbr.length;

  int get readThisMonth {
    final now = DateTime.now();
    return library.where((b) {
      final dr = b.dateRead;
      return b.alreadyRead &&
          dr != null &&
          dr.year == now.year &&
          dr.month == now.month;
    }).length;
  }

  int get pagesReadThisMonth {
    final now = DateTime.now();
    return library.fold<int>(0, (sum, b) {
      final dr = b.dateRead;
      if (b.alreadyRead && dr != null && dr.year == now.year && dr.month == now.month) {
        return sum + b.pages;
      }
      return sum;
    });
  }

  int get pagesReadAllTime => library
      .where((b) => b.alreadyRead)
      .fold<int>(0, (sum, b) => sum + b.pages);

  List<Book> get recentlyAdded {
    final list = [...library, ...tbr]
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return list.take(6).toList();
  }

  List<Book> get currentlyUnread =>
      library.where((b) => !b.alreadyRead).take(6).toList();

  // Distinct values for suggestions ----------------------------------------

  List<String> get allAuthors {
    final s = _books.map((b) => b.author.trim()).where((a) => a.isNotEmpty).toSet();
    return s.toList()..sort();
  }

  List<String> get allPublishers {
    final s = _books.map((b) => b.publisher.trim()).where((p) => p.isNotEmpty).toSet();
    return s.toList()..sort();
  }

  List<String> get allGenres {
    final s = <String>{};
    for (final b in _books) {
      for (final g in b.genres) {
        if (g.trim().isNotEmpty) s.add(g.trim());
      }
    }
    return s.toList()..sort();
  }

  // Distinct values for filter dropdowns -------------------------------------

  List<String> distinctAuthors(bool tbrOnly) {
    final source = tbrOnly ? tbr : library;
    final s = source.map((b) => b.author.trim()).where((a) => a.isNotEmpty).toSet();
    final list = s.toList()..sort();
    return list;
  }

  List<String> distinctPublishers(bool tbrOnly) {
    final source = tbrOnly ? tbr : library;
    final s = source.map((b) => b.publisher.trim()).where((p) => p.isNotEmpty).toSet();
    final list = s.toList()..sort();
    return list;
  }

  List<String> distinctGenres(bool tbrOnly) {
    final source = tbrOnly ? tbr : library;
    final s = <String>{};
    for (final b in source) {
      for (final g in b.genres) {
        if (g.trim().isNotEmpty) s.add(g.trim());
      }
    }
    final list = s.toList()..sort();
    return list;
  }

  // Filtering ----------------------------------------------------------------

  List<Book> filter({required bool tbrOnly, required LibraryFilter f}) {
    final source = tbrOnly ? tbr : library;
    final now = DateTime.now();
    Iterable<Book> result = source;

    if (f.query.isNotEmpty) {
      final q = f.query.toLowerCase();
      result = result.where((b) =>
          b.name.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.publisher.toLowerCase().contains(q) ||
          b.genres.any((g) => g.toLowerCase().contains(q)));
    }
    if (f.author != null && f.author!.isNotEmpty) {
      result = result.where((b) =>
          b.author.toLowerCase() == f.author!.toLowerCase());
    }
    if (f.publisher != null && f.publisher!.isNotEmpty) {
      result = result.where((b) =>
          b.publisher.toLowerCase() == f.publisher!.toLowerCase());
    }
    if (f.genres.isNotEmpty) {
      final lower = f.genres.map((g) => g.toLowerCase()).toSet();
      result = result.where(
          (b) => b.genres.any((g) => lower.contains(g.toLowerCase())));
    }
    if (!tbrOnly && f.readStatus != null) {
      result = result.where((b) => b.alreadyRead == f.readStatus);
    }
    if (!tbrOnly && f.thisMonthOnly) {
      result = result.where((b) {
        final dr = b.dateRead;
        return b.alreadyRead &&
            dr != null &&
            dr.year == now.year &&
            dr.month == now.month;
      });
    }

    final list = result.toList();
    switch (f.sort) {
      case SortKey.dateAddedDesc:
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortKey.dateAddedAsc:
        list.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
      case SortKey.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortKey.pagesDesc:
        list.sort((a, b) => b.pages.compareTo(a.pages));
        break;
    }
    return list;
  }

  // Import/Export passthrough -----------------------------------------------

  Future<String> exportJsonString() => _storage.exportJsonString();

  Future<void> importFromJsonString(String json, {bool replace = true}) async {
    await _storage.importFromJsonString(json, replace: replace);
    await load();
  }
}
