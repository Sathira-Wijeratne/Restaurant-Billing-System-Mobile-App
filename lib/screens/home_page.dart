import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/**
 * TODO :
 *  Show data changes in real time
 *  Make app responsive
 *  Fix lists reloading evertime press any button
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
  double itemTotal = 0.0;
  // TODO : is it ok to create linkedhashmap like this?
  LinkedHashMap<String, int> selectedItems = new LinkedHashMap();

  // TODO : is initstate necessary and other methods necessary? what variables goes inside them?
  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   selectedItems = LinkedHashMap<String, int>();
  // }

  // methods
  Future<List<Map<String, dynamic>>> fetchItems() async {
    final querySnapshot = await db.collection("items").get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  void updateTotal(double itemPrice) {
    setState(() {
      itemTotal += itemPrice;
    });
  }

  void clearSelectedItems(){
    setState(() {
      itemTotal = 0;
      selectedItems.clear();
    });
  }

  void selectItems(String itemName){
    setState(() {
      if(!selectedItems.containsKey(itemName)){
        selectedItems[itemName] = 1;
      } else {
        selectedItems.update(itemName, (value) => value + 1);
      }
    });
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
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Menu',
                                style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                              ),
                            ),
                            Expanded(
                                child: ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return ListTile(
                                      title: Text(item['itemName']?.toString() ?? 'No Name'),
                                      subtitle: Text('Rs.${item['itemPrice']?.toString() ?? 'N/A'}'),
                                    );
                                  },
                                ),
                            ),
                          ],
                        )
                      ),
                      // Right: Clickable Names
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Select Items',
                                  style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return ListTile(
                                    title: InkWell(
                                      onTap: () {
                                        // TODO : Should errors be handled here?
                                        // update selection total
                                        selectItems(item['itemName']);
                                        double price = (item['itemPrice'] as num).toDouble();
                                        updateTotal(price);

                                        // Handle click event here
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Clicked: ${item['itemName']}'), duration: Durations.medium1,),
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
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Checkout Items',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                if (selectedItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No items selected', style: TextStyle(fontSize: 16,),),
                  ),

                if (selectedItems.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ...selectedItems.entries.map((entry) => Center(
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Total: \Rs.${itemTotal.toStringAsFixed(2)}'),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: clearSelectedItems,
                        child: Text('Clear selection'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
