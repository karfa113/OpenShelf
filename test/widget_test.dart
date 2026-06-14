import 'package:flutter_test/flutter_test.dart';
import 'package:library_manual/models/book.dart';

void main() {
  test('Book serializes to JSON and back without data loss', () {
    final original = Book(
      name: 'Dune',
      author: 'Frank Herbert',
      publisher: 'Chilton Books',
      pages: 412,
      genres: ['Sci-Fi', 'Classic'],
      alreadyRead: true,
      dateRead: DateTime(2026, 1, 1),
    );
    final round = Book.fromJson(original.toJson());
    expect(round.id, original.id);
    expect(round.name, 'Dune');
    expect(round.author, 'Frank Herbert');
    expect(round.publisher, 'Chilton Books');
    expect(round.pages, 412);
    expect(round.genres, ['Sci-Fi', 'Classic']);
    expect(round.alreadyRead, true);
    expect(round.dateRead, DateTime(2026, 1, 1));
    expect(round.isTBR, false);
  });

  test('Book.copyWith updates only specified fields', () {
    final b = Book(
      name: 'A',
      author: 'X',
      publisher: 'Y',
      pages: 100,
      genres: const ['Fiction'],
      alreadyRead: false,
    );
    final c = b.copyWith(alreadyRead: true, dateRead: DateTime(2026, 6, 14));
    expect(c.id, b.id);
    expect(c.name, 'A');
    expect(c.alreadyRead, true);
    expect(c.dateRead, DateTime(2026, 6, 14));
  });
}
