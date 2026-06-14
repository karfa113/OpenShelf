import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/book_tile.dart';
import '../widgets/filter_sheet.dart';
import '../utils/routes.dart';
import 'add_book_screen.dart';
import 'book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _filter = const LibraryFilter();
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final lib = context.read<LibraryProvider>();
    final result = await showModalBottomSheet<LibraryFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterSheet(
        initial: _filter,
        authors: lib.distinctAuthors(false),
        publishers: lib.distinctPublishers(false),
        genres: lib.distinctGenres(false),
      ),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<LibraryProvider>(
        builder: (context, lib, _) {
          if (!lib.loaded) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accent));
          }
          final filtered = lib.filter(tbrOnly: false, f: _filter);
          return Stack(
            children: [
              CustomScrollView(physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Library',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    )),
                              ),
                              IconButton(
                                icon: Icon(
                                  _showSearch
                                      ? Icons.search_off
                                      : Icons.search,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(
                                    () => _showSearch = !_showSearch),
                              ),
                              IconButton(
                                icon: Icon(Icons.tune,
                                    color: _filter.isEmpty
                                        ? AppColors.textSecondary
                                        : AppColors.accent),
                                onPressed: _openFilters,
                              ),
                              ],
                              ),
                          if (_showSearch) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary),
                              onChanged: (v) => setState(
                                  () => _filter = _filter.copyWith(query: v)),
                              decoration: InputDecoration(
                                hintText: 'Search name, author…',
                                prefixIcon: const Icon(Icons.search,
                                    color: AppColors.textTertiary, size: 20),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                              ),
                            ),
                          ],
                          if (!_filter.isEmpty) ...[
                            const SizedBox(height: 8),
                            _FilterStrip(
                              filter: _filter,
                              onClear: () => setState(() {
                                _filter = const LibraryFilter();
                                _searchCtrl.clear();
                              }),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            '${filtered.length} book${filtered.length == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.border, height: 1),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          lib.library.isEmpty
                              ? 'Your library is empty'
                              : 'No matches',
                          style: GoogleFonts.inter(
                              color: AppColors.textTertiary, fontSize: 15),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (context, i) {
                          final b = filtered[i];
                          return BookTile(
                            book: b,
                            onTap: () => Navigator.of(context).push(
                                smoothRoute(BookDetailScreen(bookId: b.id))),
                          );
                        },
                      ),
                    ),
                ],
              ),
              Positioned(
                bottom: 110,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.extended(
                    onPressed: () => Navigator.of(context).push(smoothRoute(const AddBookScreen(isTBR: false))),
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    icon: const Icon(Icons.add),
                    label: Text('Add book',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  final LibraryFilter filter;
  final VoidCallback onClear;
  const _FilterStrip({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filter.thisMonthOnly) chips.add('This month');
    if (filter.readStatus == true) chips.add('Read');
    if (filter.readStatus == false) chips.add('Unread');
    if (filter.author != null) chips.add('by ${filter.author}');
    if (filter.publisher != null) chips.add(filter.publisher!);
    chips.addAll(filter.genres);
    if (filter.query.isNotEmpty) chips.add('"${filter.query}"');

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: chips
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderMid),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(c,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ))
                .toList(),
          ),
        ),
        TextButton(
          onPressed: onClear,
          child: Text('Clear',
              style: GoogleFonts.inter(color: AppColors.accent, fontSize: 13)),
        ),
      ],
    );
  }
}


