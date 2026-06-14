import 'package:flutter/material.dart';

import '../providers/library_provider.dart';
import '../theme/app_colors.dart';

class FilterSheet extends StatefulWidget {
  final LibraryFilter initial;
  final List<String> authors;
  final List<String> publishers;
  final List<String> genres;
  final bool showReadStatus;
  final bool showThisMonth;

  const FilterSheet({
    super.key,
    required this.initial,
    required this.authors,
    required this.publishers,
    required this.genres,
    this.showReadStatus = true,
    this.showThisMonth = true,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late LibraryFilter _f;

  @override
  void initState() {
    super.initState();
    _f = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Filters', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              if (widget.showReadStatus) ...[
                _label('Read status'),
                _segmented(
                  options: const [
                    MapEntry(null, 'All'),
                    MapEntry(true, 'Read'),
                    MapEntry(false, 'Unread'),
                  ],
                  selected: _f.readStatus,
                  onChanged: (v) => setState(() => _f = _f.copyWith(readStatus: v)),
                ),
                const SizedBox(height: 14),
              ],
              if (widget.showThisMonth) ...[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Read this month only'),
                  value: _f.thisMonthOnly,
                  activeThumbColor: Colors.black,
                  activeTrackColor: AppColors.accentStrong,
                  onChanged: (v) => setState(() => _f = _f.copyWith(thisMonthOnly: v)),
                ),
                const SizedBox(height: 4),
              ],
              _label('Author'),
              _dropdown(widget.authors, _f.author, (v) => setState(() => _f = _f.copyWith(author: v))),
              const SizedBox(height: 14),
              _label('Publisher'),
              _dropdown(widget.publishers, _f.publisher, (v) => setState(() => _f = _f.copyWith(publisher: v))),
              const SizedBox(height: 14),
              _label('Genres'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.genres
                    .map((g) {
                      final sel = _f.genres.contains(g);
                      return FilterChip(
                        label: Text(g),
                        selected: sel,
                        showCheckmark: false,
                        selectedColor: AppColors.accent.withValues(alpha: 0.3),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.55)),
                        onSelected: (v) {
                          setState(() {
                            final next = {..._f.genres};
                            if (v) {
                              next.add(g);
                            } else {
                              next.remove(g);
                            }
                            _f = _f.copyWith(genres: next);
                          });
                        },
                      );
                    })
                    .toList(),
              ),
              if (widget.genres.isEmpty)
                Text('No genres yet', style: t.textTheme.bodySmall),
              const SizedBox(height: 14),
              _label('Sort'),
              _segmented(
                options: const [
                  MapEntry(SortKey.dateAddedDesc, 'Newest'),
                  MapEntry(SortKey.dateAddedAsc, 'Oldest'),
                  MapEntry(SortKey.nameAsc, 'A–Z'),
                  MapEntry(SortKey.pagesDesc, 'Pages'),
                ],
                selected: _f.sort,
                onChanged: (v) => setState(() => _f = _f.copyWith(sort: v)),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _f = const LibraryFilter());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_f),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentStrong,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _segmented<T>({
    required List<MapEntry<T, String>> options,
    required T selected,
    required ValueChanged<T> onChanged,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((opt) {
        final sel = opt.key == selected;
        return ChoiceChip(
          label: Text(opt.value),
          selected: sel,
          showCheckmark: false,
          selectedColor: AppColors.accent.withValues(alpha: 0.3),
          backgroundColor: Colors.transparent,
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.55)),
          onSelected: (_) => onChanged(opt.key),
        );
      }).toList(),
    );
  }

  Widget _dropdown(List<String> options, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(),
      hint: const Text('Any'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Any')),
        ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(o))),
      ],
      onChanged: onChanged,
    );
  }
}
