import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class GenreChipInput extends StatefulWidget {
  final List<String> genres;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;

  const GenreChipInput({
    super.key,
    required this.genres,
    required this.onChanged,
    this.suggestions = const [],
  });

  @override
  State<GenreChipInput> createState() => _GenreChipInputState();
}

class _GenreChipInputState extends State<GenreChipInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _add([String? value]) {
    final v = (value ?? _controller.text).trim();
    if (v.isEmpty) return;
    if (widget.genres.any((g) => g.toLowerCase() == v.toLowerCase())) {
      _controller.clear();
      _keepFocus();
      return;
    }
    widget.onChanged([...widget.genres, v]);
    _controller.clear();
    _keepFocus();
  }

  /// Keep the keyboard up so the user can chain-add genres. The post-frame
  /// callback ensures we refocus after the parent's setState rebuild settles.
  void _keepFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _remove(String g) {
    widget.onChanged(widget.genres.where((x) => x != g).toList());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RawAutocomplete<String>(
                textEditingController: _controller,
                focusNode: _focusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return widget.suggestions.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _add(selection);
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: (_) => _add(),
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () {
                      // Block the default behaviour of advancing focus to the
                      // next form field. We handle focus ourselves in _add().
                    },
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Add genre',
                      hintText: 'e.g. Sci-Fi',
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
                        width: MediaQuery.of(context).size.width - 120,
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              title: Text(option, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
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
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _add,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        if (widget.genres.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.genres
                .map((g) => Chip(
                      label: Text(g),
                      onDeleted: () => _remove(g),
                      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.55)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
