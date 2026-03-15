class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? iban;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.iban,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Ultra-greedy: if passed a container instead of the user object, dive in
    if (!json.containsKey('id') &&
        json.containsKey('user') &&
        json['user'] is Map<String, dynamic>) {
      return User.fromJson(json['user']);
    }

    String? iban = json['iban']?.toString();
    if (iban == 'null') iban = null;

    // Dive into wallet for IBAN
    final wallet = json['wallet'];
    if (wallet is Map) {
      if (iban == null || iban.isEmpty) {
        iban = wallet['iban']?.toString();
        if (iban == 'null') iban = null;
      }
    } else if (wallet is String && (iban == null || iban.isEmpty)) {
      iban = wallet;
      if (iban == 'null') iban = null;
    }

    // Last ditch: look for any key ending in _iban
    if (iban == null || iban.isEmpty) {
      for (var key in json.keys) {
        if (key.toLowerCase().contains('iban')) {
          iban = json[key]?.toString();
          if (iban != 'null') break;
        }
      }
    }

    return User(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      iban: (iban != null && iban.isNotEmpty && iban != 'null')
          ? iban.trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'iban': iban,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? iban,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      iban: iban ?? this.iban,
    );
  }
}

class Transaction {
  final int? localId;
  final int? serverId;
  final String description;
  final int? referenceId;
  final String type;
  final double amount;
  final double? balanceBefore;
  final double? balanceAfter;
  final String createdAt;
  final String? senderName;
  final String? senderPhone;
  final String? receiverName;
  final String? receiverPhone;
  final String? reference;

  Transaction({
    this.localId,
    this.serverId,
    required this.description,
    this.referenceId,
    required this.type,
    required this.amount,
    this.balanceBefore,
    this.balanceAfter,
    required this.createdAt,
    this.senderName,
    this.senderPhone,
    this.receiverName,
    this.receiverPhone,
    this.reference,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      serverId: int.tryParse(json['id']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      referenceId: int.tryParse(json['reference_id']?.toString() ?? ''),
      type: json['type']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      balanceBefore: double.tryParse(json['balance_before']?.toString() ?? ''),
      balanceAfter: double.tryParse(json['balance_after']?.toString() ?? ''),
      createdAt: json['created_at']?.toString() ?? '',
      senderName: json['sender_name']?.toString(),
      senderPhone: json['sender_phone']?.toString(),
      receiverName: json['receiver_name']?.toString(),
      receiverPhone: json['receiver_phone']?.toString(),
      reference: json['reference']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'serverId': serverId,
      'description': description,
      'reference_id': referenceId,
      'type': type,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'created_at': createdAt,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'reference': reference,
    };
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;

  AuthResponse({required this.success, required this.message, this.data});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }
}

class AuthData {
  final String token;
  final User user;

  AuthData({required this.token, required this.user});

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}

class WalletDataResponse {
  final bool success;
  final WalletData? data;

  WalletDataResponse({required this.success, this.data});

  factory WalletDataResponse.fromJson(Map<String, dynamic> json) {
    return WalletDataResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? WalletData.fromJson(json['data']) : null,
    );
  }
}

class WalletData {
  final double balance;
  final String? iban;
  final User? user;
  final List<Transaction> transactions;

  WalletData(
      {required this.balance,
      this.iban,
      this.user,
      required this.transactions});

  factory WalletData.fromJson(Map<String, dynamic> json) {
    // For GET /api/wallet/data where it might be in data.iban or data.wallet.iban
    String? iban = json['iban']?.toString();
    if (iban == 'null') iban = null;

    final wallet = json['wallet'];
    if (wallet is Map) {
      if (iban == null || iban.isEmpty) {
        iban = wallet['iban']?.toString();
        if (iban == 'null') iban = null;
      }
    }

    return WalletData(
      balance: double.tryParse(json['balance']?.toString() ?? '') ??
          double.tryParse(json['wallet']?['balance']?.toString() ?? '') ??
          0.0,
      iban: (iban != null && iban.isNotEmpty && iban != 'null')
          ? iban.trim()
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      transactions: (json['transactions'] as List?)
              ?.map((i) => Transaction.fromJson(i))
              .toList() ??
          [],
    );
  }
}
