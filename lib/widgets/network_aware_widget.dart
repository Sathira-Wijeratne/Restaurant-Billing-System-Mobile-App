import 'package:flutter/material.dart';
import 'package:billingapp/services/network_service.dart';

class NetworkAwareWidget extends StatefulWidget {
  final Widget onlineChild;
  final Widget offlineChild;

  const NetworkAwareWidget({
    Key? key,
    required this.onlineChild,
    required this.offlineChild,
  }) : super(key: key);

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  final NetworkService _networkService = NetworkService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = _networkService.isConnected;
    _networkService.connectivityStream.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isConnected ? widget.onlineChild : widget.offlineChild;
  }
}
