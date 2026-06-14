import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'tbr_screen.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    LibraryScreen(),
    TbrScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: _pages[_index],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _NavBar(
              index: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  static const _icons = [
    Icons.home_outlined,
    Icons.menu_book_outlined,
    Icons.bookmark_border,
    Icons.settings_outlined,
  ];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.bookmark_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = screenWidth < 312 ? screenWidth - 32 : 280.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: navWidth,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.borderMid),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                final sel = index == i;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel ? AppColors.accent : Colors.transparent,
                    ),
                    child: Icon(
                      sel ? _activeIcons[i] : _icons[i],
                      size: 28,
                      color: sel ? AppColors.bg : AppColors.textTertiary,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
