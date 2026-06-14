import '../models/book.dart';

abstract class StorageService {
  Future<List<Book>> loadBooks();
  Future<void> saveBooks(List<Book> books);
  Future<String> exportJsonString();
  Future<void> importFromJsonString(String jsonString, {bool replace = true});
}
