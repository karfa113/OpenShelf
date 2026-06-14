import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import '../utils/routes.dart';
import '../widgets/book_tile.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedGenre = 0; // 0 = all

  static const _quotes = <String>[
    'A reader lives a thousand lives before he dies.',
    'Books are a uniquely portable magic.',
    'So many books, so little time.',
    'There is no friend as loyal as a book.',
    'Reading is essential for those who seek to rise above the ordinary.',
    'Books wash away from the soul the dust of everyday life.',
    'That\'s the thing about books — they let you travel without moving your feet.',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greet = _greeting(now.hour);
    final quote = _quotes[now.day % _quotes.length];

    return Consumer<LibraryProvider>(
      builder: (context, lib, _) {
        if (!lib.loaded) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }

        final topGenres = _topGenres(lib);
        final allGenres = ['all', ...topGenres.map((e) => e.key)];
        final selectedGenreLabel =
            _selectedGenre == 0 ? null : allGenres[_selectedGenre];

        // Show ALL books (library + tbr) filtered by genre
        final books = selectedGenreLabel == null
            ? lib.all
            : lib.all
                .where((b) => b.genres.contains(selectedGenreLabel))
                .toList();

        return SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Top bar ───────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(greet,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            )),
                      ),
                      Text(DateFormat('MMM d').format(now),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          )),
                    ],
                  ),
                ),
              ),

              // ── Headline ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                      children: [
                        const TextSpan(text: 'your\n'),
                        TextSpan(
                          text: lib.totalBooks > 0
                              ? '${lib.totalBooks} books'
                              : 'library',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Genre filter pills ────────────────────────────────
              if (topGenres.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 46,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: allGenres.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final sel = _selectedGenre == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGenre = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppColors.accent
                                    : AppColors.borderMid,
                              ),
                            ),
                            child: Text(
                              '#${allGenres[i]}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: sel ? AppColors.bg : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // ── Stats row ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _StatChip(
                          value: lib.totalBooks.toString(), label: 'books'),
                      const SizedBox(width: 8),
                      _StatChip(value: lib.totalRead.toString(), label: 'read'),
                      const SizedBox(width: 8),
                      _StatChip(value: lib.tbrCount.toString(), label: 'tbr'),
                    ],
                  ),
                ),
              ),

              // ── Divider ───────────────────────────────────────────
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                    child: Divider(color: AppColors.border, height: 1)),
              ),

              // ── Book list ─────────────────────────────────────────
              if (books.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  sliver: SliverList.separated(
                    itemCount: books.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, i) => BookTile(
                      book: books[i],
                      onTap: () => Navigator.of(context).push(
                        smoothRoute(BookDetailScreen(bookId: books[i].id)),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 110),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"$quote"',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          lib.totalBooks == 0
                              ? 'Add your first book in the Library tab.'
                              : 'No books in this genre.',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _greeting(int h) {
    if (h < 5) return 'Late night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  List<MapEntry<String, int>> _topGenres(LibraryProvider lib) {
    final counts = <String, int>{};
    for (final b in lib.all) {
      for (final g in b.genres) {
        if (g.trim().isEmpty) continue;
        counts[g] = (counts[g] ?? 0) + 1;
      }
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(5).toList();
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextSpan(
              text: '  $label',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
