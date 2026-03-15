import 'package:flutter_test/flutter_test.dart';
import 'package:faka_pay/data/models/auth_models.dart';

void main() {
  group('WalletData Parsing Tests', () {
    test('should parse string balance correctly', () {
      final json = {'balance': '12.50', 'transactions': []};

      final walletData = WalletData.fromJson(json);

      expect(walletData.balance, 12.50);
    });

    test('should parse numeric balance correctly', () {
      final json = {'balance': 10.0, 'transactions': []};

      final walletData = WalletData.fromJson(json);

      expect(walletData.balance, 10.0);
    });
  });

  group('Transaction Parsing Tests', () {
    test('should parse string amounts and balances correctly', () {
      final json = {
        'id': 1,
        'amount': '5.00',
        'balance_before': '15.00',
        'balance_after': '10.00',
        'description': 'Test',
        'type': 'transfer'
      };

      final tx = Transaction.fromJson(json);

      expect(tx.amount, 5.00);
      expect(tx.balanceBefore, 15.00);
      expect(tx.balanceAfter, 10.00);
    });
  });
}
