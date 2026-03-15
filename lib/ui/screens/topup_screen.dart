import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/wallet_provider.dart';
import '../widgets/success_dialog.dart';
import '../theme.dart';
import '../../utils/translations.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  bool _isSuccess = false;
  double _newBalance = 0.0;

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: Text(
          S.of(context, 'topup_mobile'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10), // android:padding="10dp"
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                S.of(context, 'add_funds_to_wallet'),
                style: GoogleFonts.cairo(
                  color: AppTheme.gray400,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              // Amount Input
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: S.of(context, 'amount_shekel'),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              // Topup Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _handleTopup(walletProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.white,
                          ))
                      : Text(S.of(context, 'add_funds')),
                ),
              ),
              if (_isSuccess) ...[
                const SizedBox(height: 32),
                // Success Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.black,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppTheme.primaryYellow, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '✓ ${S.of(context, "topup_success")}',
                        style: GoogleFonts.cairo(
                          color: AppTheme.primaryYellow,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(context, 'new_balance'),
                        style: GoogleFonts.cairo(
                          color: AppTheme.gray400,
                          fontSize: 12,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _newBalance.toStringAsFixed(2),
                            style: GoogleFonts.cairo(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'ILS',
                              style: GoogleFonts.cairo(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTopup(WalletProvider walletProvider) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError(S.of(context, 'enter_amount_error'));
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError(S.of(context, 'invalid_amount'));
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    final success = await walletProvider.topUp(amount);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _isSuccess = true;
          _newBalance = walletProvider.balance;
          _amountController.clear();
          SuccessDialog.show(
            context,
            message:
                S.of(context, 'topup_success_msg').replaceFirst('{balance}', walletProvider.balance.toStringAsFixed(2)),
            onConfirm: () {},
          );
        } else {
          _showError(S.of(context, 'topup_failed'));
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryYellow,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
