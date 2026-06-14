import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book.dart';
import 'storage_service.dart';

/// Cloud-only StorageService backed by Firestore.
///
/// Books live at: users/{uid}/books/{bookId}.
/// CRUD is per-doc so adding/editing one book doesn't rewrite the whole
/// library. The snapshot stream is the single source of truth — the
/// LibraryProvider does not mutate its in-memory list directly.
class FirestoreStorageService implements StorageService {
  static const _schemaVersion = 1;

  final String uid;
  FirestoreStorageService(this.uid);

  CollectionReference<Map<String, dynamic>> get _books => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('books');

  @override
  Future<List<Book>> loadBooks() async {
    final snap = await _books.get();
    return snap.docs.map((d) => Book.fromJson(d.data())).toList();
  }

  @override
  Stream<List<Book>> watchBooks() {
    return _books.snapshots().map(
          (snap) => snap.docs.map((d) => Book.fromJson(d.data())).toList(),
        );
  }

  @override
  Future<void> saveBook(Book book) =>
      _books.doc(book.id).set(book.toJson());

  @override
  Future<void> removeBook(String id) => _books.doc(id).delete();

  /// Bulk replace used by import. Upserts everything in [books] and deletes
  /// any cloud docs not present in the list.
  @override
  Future<void> saveBooks(List<Book> books) async {
    final cloudIds = (await _books.get()).docs.map((d) => d.id).toSet();
    final localIds = books.map((b) => b.id).toSet();

    final batch = FirebaseFirestore.instance.batch();
    for (final b in books) {
      batch.set(_books.doc(b.id), b.toJson());
    }
    for (final id in cloudIds.difference(localIds)) {
      batch.delete(_books.doc(id));
    }
    await batch.commit();
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
