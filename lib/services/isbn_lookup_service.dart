import 'dart:convert';

import 'package:http/http.dart' as http;

class IsbnLookupResult {
  final String title;
  final String author;
  final String publisher;
  final int pages;
  final List<String> genres;

  IsbnLookupResult({
    required this.title,
    required this.author,
    required this.publisher,
    required this.pages,
    required this.genres,
  });
}

class IsbnLookupException implements Exception {
  final String message;
  IsbnLookupException(this.message);
  @override
  String toString() => message;
}

class IsbnLookupService {
  static const _userAgent = 'OpenShelf/1.0 (Flutter)';

  static String normalize(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();

  static bool isValid(String raw) {
    final n = normalize(raw);
    return n.length == 10 || n.length == 13;
  }

  Future<IsbnLookupResult> lookup(String rawIsbn, {String? googleApiKey}) async {
    final isbn = normalize(rawIsbn);
    if (!isValid(isbn)) {
      throw IsbnLookupException('Enter a valid 10 or 13 digit ISBN.');
    }

    Object? olError;
    bool olEmpty = false;
    try {
      final ol = await _fetchOpenLibrary(isbn);
      if (ol != null) return ol;
      olEmpty = true;
    } catch (e) {
      olError = e;
    }

    Object? googleError;
    bool googleEmpty = false;
    try {
      final google = await _fetchGoogle(isbn, googleApiKey);
      if (google != null) return google;
      googleEmpty = true;
    } catch (e) {
      googleError = e;
    }

    // Final fallback: scrape isbnsearch.org (good for Indian/regional books)
    try {
      final scraped = await _fetchIsbnSearch(isbn);
      if (scraped != null) return scraped;
    } catch (_) {}

    if (olEmpty && googleEmpty) {
      throw IsbnLookupException('No book found for ISBN $isbn.');
    }
    final reason = olError?.toString() ?? googleError?.toString() ?? 'unknown';
    throw IsbnLookupException('Lookup failed: $reason');
  }

  Future<IsbnLookupResult?> _fetchGoogle(String isbn, String? apiKey) async {
    final params = {'q': 'isbn:$isbn'};
    if (apiKey != null && apiKey.isNotEmpty) params['key'] = apiKey;
    final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', params);
    final res = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw IsbnLookupException(
          'Google Books HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final totalItems = (body['totalItems'] as num?)?.toInt() ?? 0;
    final items = body['items'] as List<dynamic>?;
    if (totalItems == 0 || items == null || items.isEmpty) return null;

    final info = (items.first as Map<String, dynamic>)['volumeInfo']
        as Map<String, dynamic>?;
    if (info == null) return null;

    final authors = (info['authors'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final categories = (info['categories'] as List<dynamic>? ?? [])
        .expand((e) => e.toString().split('/'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    return IsbnLookupResult(
      title: (info['title'] as String? ?? '').trim(),
      author: authors.join(', '),
      publisher: (info['publisher'] as String? ?? '').trim(),
      pages: (info['pageCount'] as num?)?.toInt() ?? 0,
      genres: categories,
    );
  }

  Future<IsbnLookupResult?> _fetchIsbnSearch(String isbn) async {
    final uri = Uri.https('isbnsearch.org', '/isbn/$isbn');
    final res = await http
        .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;

    String _extract(String html, String label) {
      final pattern = RegExp('<strong>$label:</strong>\\s*([^<]+)');
      return pattern.firstMatch(html)?.group(1)?.trim() ?? '';
    }

    final title = RegExp(r'<h1>(.*?)</h1>').firstMatch(res.body)?.group(1)?.trim() ?? '';
    if (title.isEmpty) return null;

    return IsbnLookupResult(
      title: title,
      author: _extract(res.body, 'Author'),
      publisher: _extract(res.body, 'Publisher'),
      pages: 0,
      genres: [],
    );
  }

  Future<IsbnLookupResult?> _fetchOpenLibrary(String isbn) async {
    final uri = Uri.https(
      'openlibrary.org',
      '/api/books',
      {'format': 'json', 'jscmd': 'data', 'bibkeys': 'ISBN:$isbn'},
    );
    final res = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw IsbnLookupException(
          'OpenLibrary HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final entry = body['ISBN:$isbn'] as Map<String, dynamic>?;
    if (entry == null) return null;

    final authors = (entry['authors'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final publishers = (entry['publishers'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final subjects = (entry['subjects'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .take(5)
        .toList();

    return IsbnLookupResult(
      title: (entry['title'] as String? ?? '').trim(),
      author: authors.join(', '),
      publisher: publishers.isNotEmpty ? publishers.first : '',
      pages: (entry['number_of_pages'] as num?)?.toInt() ?? 0,
      genres: subjects,
    );
  }
}
