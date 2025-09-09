import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectionProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isOnline = false;
  
  ConnectivityResult get connectionStatus => _connectionStatus;
  bool get isOnline => _isOnline;
  
  ConnectionProvider() {
    _initializeConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  Future<void> _initializeConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Error checking connectivity: $e');
    }
  }
  
  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionStatus = result;
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
    
    if (_isOnline) {
      _syncOfflineData();
    }
  }
  
  Future<void> _syncOfflineData() async {
    // Sync offline data when connection is restored
    try {
      // This would sync any offline prayers, session data, etc.
      print('Syncing offline data...');
      // Implementation would depend on your local storage service
    } catch (e) {
      print('Error syncing offline data: $e');
    }
  }
  
  String getConnectionStatusText() {
    switch (_connectionStatus) {
      case ConnectivityResult.wifi:
        return 'Connected via WiFi';
      case ConnectivityResult.mobile:
        return 'Connected via Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Connected via Ethernet';
      case ConnectivityResult.none:
        return 'No Internet Connection';
      default:
        return 'Unknown Connection Status';
    }
  }
  
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}