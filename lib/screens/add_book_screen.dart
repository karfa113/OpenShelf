import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/library_provider.dart';
import '../services/isbn_lookup_service.dart';
import '../theme/app_colors.dart';
import '../widgets/genre_chip_input.dart';

class AddBookScreen extends StatefulWidget {
  final bool isTBR;
  final Book? editing;
  const AddBookScreen({super.key, this.isTBR = false, this.editing});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _isbn;
  late final TextEditingController _name;
  late final TextEditingController _author;
  late final TextEditingController _publisher;
  late final TextEditingController _pages;
  late final TextEditingController _notes;
  late List<String> _genres;
  late bool _alreadyRead;
  DateTime? _dateRead;
  bool _isbnLoading = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _isbn = TextEditingController();
    _name = TextEditingController(text: e?.name ?? '');
    _author = TextEditingController(text: e?.author ?? '');
    _publisher = TextEditingController(text: e?.publisher ?? '');
    _pages = TextEditingController(
        text: (e?.pages ?? 0) > 0 ? '${e!.pages}' : '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _genres = [...?e?.genres];
    _alreadyRead = e?.alreadyRead ?? false;
    _dateRead = e?.dateRead;
  }

  @override
  void dispose() {
    _isbn.dispose();
    _name.dispose();
    _author.dispose();
    _publisher.dispose();
    _pages.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _fetchByIsbn() async {
    final raw = _isbn.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (raw.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter an ISBN first.')),
      );
      return;
    }
    if (!IsbnLookupService.isValid(raw)) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('ISBN must be 10 or 13 digits.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isbnLoading = true);
    try {
      final result = await IsbnLookupService().lookup(raw);
      if (!mounted) return;
      setState(() {
        if (result.title.isNotEmpty) _name.text = result.title;
        if (result.author.isNotEmpty) _author.text = result.author;
        if (result.publisher.isNotEmpty) _publisher.text = result.publisher;
        if (result.pages > 0) _pages.text = '${result.pages}';
        if (result.genres.isNotEmpty) {
          final merged = {..._genres, ...result.genres}.toList();
          _genres = merged;
        }
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Book details loaded.')),
      );
    } on IsbnLookupException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Lookup failed. Check your connection.'),
            backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isbnLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    final pages = int.tryParse(_pages.text.trim()) ?? 0;
    final lib = context.read<LibraryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final isDuplicate = lib.all.any((b) =>
        b.name.toLowerCase() == name.toLowerCase() &&
        b.id != widget.editing?.id);

    if (isDuplicate) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('A book with the name "$name" already exists.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      if (_isEditing) {
        await lib.updateBook(widget.editing!.copyWith(
          name: name,
          author: _author.text.trim(),
          publisher: _publisher.text.trim(),
          pages: pages,
          genres: _genres,
          alreadyRead: _alreadyRead,
          dateRead: _alreadyRead ? (_dateRead ?? DateTime.now()) : null,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ));
      } else {
        await lib.addBook(Book(
          name: name,
          author: _author.text.trim(),
          publisher: _publisher.text.trim(),
          pages: pages,
          genres: _genres,
          alreadyRead: _alreadyRead,
          dateRead: _alreadyRead ? (_dateRead ?? DateTime.now()) : null,
          isTBR: widget.isTBR,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.read<LibraryProvider>();
    final title = _isEditing
        ? 'Edit book'
        : (widget.isTBR ? 'Add to TBR' : 'Add book');
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(title,
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 20)),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            if (!_isEditing) ...[
              _isbnLookupRow(),
              const SizedBox(height: 8),
            ],
            _field(_name, 'Title',
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null),
            _autocompleteField(_author, 'Author', lib.allAuthors),
            _autocompleteField(_publisher, 'Publisher', lib.allPublishers),
            _field(_pages, 'Pages',
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 20),
            Text('Genres',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            GenreChipInput(
              genres: _genres,
              suggestions: lib.allGenres,
              onChanged: (g) => setState(() => _genres = g),
            ),
            if (!widget.isTBR) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Already read',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 15)),
                  ),
                  Switch.adaptive(
                    value: _alreadyRead,
                    activeThumbColor: Colors.black,
                    activeTrackColor: AppColors.accent,
                    onChanged: (v) => setState(() {
                      _alreadyRead = v;
                      if (v && _dateRead == null) _dateRead = DateTime.now();
                    }),
                  ),
                ],
              ),
              if (_alreadyRead)
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateRead ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                              primary: AppColors.accent,
                              surface: AppColors.surface,
                              onSurface: AppColors.textPrimary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _dateRead = picked);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _dateRead == null
                              ? 'Pick date read'
                              : DateFormat.yMMMMd().format(_dateRead!),
                          style: GoogleFonts.inter(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            _field(_notes, 'Notes (optional)', maxLines: 3),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.borderMid),
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_isEditing ? 'Save' : 'Add',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _isbnLookupRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _isbn,
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9Xx\-\s]')),
              ],
              enabled: !_isbnLoading,
              onFieldSubmitted: (_) => _fetchByIsbn(),
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'ISBN (optional)',
                hintText: '10 or 13 digits',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.textTertiary, fontSize: 13),
                filled: true,
                fillColor: AppColors.bg,
                prefixIcon: const Icon(Icons.qr_code_2_rounded,
                    color: AppColors.textTertiary, size: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderMid),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.5),
                ),
                labelStyle: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isbnLoading ? null : _fetchByIsbn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                disabledBackgroundColor:
                    AppColors.accent.withValues(alpha: 0.5),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isbnLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text('Fetch',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    TextInputType? type,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: type,
        textCapitalization: textCapitalization,
        inputFormatters: formatters,
        validator: validator,
        style: GoogleFonts.inter(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.bg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderMid),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          labelStyle: GoogleFonts.spaceGrotesk(
              color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _autocompleteField(
    TextEditingController ctrl,
    String label,
    List<String> suggestions,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RawAutocomplete<String>(
        textEditingController: ctrl,
        focusNode: FocusNode(),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return suggestions.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            onFieldSubmitted: (v) => onFieldSubmitted(),
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: AppColors.bg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderMid),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              labelStyle: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: AppColors.surface,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: MediaQuery.of(context).size.width - 40,
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return ListTile(
                      title: Text(option,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary, fontSize: 14)),
                      onTap: () => onSelected(option),
                      hoverColor: AppColors.accent.withValues(alpha: 0.1),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
