import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/**
 * TODO :
 *  Show data changes in real time
 *
 */
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final querySnapshot = await db.collection("items").get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final items = snapshot.data ?? []; // what does ?? mean?
            if (items.isEmpty) {
              return const Center(child: Text('No items found.'));
            }
            return Row(
              children: [
                // Left: Name and Price
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item['itemName']?.toString() ?? 'No Name'),
                        subtitle: Text('Price: ${item['itemPrice']?.toString() ?? 'N/A'}'),
                      );
                    },
                  ),
                ),
                // Right: Clickable Names
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: InkWell(
                          onTap: () {
                            // Handle click event here
                            // TODO : Pressing multiple times does not show the snackbar immediately, fix it
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Clicked: ${item['itemName']}')),
                            );
                          },
                          child: Text(
                            item['itemName']?.toString() ?? 'No Name',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
    );
  }
}
