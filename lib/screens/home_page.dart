import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = FirebaseFirestore.instance;

  void getItems() {
    db.collection("items").get().then(
        (querySnapshot) {
          print("Sucesssfully completed");

          for(var docSnapshot in querySnapshot.docs){
            print('${docSnapshot.id} => {docSnapshot.data()}');
          }
        },
      onError: (e) => print("Error completing : $e"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            Row(
              children: [
              ],)
          ],),);
  }
}
