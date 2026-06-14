import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import '../utils/routes.dart';
import 'add_book_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, lib, _) {
        final book =
            lib.all.where((b) => b.id == bookId).cast<Book?>().firstOrNull;
        if (book == null) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(),
            body: const Center(child: Text('Book not found')),
          );
        }

        final color = _colorForBook(book);

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            iconTheme: const IconThemeData(color: AppColors.textSecondary),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).push(smoothRoute(AddBookScreen(isTBR: book.isTBR, editing: book))),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.textSecondary),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text('Delete book?',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textPrimary)),
                      content: Text('"${book.name}" will be removed.',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel',
                                style:
                                    GoogleFonts.inter(color: AppColors.textSecondary))),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete',
                                style: GoogleFonts.inter(color: Colors.redAccent))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await lib.deleteBook(book.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover + title block
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      child: (book.imagePath != null &&
                              File(book.imagePath!).existsSync())
                          ? Image.file(File(book.imagePath!), fit: BoxFit.cover)
                          : Text(
                              book.name.isNotEmpty
                                  ? book.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (book.genres.isNotEmpty)
                            Text(
                              '#${book.genres.first.toLowerCase()}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            book.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book.author.isEmpty
                                ? 'Unknown author'
                                : book.author,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                // Metadata
                _kv('Publisher',
                    book.publisher.isEmpty ? '—' : book.publisher),
                _kv('Pages', book.pages == 0 ? '—' : '${book.pages}'),
                _kv('Added', DateFormat.yMMMMd().format(book.dateAdded)),
                if (!book.isTBR)
                  _kv(
                    'Read',
                    book.alreadyRead
                        ? (book.dateRead == null
                            ? 'Yes'
                            : DateFormat.yMMMMd().format(book.dateRead!))
                        : 'No',
                  ),

                // Extra genres
                if (book.genres.length > 1) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: book.genres
                        .map((g) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: AppColors.borderMid),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('#${g.toLowerCase()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  )),
                            ))
                        .toList(),
                  ),
                ],

                // Notes
                if (book.notes != null && book.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  Text('Notes',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 8),
                  Text(book.notes!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      )),
                ],

                const SizedBox(height: 32),

                // Action button
                if (book.isTBR)
                  _ActionBtn(
                    label: 'Move to library',
                    icon: Icons.library_add_check_outlined,
                    onPressed: () async {
                      await lib.moveTbrToLibrary(book.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  )
                else
                  _ActionBtn(
                    label: book.alreadyRead ? 'Mark as unread' : 'Mark as read',
                    icon: book.alreadyRead
                        ? Icons.undo
                        : Icons.check_circle_outline,
                    onPressed: () => lib.setRead(book.id, !book.alreadyRead),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(k,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textTertiary)),
          ),
          Expanded(
            child: Text(v,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  static Color _colorForBook(Book book) {
    const palette = [
      AppColors.accent,
      AppColors.secondary,
      AppColors.tertiary,
      Color(0xFFFC8181),
      Color(0xFFA78BFA),
    ];
    final seed = book.genres.isNotEmpty ? book.genres.first : book.author;
    if (seed.isEmpty) return AppColors.accent;
    final hash =
        seed.codeUnits.fold<int>(0, (a, b) => (a + b) & 0xFFFFFFFF);
    return palette[hash % palette.length];
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _ActionBtn(
      {required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

