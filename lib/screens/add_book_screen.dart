import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/library_provider.dart';
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
  late final TextEditingController _name;
  late final TextEditingController _author;
  late final TextEditingController _publisher;
  late final TextEditingController _pages;
  late final TextEditingController _notes;
  late List<String> _genres;
  late bool _alreadyRead;
  DateTime? _dateRead;
  String? _imagePath;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _name = TextEditingController(text: e?.name ?? '');
    _author = TextEditingController(text: e?.author ?? '');
    _publisher = TextEditingController(text: e?.publisher ?? '');
    _pages = TextEditingController(
        text: (e?.pages ?? 0) > 0 ? '${e!.pages}' : '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _genres = [...?e?.genres];
    _alreadyRead = e?.alreadyRead ?? false;
    _dateRead = e?.dateRead;
    _imagePath = e?.imagePath;
  }

  @override
  void dispose() {
    _name.dispose();
    _author.dispose();
    _publisher.dispose();
    _pages.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _imagePath = result.files.single.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    final pages = int.tryParse(_pages.text.trim()) ?? 0;
    final lib = context.read<LibraryProvider>();

    // Duplicate check
    final isDuplicate = lib.all.any((b) =>
        b.name.toLowerCase() == name.toLowerCase() &&
        b.id != widget.editing?.id);

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A book with the name "$name" already exists.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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
        imagePath: _imagePath,
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
        imagePath: _imagePath,
      ));
    }
    if (mounted) Navigator.of(context).pop();
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
            // Image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagePath != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(_imagePath!), fit: BoxFit.cover),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _imagePath = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined,
                                color: AppColors.textTertiary, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Add Cover',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
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

