import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:uuid/uuid.dart';

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
  //
  final db = FirebaseFirestore.instance;
  double itemTotal = 0.00;
  // TODO : is it ok to create linkedhashmap like this?
  LinkedHashMap<String, int> selectedItems = LinkedHashMap();
  double balance = 0.00;
  double paidAmount = 0.00;
  bool isLoading = true;
  late List<Map<String, dynamic>> items;
  late TextEditingController amountReceivedController;
  String? paymentError;

  //
  @override
  void initState() {
    super.initState();
    amountReceivedController = TextEditingController();

    // fetch items
    fetchItems().then((fetchedItems) {
      setState(() {
        items = fetchedItems;
        isLoading = false;
      });
    }).catchError((error) {
      if (kDebugMode) {
        print("Error fetching items: $error");
      }
      setState(() {
        isLoading = false;
      });

      // TODO : store the error in a variable to display in the UI
    });
    // TODO : show a SnackBar or error message
  }

  @override
  void dispose() {
    amountReceivedController.dispose();
    super.dispose();
  }

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

  void clearSelectedItems() {
    setState(() {
      itemTotal = 0;
      selectedItems.clear();
      paidAmount = 0.0;
      balance = 0.0;
    });

    amountReceivedController.clear();
  }

  void selectItems(String itemName) {
    setState(() {
      if (!selectedItems.containsKey(itemName)) {
        selectedItems[itemName] = 1;
      } else {
        selectedItems.update(itemName, (value) => value + 1);
      }
    });
  }

  bool checkIsItemsSelected(){
    if(selectedItems.isEmpty){
      // notify that sale cannot be closed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No items selected')),
      );
      return false;
    }

    return true;
  }

  void confirmPayment() {
    if(!checkIsItemsSelected()){
      return;
    }

    setState(() {
      paymentError = null;
      double? received = double.tryParse(amountReceivedController.text);
      if (received == null || received < itemTotal) {
        paymentError = 'Enter a valid amount';
        paidAmount = 0.0;
        balance = 0.0;
      } else {
        paidAmount = received;
        balance = received - itemTotal;
      }
    });
  }

  void closeSale() async {
    confirmPayment();

    // Generate unique sale ID
    // var uuid = Uuid();
    // String saleId = uuid.v4();

    // Add to 'sales' collection
    // await db.collection('sales').doc(saleId).set({
    //   // 'saleId': saleId,
    //   'totalCost': itemTotal,
    //   'timestamp': FieldValue.serverTimestamp(),
    // });
    String newSaleId = '';
    await db.collection('sales').add({
      'totalCost' : itemTotal,
      'timestamp' : FieldValue.serverTimestamp()
    }).then((DocumentReference doc) {
      print('DocumentSnapshot added with ID : ${doc.id}');
      newSaleId = doc.id;
    });

    // Add to 'saleitems' collection
    for (var entry in selectedItems.entries) {
      await db.collection('saleitems').add({
        'saleId': newSaleId,
        'item': entry.key,
        'quantity': entry.value,
      });
    }

    // Notify success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sale closed successfully!')),
    );

    // Clear variables
    setState(() {
      itemTotal = 0.0;
      paidAmount = 0.0;
      balance = 0.0;
      selectedItems.clear();
    });

    amountReceivedController.clear();
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
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : items.isEmpty
                ? const Center(
              child: Text('No items found.'),
            )
                : Row(
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
                                title: Text(item['itemName']?.toString() ??
                                    'No Name'),
                                subtitle: Text(
                                    'Rs.${item['itemPrice']?.toString() ?? 'N/A'}'),
                              );
                            },
                          ),
                        ),
                      ],
                    )),
                // Right: Clickable Names
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Select Items',
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
                                  double price = (item['itemPrice']
                                  as num)
                                      .toDouble();
                                  updateTotal(price);

                                  // Handle click event here
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Clicked: ${item['itemName']}'),
                                      duration: Durations.medium1,
                                    ),
                                  );
                                },
                                child: Text(
                                  item['itemName']?.toString() ??
                                      'No Name',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration:
                                    TextDecoration.underline,
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
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Checkout Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (selectedItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'No items selected',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              if (selectedItems.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...selectedItems.entries.map(
                            (entry) => Center(
                          child: Text(
                            '${entry.key} x${entry.value}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // --- Payment input section ---
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountReceivedController,
                        keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount Received',
                          errorText: paymentError,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: confirmPayment,
                      child: Text('Confirm Payment'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            'Total: \Rs.${itemTotal.toStringAsFixed(2)}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            'Paid Amount: Rs.${paidAmount.toStringAsFixed(2)}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            'Balance: Rs.${balance.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: clearSelectedItems,
                          child: Text('Clear selection'),
                        ),
                      ),
                      ElevatedButton(
                          onPressed: closeSale, child: Text('Close Sale'))
                    ],
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
