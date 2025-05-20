import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:uuid/uuid.dart';

/**
 * TODO :
 *  Make app responsive
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection("items").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          final items = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          if (items.isEmpty) {
            return const Center(child: Text('No items found.'));
          }

          return ItemMenuAndSelectionPanel(items: items, db: db);
        },
      ),
    );
  }
}

class ItemMenuAndSelectionPanel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final FirebaseFirestore db;
  const ItemMenuAndSelectionPanel({super.key, required this.items, required this.db});

  @override
  State<ItemMenuAndSelectionPanel> createState() => _ItemMenuAndSelectionPanelState();
}

class _ItemMenuAndSelectionPanelState extends State<ItemMenuAndSelectionPanel> {
  double _itemTotal = 0.00, _balance = 0.00, _paidAmount = 0.00;
  Map<String, int> _selectedItems = {}; // LinkedHashMap
  late TextEditingController _amountReceivedController;
  String? _paymentError;

  @override
  void initState() {
    super.initState();
    _amountReceivedController = TextEditingController();
  }

  @override
  void dispose() {
    _amountReceivedController.dispose();
    super.dispose();
  }

  void updateTotal(double itemPrice) {
    setState(() {
      _itemTotal += itemPrice;
    });
  }

  void resetSale() {
    setState(() {
      _itemTotal = 0;
      _selectedItems.clear();
      _paidAmount = 0.0;
      _balance = 0.0;
      _paymentError = null;
    });
      _amountReceivedController.clear();
  }

  void selectItems(String itemName) {
    setState(() {
      if (!_selectedItems.containsKey(itemName)) {
        _selectedItems[itemName] = 1;
      } else {
        _selectedItems.update(itemName, (value) => value + 1);
      }
    });
  }

  // helper methods
  bool _checkIsItemsSelected() {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No items selected'), duration: Durations.extralong1,),
      );
      return false;
    }
    return true;
  }

  String? _validateAmountReceived(){
    double? received = double.tryParse(_amountReceivedController.text);

    if (received == null || received < _itemTotal){
      return 'Enter a valid amount';
    }

    return null;
  }

  void closeSale() async {
    // validate items present
    if (!_checkIsItemsSelected()) {
      return;
    }

    // validate amount entered
    final String? error = _validateAmountReceived();
    if (error != null){
      setState(() {
        _paymentError = error;
      });

      return;
    }

    String newSaleId = '';
    await widget.db.collection('sales').add({
      'totalCost': _itemTotal,
      'timestamp': FieldValue.serverTimestamp()
    }).then((DocumentReference doc) {
      newSaleId = doc.id;
    });

    for (var entry in _selectedItems.entries) {
      await widget.db.collection('saleitems').add({
        'saleId': newSaleId,
        'item': entry.key,
        'quantity': entry.value,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sale closed successfully!')),
    );

    setState(() {
      _itemTotal = 0.0;
      _paidAmount = 0.0;
      _balance = 0.0;
      _selectedItems.clear();
    });
    _amountReceivedController.clear();
  }

  void confirmPayment() {
    if (!_checkIsItemsSelected()) {
      return;
    }

    final String? error = _validateAmountReceived();

    setState(() {
      _paymentError = error;
      if (error == null){
        double received = double.parse(_amountReceivedController.text);
        _paidAmount = received;
        _balance = received - _itemTotal;
      }
      else {
        _paidAmount = 0.0;
        _balance = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Left: Name and Price
              Expanded(
                child: _MenuList(items: items),
              ),
              // Right: Clickable Names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Select Items',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                                selectItems(item['itemName']);
                                double price = (item['itemPrice'] as num).toDouble();
                                // update selection total
                                updateTotal(price);

                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Clicked: ${item['itemName']}'),
                                    duration: Durations.medium1,
                                  ),
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
          ),
        ),
        // Checkout and summary widgets
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
            if (_selectedItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'No items selected',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            if (_selectedItems.isNotEmpty)
              SizedBox(
                height: 110,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ..._selectedItems.entries.map(
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
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountReceivedController,
                      keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount Received',
                        errorText: _paymentError,
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
                          'Total: \Rs.${_itemTotal.toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          'Paid Amount: Rs.${_paidAmount.toStringAsFixed(2)}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          'Balance: Rs.${_balance.toStringAsFixed(2)}'),
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
                        onPressed: resetSale,
                        child: Text('Reset sale'),
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
    );
  }
}

class _MenuList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _MenuList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Menu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    );
  }
}
