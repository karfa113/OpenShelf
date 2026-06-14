import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/library_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_gate.dart';
import 'services/firestore_storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final theme = ThemeProvider();
  await theme.load();

  runApp(LibraryManualApp(theme: theme));
}

class LibraryManualApp extends StatelessWidget {
  final ThemeProvider theme;
  const LibraryManualApp({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: theme),
        // LibraryProvider sits above MaterialApp so it's reachable from any
        // pushed route (AddBookScreen, BookDetailScreen, etc.). The proxy
        // rebinds it to the current user whenever AuthProvider changes.
        ChangeNotifierProxyProvider<AuthProvider, LibraryProvider>(
          create: (_) => LibraryProvider((uid) => FirestoreStorageService(uid)),
          update: (_, auth, library) {
            library!.rebindToUid(auth.user?.uid);
            return library;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, t, _) => MaterialApp(
          title: 'OpenShelf',
          debugShowCheckedModeBanner: false,
          themeMode: t.mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const AuthGate(),
        ),
      ),
    );
  }
}
