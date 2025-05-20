import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectivityStreamController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectivityStream => _connectivityStreamController.stream;
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  void initialize() {
    // Check current connectivity state
    _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = result != ConnectivityResult.none;
    _connectivityStreamController.add(_isConnected);
  }

  void dispose() {
    _connectivityStreamController.close();
  }
}
