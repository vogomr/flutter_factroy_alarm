import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui/login_page.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final loggedIn = prefs.getBool('is_logged_in') ?? false;
  runApp(MyApp(initialRoute: loggedIn ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    const kScale = 1.15;

    // Helper to scale a single style safely
    TextStyle? scaled(TextStyle? s) =>
        (s == null) ? null : s.copyWith(fontSize: (s.fontSize ?? 14) * kScale);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Factory Alarm Controller',
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: Colors.red,
          secondary: Colors.orangeAccent,
          surface: Colors.white,
          error: const Color(0xFFB00020),
          onSurface: Colors.black,
        ),
        // Scale only known styles; leave others untouched to avoid assertions.
        textTheme: base.textTheme.copyWith(
          displayLarge:  scaled(base.textTheme.displayLarge),
          displayMedium: scaled(base.textTheme.displayMedium),
          displaySmall:  scaled(base.textTheme.displaySmall),
          headlineLarge: scaled(base.textTheme.headlineLarge),
          headlineMedium: scaled(base.textTheme.headlineMedium),
          headlineSmall: scaled(base.textTheme.headlineSmall),
          titleLarge:    scaled(base.textTheme.titleLarge),
          titleMedium:   scaled(base.textTheme.titleMedium),
          titleSmall:    scaled(base.textTheme.titleSmall),
          bodyLarge:     scaled(base.textTheme.bodyLarge),
          bodyMedium:    scaled(base.textTheme.bodyMedium),
          bodySmall:     scaled(base.textTheme.bodySmall),
          labelLarge:    scaled(base.textTheme.labelLarge),
          labelMedium:   scaled(base.textTheme.labelMedium),
          labelSmall:    scaled(base.textTheme.labelSmall),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            minimumSize: const Size(200, 100),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}