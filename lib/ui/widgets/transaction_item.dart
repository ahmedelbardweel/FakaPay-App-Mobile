import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../../data/models/auth_models.dart';
import '../../utils/translations.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final typeUpper = transaction.type.toUpperCase();
    final descUpper = transaction.description.toUpperCase();

    // Determine if it's a credit (balance increase)
    bool isCredit = typeUpper == 'CREDIT' ||
        typeUpper == 'TOPUP' ||
        typeUpper == 'RECEIVED' ||
        descUpper.contains('TOP-UP') ||
        descUpper.contains('TOP UP') ||
        descUpper.contains('RECEIVED') ||
        descUpper.contains('تعبئة') ||
        descUpper.contains('استلام') ||
        descUpper.contains('واردة') ||
        descUpper.contains('حوالة');

    if (transaction.balanceAfter != null && transaction.balanceBefore != null) {
      isCredit = transaction.balanceAfter! > transaction.balanceBefore!;
    }

    final date = DateTime.tryParse(transaction.createdAt) ?? DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
    final color = isCredit ? AppTheme.accentOlive : AppTheme.danger;

    // Get initials for avatar
    String initials = "TX";
    if (transaction.description.isNotEmpty) {
      final parts = transaction.description.trim().split(' ');
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else {
        initials = parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
      }
    }

    return InkWell(
      onTap: () => _showTransactionDetails(context, isCredit, formattedDate, color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border.all(color: AppTheme.gray200),
          borderRadius: BorderRadius.circular(1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isCredit ? AppTheme.accentOlive : AppTheme.primaryYellow).withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.cairo(
                    color: isCredit ? AppTheme.accentOlive : AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.black,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} ${transaction.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.cairo(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'ILS',
                  style: GoogleFonts.cairo(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: AppTheme.gray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, bool isCredit, String date, Color amountColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 50),
              decoration: BoxDecoration(
                color: AppTheme.gray200,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Text(
              S.of(context, 'transaction_details'),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(S.of(context, 'value'), '${isCredit ? '+' : '-'} ${transaction.amount.toStringAsFixed(2)} ILS', valueColor: amountColor, isBold: true),
            _buildDetailRow(S.of(context, 'date'), date),
            _buildDetailRow(S.of(context, 'type'), transaction.type),
            _buildDetailRow(S.of(context, 'description'), transaction.description),
            if (transaction.reference != null) _buildDetailRow(S.of(context, 'reference'), transaction.reference!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(S.of(context, 'close')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: valueColor ?? AppTheme.black,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppTheme.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

