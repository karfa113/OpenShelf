import '../models/book.dart';

abstract class StorageService {
  Future<List<Book>> loadBooks();

  /// Emits the current book list, then re-emits whenever the underlying
  /// store changes. For Firestore this stays open and pushes updates from
  /// other devices; for local storage it re-emits after every mutation.
  Stream<List<Book>> watchBooks();

  /// Upsert a single book (create or replace).
  Future<void> saveBook(Book book);

  /// Delete a single book by id.
  Future<void> removeBook(String id);

  /// Bulk replace (used by import).
  Future<void> saveBooks(List<Book> books);

  Future<String> exportJsonString();
  Future<void> importFromJsonString(String jsonString, {bool replace = true});
}
