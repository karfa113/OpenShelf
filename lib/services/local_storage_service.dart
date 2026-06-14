import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import 'storage_service.dart';

class LocalStorageService implements StorageService {
  static const _fileName = 'library.json';
  static const _schemaVersion = 1;

  final _controller = StreamController<List<Book>>.broadcast();
  List<Book>? _cache;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Book>> _readFromDisk() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return (decoded['books'] as List<dynamic>? ?? [])
          .map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeToDisk(List<Book> books) async {
    final file = await _file();
    final payload = {
      'version': _schemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'books': books.map((b) => b.toJson()).toList(),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  Future<List<Book>> _ensureCache() async {
    _cache ??= await _readFromDisk();
    return _cache!;
  }

  void _emit() {
    if (_cache != null) _controller.add(List.of(_cache!));
  }

  @override
  Future<List<Book>> loadBooks() async => List.of(await _ensureCache());

  @override
  Stream<List<Book>> watchBooks() async* {
    final initial = await _ensureCache();
    yield List.of(initial);
    yield* _controller.stream;
  }

  @override
  Future<void> saveBook(Book book) async {
    final cache = await _ensureCache();
    final idx = cache.indexWhere((b) => b.id == book.id);
    if (idx == -1) {
      cache.add(book);
    } else {
      cache[idx] = book;
    }
    await _writeToDisk(cache);
    _emit();
  }

  @override
  Future<void> removeBook(String id) async {
    final cache = await _ensureCache();
    cache.removeWhere((b) => b.id == id);
    await _writeToDisk(cache);
    _emit();
  }

  @override
  Future<void> saveBooks(List<Book> books) async {
    _cache = List.of(books);
    await _writeToDisk(_cache!);
    _emit();
  }

  @override
  Future<String> exportJsonString() async {
    final books = await loadBooks();
    final payload = {
      'version': _schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'books': books.map((b) => b.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  @override
  Future<void> importFromJsonString(String jsonString,
      {bool replace = true}) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final incoming = (decoded['books'] as List<dynamic>? ?? [])
        .map((e) => Book.fromJson(e as Map<String, dynamic>))
        .toList();
    if (replace) {
      await saveBooks(incoming);
    } else {
      final existing = await _ensureCache();
      final existingIds = existing.map((b) => b.id).toSet();
      final merged = [
        ...existing,
        ...incoming.where((b) => !existingIds.contains(b.id)),
      ];
      await saveBooks(merged);
    }
  }
}
