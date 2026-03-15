import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api/api_service.dart';
import '../data/models/auth_models.dart';
import '../utils/notification_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  double _balance = 0.0;
  String? _iban;
  User? _updatedUser;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  WalletProvider() {
    _loadFromCache();
  }

  double get balance => _balance;
  String? get iban => _iban;
  User? get updatedUser => _updatedUser;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('wallet_cache');
      if (cachedData != null) {
        final data = json.decode(cachedData);
        _balance = (data['balance'] ?? 0.0).toDouble();
        _iban = data['iban'];
        if (data['user'] != null) {
          _updatedUser = User.fromJson(data['user']);
        }
        if (data['transactions'] != null) {
          _transactions = (data['transactions'] as List)
              .map((i) => Transaction.fromJson(i))
              .toList();
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading wallet cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'balance': _balance,
        'iban': _iban,
        'user': _updatedUser?.toJson(),
        'transactions': _transactions.map((t) => t.toJson()).toList(),
      };
      await prefs.setString('wallet_cache', json.encode(data));
    } catch (e) {
      debugPrint('Error saving wallet cache: $e');
    }
  }

  Future<void> refreshWalletData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getWalletData();
      final walletResponse = WalletDataResponse.fromJson(response.data);

      if (walletResponse.success && walletResponse.data != null) {
        _balance = walletResponse.data!.balance;
        _iban = walletResponse.data!.iban;
        _transactions = walletResponse.data!.transactions;
        _updatedUser = walletResponse.data!.user;
        _isLoading = false;
        await _saveToCache();

        // 4. Check for new received transactions (Foreground Notifications)
        await _checkNewForegroundTransactions(_transactions);

        notifyListeners();
      } else {
        _errorMessage = 'Failed to load wallet data';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Connection Error';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> topUp(double amount) async {
    try {
      final response = await _apiService.topUp(amount);
      if (response.data['success'] == true) {
        await refreshWalletData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void deductBalance(double amount) {
    _balance = (_balance - amount).clamp(0.0, double.infinity);
    _saveToCache(); // Persist immediately
    notifyListeners();
  }

  Future<void> _checkNewForegroundTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTransactionId = prefs.getInt('last_transaction_id') ?? 0;

      if (transactions.isNotEmpty) {
        final maxId = transactions
            .map((t) => t.serverId ?? 0)
            .reduce((a, b) => a > b ? a : b);

        if (lastTransactionId == 0) {
          await prefs.setInt('last_transaction_id', maxId);
          return;
        }

        final newTransactions = transactions.where((t) {
          final serverId = t.serverId ?? 0;
          return serverId > lastTransactionId && 
                 t.type.trim().toUpperCase() == 'CREDIT';
        }).toList();

        if (newTransactions.isNotEmpty) {
          final notificationService = NotificationService();
          for (final t in newTransactions) {
            String sender = t.senderName ?? t.senderPhone ?? "مجهول";
            await notificationService.showPaymentNotification(
              id: t.serverId ?? 0,
              title: "حوالة واردة جديدة",
              body: "استلمت ${t.amount} شيكل من $sender",
            );
          }
          await prefs.setInt('last_transaction_id', maxId);
        }
      }
    } catch (e) {
      debugPrint('Error checking foreground transactions: $e');
    }
  }
}
