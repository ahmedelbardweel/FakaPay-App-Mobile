import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import '../models/auth_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static sql.Database? _database;
  final _secureStorage = const FlutterSecureStorage();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    // After initialization, check for recovery
    await checkAndRecover();
    return _database!;
  }

  // --- Deterministic Hardware ID ---

  Future<String> _getDeterministicSeed() async {
    final deviceInfo = DeviceInfoPlugin();
    String seed = 'FakaPay_Global_Salt_';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      seed += androidInfo
          .id; // Unique ID that survives factory resets sometimes and certainly survives uninstalls
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      seed += iosInfo.identifierForVendor ?? 'ios_fallback_seed';
    }
    return seed;
  }

  // --- Secure Key Management ---

  Future<encrypt.Key> _getEncryptionKey() async {
    String? keyStr = await _secureStorage.read(key: 'vault_encryption_key');
    if (keyStr == null) {
      // PROBABILITY: App was uninstalled or first run.
      // We derive the key from the Hardware ID to ensure survival.
      final seed = await _getDeterministicSeed();
      final keyBytes = sha256.convert(utf8.encode("${seed}_key")).bytes;
      final newKey = encrypt.Key(Uint8List.fromList(keyBytes));

      // Save it back to secure storage for performance, but it's now recoverable.
      await _secureStorage.write(
          key: 'vault_encryption_key', value: newKey.base64);
      return newKey;
    }
    return encrypt.Key.fromBase64(keyStr);
  }

  Future<encrypt.IV> _getIV() async {
    String? ivStr = await _secureStorage.read(key: 'vault_encryption_iv');
    if (ivStr == null) {
      final seed = await _getDeterministicSeed();
      // Derive IV from seed (using first 16 bytes of a different hash)
      final ivBytes =
          sha256.convert(utf8.encode("${seed}_iv")).bytes.sublist(0, 16);
      final newIv = encrypt.IV(Uint8List.fromList(ivBytes));

      await _secureStorage.write(
          key: 'vault_encryption_iv', value: newIv.base64);
      return newIv;
    }
    return encrypt.IV.fromBase64(ivStr);
  }

  Future<sql.Database> _initDatabase() async {
    String path = join(await sql.getDatabasesPath(), 'faka_pay.db');
    return await sql.openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS offline_tokens(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              token TEXT,
              amount REAL,
              created_at TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> _onCreate(sql.Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        description TEXT,
        amount REAL,
        type TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE offline_tokens(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token TEXT,
        amount REAL,
        created_at TEXT
      )
    ''');
  }

  // --- ShadowVault Logic ---

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      return false;
    }
    return true;
  }

  Future<File?> _getShadowFile() async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Documents/FakaPay');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } else {
        dir = await getApplicationSupportDirectory();
      }
      return File(join(dir.path, 'shadow_vault.json.enc'));
    } catch (e) {
      print('ShadowVault: Error getting path: $e');
      return null;
    }
  }

  Future<void> _syncToShadowVault() async {
    try {
      if (!await _requestPermission()) {
        print('ShadowVault Sync Blocked: Permission denied');
        return;
      }

      final tokens = await getOfflineTokens();
      final shadowFile = await _getShadowFile();
      if (shadowFile == null) return;

      if (tokens.isEmpty) {
        if (await shadowFile.exists()) await shadowFile.delete();
        return;
      }

      final jsonData = jsonEncode(tokens);
      final key = await _getEncryptionKey();
      final iv = await _getIV();

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(jsonData, iv: iv);

      await shadowFile.writeAsBytes(encrypted.bytes);
      print(
          'ShadowVault: Successfully synced ${tokens.length} tokens to ${shadowFile.path}');
    } catch (e) {
      print('ShadowVault Sync Error: $e');
    }
  }

  Future<void> checkAndRecover() async {
    try {
      print('ShadowVault: Checking for recovery...');

      final db = await database;
      final currentTokens = await db.query('offline_tokens');
      if (currentTokens.isNotEmpty) {
        print('ShadowVault: Local DB is not empty. Skipping recovery.');
        return;
      }

      if (!await _requestPermission()) {
        print('ShadowVault Recovery Blocked: Permission denied');
        return;
      }

      final shadowFile = await _getShadowFile();
      if (shadowFile == null || !await shadowFile.exists()) {
        print('ShadowVault: No backup file found.');
        return;
      }

      print(
          'ShadowVault: Backup file found at ${shadowFile.path}. Attempting decryption...');

      final encryptedBytes = await shadowFile.readAsBytes();
      final key = await _getEncryptionKey();
      final iv = await _getIV();

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted =
          encrypter.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);

      final List<dynamic> recovered = jsonDecode(decrypted);
      for (var tokenMap in recovered) {
        await db.insert(
            'offline_tokens',
            {
              'token': tokenMap['token'],
              'amount': tokenMap['amount'],
              'created_at': tokenMap['created_at'],
            },
            conflictAlgorithm: sql.ConflictAlgorithm.ignore);
      }
      print('ShadowVault: SUCCESS! Recovered ${recovered.length} tokens.');
    } catch (e) {
      print('ShadowVault Recovery CRITICAL ERROR: $e');
    }
  }

  // Transaction operations
  Future<void> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      {
        'id': transaction.reference ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'description': transaction.description,
        'amount': transaction.amount,
        'type': transaction.type,
        'created_at': transaction.createdAt,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('transactions', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Transaction.fromJson(maps[i]));
  }

  Future<void> clearTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  // Offline Token operations
  Future<void> insertOfflineToken(String token, double amount) async {
    final db = await database;
    await db.insert(
      'offline_tokens',
      {
        'token': token,
        'amount': amount,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
    await _syncToShadowVault();
  }

  Future<List<Map<String, dynamic>>> getOfflineTokens() async {
    final db = await database;
    return await db.query('offline_tokens', orderBy: 'created_at ASC');
  }

  Future<void> deleteOfflineToken(int id) async {
    final db = await database;
    await db.delete(
      'offline_tokens',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncToShadowVault();
  }

  Future<void> deleteAllOfflineTokens() async {
    final db = await database;
    await db.delete('offline_tokens');
    await _syncToShadowVault();
  }
}
