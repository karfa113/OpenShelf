import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../theme/app_colors.dart';

/// Editorial book list row — genre tag · large title · author · cover initial.
/// Matches the dark editorial style: big serif title, muted metadata, no cards.
class BookTile extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final Widget? trailing;

  const BookTile({super.key, required this.book, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final initial = book.name.isNotEmpty ? book.name[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.genres.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Wrap(
                        spacing: 8,
                        children: book.genres.map((g) {
                          return Text(
                            '#${g.toLowerCase()}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  Text(
                    book.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        book.author.isEmpty ? 'Unknown' : book.author,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (book.alreadyRead) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.accent),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'read',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Book cover placeholder
            if (trailing == null)
              _Cover(initial: initial, book: book)
            else
              trailing!,
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String initial;
  final Book book;
  const _Cover({required this.initial, required this.book});

  @override
  Widget build(BuildContext context) {
    final color = _colorForBook(book);
    return Container(
      width: 58,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  static Color _colorForBook(Book book) {
    const palette = [
      AppColors.accent,
      AppColors.secondary,
      AppColors.tertiary,
      Color(0xFFFC8181), // soft red
      Color(0xFFA78BFA), // soft purple
    ];
    final seed = book.genres.isNotEmpty ? book.genres.first : book.author;
    if (seed.isEmpty) return AppColors.accent;
    final hash = seed.codeUnits.fold<int>(0, (a, b) => (a + b) & 0xFFFFFFFF);
    return palette[hash % palette.length];
  }
}

// Kept for screens that still use _Pill internally — not used in BookTile anymore
class BookTilePill extends StatelessWidget {
  final String label;
  final Color color;
  const BookTilePill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
