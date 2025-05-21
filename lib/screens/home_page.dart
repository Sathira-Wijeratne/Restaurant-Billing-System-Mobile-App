import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:billingapp/services/network_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = FirebaseFirestore.instance;
  final NetworkService _networkService = NetworkService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    // Initialize the network service
    _isConnected = _networkService.isConnected;
    // Listen for connectivity changes
    _networkService.connectivityStream.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });

      // Show snackbar if offline
      if (!isConnected) {
        _showOfflineSnackbar();
      }
    });
  }

  void _showOfflineSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You are currently offline. Some features may be unavailable.'),
        backgroundColor: Colors.red,
        duration: Duration(days: 1), // until connection is back
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      // Use NetworkAwareWidget to show different content based on connectivity
      body: !_isConnected
          ? _buildOfflineWidget()
          : StreamBuilder<QuerySnapshot>(
              stream: db.collection("items").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                final items = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No items found.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  );
                }

                return ItemMenuAndSelectionPanel(items: items, db: db, isConnected: _isConnected);
              },
            ),
    );
  }

  Widget _buildOfflineWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 80,
            color: Color(0xFF8D2B0B),
          ),
          SizedBox(height: 16),
          Text(
            'You are offline',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 8),
          Text(
            'Please check your internet connection',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {}); // Refresh the UI
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class ItemMenuAndSelectionPanel extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final FirebaseFirestore db;
  final bool isConnected;

  const ItemMenuAndSelectionPanel({
    super.key,
    required this.items,
    required this.db,
    required this.isConnected,
  });

  @override
  State<ItemMenuAndSelectionPanel> createState() => _ItemMenuAndSelectionPanelState();
}

