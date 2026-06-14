import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/book.dart';
import 'storage_service.dart';

class LocalStorageService implements StorageService {
  static const _fileName = 'library.json';
  static const _schemaVersion = 1;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<List<Book>> loadBooks() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['books'] as List<dynamic>? ?? [])
          .map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveBooks(List<Book> books) async {
    final file = await _file();
    final payload = {
      'version': _schemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'books': books.map((b) => b.toJson()).toList(),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
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
  Future<void> importFromJsonString(String jsonString, {bool replace = true}) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final incoming = (decoded['books'] as List<dynamic>? ?? [])
        .map((e) => Book.fromJson(e as Map<String, dynamic>))
        .toList();
    if (replace) {
      await saveBooks(incoming);
    } else {
      final existing = await loadBooks();
      final existingIds = existing.map((b) => b.id).toSet();
      final merged = [
        ...existing,
        ...incoming.where((b) => !existingIds.contains(b.id)),
      ];
      await saveBooks(merged);
    }
  }
}
