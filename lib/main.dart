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
    return MaterialApp(
      title: 'Casa Del Gusto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)
      ),
      home: HomePage(title: 'Casa Del Gusto'),
    );
  }
}
