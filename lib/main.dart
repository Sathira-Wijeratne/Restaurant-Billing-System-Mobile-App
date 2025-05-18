import 'package:billingapp/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(CasaDelGusto());
}

class CasaDelGusto extends StatelessWidget {
  const CasaDelGusto({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casa Del Gusto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)
      ),
      home: HomePage(title: 'Casa Del Gusto'),
    );
  }
}
