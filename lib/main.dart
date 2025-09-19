import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/welcome_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'DebtMe',
      debugShowCheckedModeBanner: false,
      
      // Arabic language support
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'), // Arabic
        Locale('en', 'US'), // English (fallback)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // App theme
      theme: AppTheme.lightTheme,
      
      // Start with welcome screen
      home: const WelcomeScreen(),
    );
  }
}