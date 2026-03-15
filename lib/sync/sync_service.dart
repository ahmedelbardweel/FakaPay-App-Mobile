import 'package:workmanager/workmanager.dart';
import '../data/local/database_helper.dart';
import '../data/api/api_service.dart';
import '../data/models/auth_models.dart';
import '../utils/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final dbHelper = DatabaseHelper();
    final apiService = ApiService();

    try {
      // 1. Fetch pending offline tokens
      final tokens = await dbHelper.getOfflineTokens();

      if (tokens.isNotEmpty) {
        final List<Map<String, dynamic>> syncData = tokens
            .map((t) => {
                  'token': t['token'],
                  'amount': t['amount'],
                })
            .toList();

        if (syncData.isNotEmpty) {
          final response = await apiService.syncTransfers(syncData);
          if (response.statusCode == 200 || response.statusCode == 201) {
            // 3. Clear synced tokens locally
            await dbHelper.deleteAllOfflineTokens();
          }
        }
      }

      // 4. Check for new received transactions (Notifications)
      await _checkNewTransactions(apiService);

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

Future<void> _checkNewTransactions(ApiService apiService) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastTransactionId = prefs.getInt('last_transaction_id') ?? 0;

    final response = await apiService.getWalletData();
    final walletResponse = WalletDataResponse.fromJson(response.data);

    if (walletResponse.success && walletResponse.data != null) {
      final transactions = walletResponse.data!.transactions;
      if (transactions.isNotEmpty) {
        final maxId = transactions
            .map((t) => t.serverId ?? 0)
            .reduce((a, b) => a > b ? a : b);

        if (lastTransactionId == 0) {
          // First time initialization: don't notify for old history
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
          await notificationService.initialize();

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
    }
  } catch (e) {
    // Silent fail in background
  }
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  void initialize() {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
  }

  void scheduleSync() {
    Workmanager().registerOneOffTask(
      "sync-task",
      "syncTask",
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  void registerPeriodicSync() {
    Workmanager().registerPeriodicTask(
      "periodic-sync-task",
      "periodicSyncTask",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Immediately syncs all pending offline tokens in the foreground.
  /// Processes each token individually using the proven processTransfer endpoint.
  /// Returns true if at least one token was synced successfully.
  static Future<bool> syncOnLogin() async {
    final dbHelper = DatabaseHelper();
    final apiService = ApiService();

    try {
      final tokens = await dbHelper.getOfflineTokens();
      if (tokens.isEmpty) return false;

      bool anySynced = false;
      for (final t in tokens) {
        try {
          final response = await apiService.processTransfer(
            t['token'] as String,
            (t['amount'] as num).toDouble(),
          );
          if (response.statusCode == 200 || response.statusCode == 201) {
            await dbHelper.deleteOfflineToken(t['id'] as int);
            anySynced = true;
          }
        } catch (_) {
          // Keep this token in the queue and try next one
        }
      }
      return anySynced;
    } catch (_) {
      return false;
    }
  }

  /// Process a single offline token against the server.
  static Future<bool> processSingleToken(String token, double amount) async {
    try {
      final apiService = ApiService();
      final response = await apiService.processTransfer(token, amount);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
