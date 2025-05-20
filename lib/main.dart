import 'package:billingapp/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  // initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // set preferred orientations
  await SystemChrome.setPreferredOrientations(([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]));

  runApp(CasaDelGusto());
}

class CasaDelGusto extends StatelessWidget {
  const CasaDelGusto({super.key});

  @override
  Widget build(BuildContext context) {
    // Restaurant color palette
    const primaryColor = Color(0xFF8D2B0B); // brick red
    const backgroundColor = Color(0xFFFFF8E1); // warm cream
    const headingTextColor = Color(0xFF5F4B32); // warm brown
    const bodyTextColor = Color(0xFF2C2C2C); // dark gray
    const cardColor = Color(0xFFF5EBD5); // beige
    const borderColor = Color(0xFFE8E0D0); // light beige

    return MaterialApp(
      title: 'Casa Del Gusto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          onPrimary: Colors.white,
          secondary: primaryColor.withOpacity(0.8),
          background: backgroundColor,
          surface: cardColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        textTheme: Typography.blackMountainView.copyWith(
          headlineLarge: TextStyle(color: headingTextColor, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: headingTextColor, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: headingTextColor, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: headingTextColor, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: headingTextColor),
          bodyLarge: TextStyle(color: bodyTextColor),
          bodyMedium: TextStyle(color: bodyTextColor),
        ),
        cardTheme: CardTheme(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: HomePage(title: 'Casa Del Gusto'),
    );
  }
}
