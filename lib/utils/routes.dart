import 'package:flutter/material.dart';

PageRoute smoothRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, anim, secondaryAnimation, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