class _ItemMenuAndSelectionPanelState extends State<ItemMenuAndSelectionPanel> {
  double _itemTotal = 0.00, _balance = 0.00, _paidAmount = 0.00;
  Map<String, int> _selectedItems = {};
  late TextEditingController _amountReceivedController;
  String? _paymentError;
  Map<String, double> _itemPriceMap = HashMap();

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
      _itemPriceMap.clear();
    });
    _amountReceivedController.clear();
  }

  void selectItems(String itemName, double itemPrice) {
    setState(() {
      if (!_selectedItems.containsKey(itemName)) {
        _selectedItems[itemName] = 1;
        _itemPriceMap[itemName] = itemPrice;
      } else {
        _selectedItems.update(itemName, (value) => value + 1);
      }
    });
  }

  bool _checkIsItemsSelected() {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No items selected'),
          duration: Durations.extralong1,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return false;
    }
    return true;
  }

  bool _checkIsAmountPaid(){
    if (_paidAmount == 0.0){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment not confirmed'),
          duration: Durations.extralong1,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      return false;
    }

    return true;
  }

  String? _validateAmountReceived() {
    double? received = double.tryParse(_amountReceivedController.text);

    if (received == null || received < _itemTotal) {
      return 'Enter a valid amount';
    }

    return null;
  }

  Future<String> generateSaleId () async {
    String newSaleId = '';

    try {
      DocumentSnapshot counterDoc = await widget.db.collection('counters').doc('sales').get();
      int counterValue = 1;

      if (counterDoc.exists) {
        counterValue = (counterDoc.data() as Map<String, dynamic>)['value'] + 1;
      }

      String formattedCounter = 'S${counterValue.toString().padLeft(3, '0')}';

      await widget.db.collection('counters').doc('sales').set({
        'value' : counterValue
      }, SetOptions(merge: true)); // create new document if doesn't exist, if exist, update only value

      newSaleId = formattedCounter;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error generating sale ID : ${error.toString()}'),
            backgroundColor: Colors.red,
        ),
      );
    }

    return newSaleId;
  }

  void closeSale() async {
    if (!widget.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot complete sale while offline'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_checkIsItemsSelected() || !_checkIsAmountPaid()) {
      return;
    }

    final String? error = _validateAmountReceived();
    if (error != null) {
      setState(() {
        _paymentError = error;
      });

      return;
    }

    // generate sale id
    String newSaleId = await generateSaleId();

    if (newSaleId.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating sale ID. Please try again'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }
    
    try{
      await widget.db.collection('sales').doc(newSaleId).set({
        'totalCost': _itemTotal,
        'timestamp': FieldValue.serverTimestamp()
      });

      for (var entry in _selectedItems.entries) {
        await widget.db.collection('saleitems').add({
          'saleId': newSaleId,
          'item': entry.key,
          'quantity': entry.value,
          'price' : _itemPriceMap[entry.key]
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale closed successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      setState(() {
        _itemTotal = 0.0;
        _paidAmount = 0.0;
        _balance = 0.0;
        _selectedItems.clear();
        _itemPriceMap.clear();
      });
      _amountReceivedController.clear();
    } catch (error){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving sale: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: Durations.extralong4
        ),
      );
    }

  }

  void confirmPayment() {
    if (!_checkIsItemsSelected()) {
      return;
    }

    final String? error = _validateAmountReceived();

    setState(() {
      _paymentError = error;
      if (error == null) {
        double received = double.parse(_amountReceivedController.text);
        _paidAmount = received;
        _balance = received - _itemTotal;
      } else {
        _paidAmount = 0.0;
        _balance = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: !isSmallScreen
                  ? Column(
                      children: [
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(8),
                            child: _MenuList(items: items),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(8),
                            child: _SelectionPanel(
                              items: items,
                              selectItems: selectItems,
                              updateTotal: updateTotal,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(12),
                            child: _MenuList(items: items),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(12),
                            child: _SelectionPanel(
                              items: items,
                              selectItems: selectItems,
                              updateTotal: updateTotal,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'Checkout Items',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (_selectedItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'No items selected',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    if (_selectedItems.isNotEmpty)
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).inputDecorationTheme.border!.borderSide.color),
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ..._selectedItems.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardTheme.color,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Theme.of(context).inputDecorationTheme.border!.borderSide.color),
                                      ),
                                      child: Text(
                                        '×${entry.value}',
                                        style: TextStyle(
                                          color: Color(0xFF5F4B32),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountReceivedController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Amount Received',
                                errorText: _paymentError,
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                prefixText: 'Rs.',
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: confirmPayment,
                            icon: Icon(Icons.check_circle),
                            label: Text('Confirm Payment'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SummaryRow(
                                label: 'Total',
                                value: 'Rs.${_itemTotal.toStringAsFixed(2)}',
                                isTotal: true,
                              ),
                              _SummaryRow(
                                label: 'Paid \nAmount',
                                value: 'Rs.${_paidAmount.toStringAsFixed(2)}',
                              ),
                              _SummaryRow(
                                label: 'Balance',
                                value: 'Rs.${_balance.toStringAsFixed(2)}',
                                isBalance: true,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: resetSale,
                                icon: Icon(Icons.refresh),
                                label: Text('Reset Sale'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: closeSale,
                                icon: Icon(Icons.check),
                                label: Text('Close Sale'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
        ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.white,
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: Theme.of(context)
                          .inputDecorationTheme
                          .border!
                          .borderSide
                          .color),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['itemName']?.toString() ?? 'No Name',
                          style: TextStyle(
                            color: Color(0xFF5F4B32),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        'Rs.${item['itemPrice']?.toString() ?? 'N/A'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(String, double) selectItems;
  final void Function(double) updateTotal;

  const _SelectionPanel({
    required this.items,
    required this.selectItems,
    required this.updateTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Select Items',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.white,
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: Theme.of(context)
                          .inputDecorationTheme
                          .border!
                          .borderSide
                          .color),
                ),
                child: InkWell(
                  onTap: () {
                    double price = (item['itemPrice'] as num).toDouble();
                    selectItems(item['itemName'], price);
                    updateTotal(price);

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('\'${item['itemName']}\' added'),
                        duration: Durations.medium1,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['itemName']?.toString() ?? 'No Name',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Icon(
                          Icons.add_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isBalance;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isTotal
                  ? Color(0xFF5F4B32)
                  : (isBalance
                      ? Theme.of(context).colorScheme.primary
                      : Color(0xFF2C2C2C)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isTotal
                    ? Color(0xFF5F4B32)
                    : (isBalance
                        ? Theme.of(context).colorScheme.primary
                        : Color(0xFF2C2C2C)),
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
