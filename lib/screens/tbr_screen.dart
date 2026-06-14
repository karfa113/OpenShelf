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

class TbrScreen extends StatefulWidget {
  const TbrScreen({super.key});

  @override
  State<TbrScreen> createState() => _TbrScreenState();
}

class _TbrScreenState extends State<TbrScreen> {
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
        authors: lib.distinctAuthors(true),
        publishers: lib.distinctPublishers(true),
        genres: lib.distinctGenres(true),
        showReadStatus: false,
        showThisMonth: false,
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
          final filtered = lib.filter(tbrOnly: true, f: _filter);
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
                                child: Text('To Be Read',
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
                                icon: const Icon(Icons.tune,
                                    color: AppColors.textSecondary),
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
                              decoration: const InputDecoration(
                                hintText: 'Search…',
                                prefixIcon: Icon(Icons.search,
                                    color: AppColors.textTertiary, size: 20),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            '${filtered.length} book${filtered.length == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textTertiary),
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
                          lib.tbr.isEmpty
                              ? 'TBR list is empty'
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
                            trailing: IconButton(
                              tooltip: 'Move to library',
                              icon: const Icon(
                                  Icons.library_add_check_outlined,
                                  color: AppColors.accent),
                              onPressed: () async {
                                await lib.moveTbrToLibrary(b.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('"${b.name}" moved to library')),
                                );
                              },
                            ),
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
                    onPressed: () => Navigator.of(context).push(smoothRoute(const AddBookScreen(isTBR: true))),
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    icon: const Icon(Icons.add),
                    label: Text('Add TBR',
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


