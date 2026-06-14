import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/library_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/root_scaffold.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final storage = LocalStorageService();
  final library = LibraryProvider(storage);
  final theme = ThemeProvider();
  await Future.wait([library.load(), theme.load()]);

  runApp(LibraryManualApp(library: library, theme: theme));
}

class LibraryManualApp extends StatelessWidget {
  final LibraryProvider library;
  final ThemeProvider theme;
  const LibraryManualApp({super.key, required this.library, required this.theme});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: library),
        ChangeNotifierProvider.value(value: theme),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, t, _) => MaterialApp(
          title: 'OpenShelf',
          debugShowCheckedModeBanner: false,
          themeMode: t.mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const RootScaffold(),
        ),
      ),
    );
  }
}
