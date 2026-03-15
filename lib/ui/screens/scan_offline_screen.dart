import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../../data/local/database_helper.dart';
import '../../providers/wallet_provider.dart';
import '../../sync/sync_service.dart';
import 'package:intl/intl.dart';
import '../widgets/success_dialog.dart';
import '../../utils/translations.dart';
import '../widgets/shimmer_loading.dart';

class ScanOfflineScreen extends StatefulWidget {
  const ScanOfflineScreen({super.key});

  @override
  State<ScanOfflineScreen> createState() => _ScanOfflineScreenState();
}

class _ScanOfflineScreenState extends State<ScanOfflineScreen> {
  List<Map<String, dynamic>> _offlineTokens = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  int _syncedCount = 0;
  int _totalToSync = 0;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    setState(() => _isLoading = true);
    final tokens = await DatabaseHelper().getOfflineTokens();
    setState(() {
      _offlineTokens = tokens;
      _isLoading = false;
    });
  }

  Future<void> _copyAll() async {
    if (_offlineTokens.isEmpty) return;
    final text = _offlineTokens
        .map((t) => "${t['token']} | ${t['amount']} ILS")
        .join("\n");
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, 'copied_to_clipboard'))),
      );
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing || _offlineTokens.isEmpty) return;

    final snapshot = List<Map<String, dynamic>>.from(_offlineTokens);
    setState(() {
      _isSyncing = true;
      _syncedCount = 0;
      _totalToSync = snapshot.length;
    });

    final dbHelper = DatabaseHelper();
    int failedCount = 0;

    for (final t in snapshot) {
      final success = await SyncService.processSingleToken(
        t['token'] as String,
        (t['amount'] as num).toDouble(),
      );
      if (success) {
        await dbHelper.deleteOfflineToken(t['id'] as int);
        setState(() => _syncedCount++);
      } else {
        failedCount++;
      }
    }

    // Reload list and refresh server balance
    await _loadTokens();
    if (mounted) {
      await Provider.of<WalletProvider>(context, listen: false)
          .refreshWalletData();
    }

    setState(() => _isSyncing = false);

    if (mounted) {
      final msg = _syncedCount > 0
          ? '${S.of(context, 'synced_success_msg').replaceFirst('{count}', _syncedCount.toString())}${failedCount > 0 ? S.of(context, 'failed_detail_msg').replaceFirst('{count}', failedCount.toString()) : ''}'
          : S.of(context, 'failed_sync_msg');
      SuccessDialog.show(context, message: msg, onConfirm: () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _offlineTokens.length;

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: Text(
          S.of(context, 'offline_tokens'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: AppTheme.offlineAmber,
            child: Text(
              S.of(context, 'offline_mode_no_internet'),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    pendingCount > 0
                        ? S
                            .of(context, 'pending_transfers_msg')
                            .replaceFirst('{count}', pendingCount.toString())
                        : S.of(context, 'all_synced_msg'),
                    style: GoogleFonts.cairo(
                        color: AppTheme.gray400, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: _copyAll,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        S.of(context, 'copy_all_backup'),
                        style: GoogleFonts.cairo(
                          color: AppTheme.primaryYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? ListView.builder(
                            itemCount: 5,
                            itemBuilder: (context, index) =>
                                const OfflineTokenShimmer(),
                          )
                        : _offlineTokens.isEmpty
                            ? Center(
                                child: Text(
                                    S.of(context, 'no_pending_transfers'),
                                    style: GoogleFonts.cairo(
                                        color: AppTheme.gray400)),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadTokens,
                                color: AppTheme.primaryYellow,
                                child: ListView.separated(
                                  itemCount: _offlineTokens.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 1),
                                  itemBuilder: (ctx, i) =>
                                      _buildTokenItem(_offlineTokens[i]),
                                ),
                              ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed:
                          _isSyncing || pendingCount == 0 ? null : _syncNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.offlineAmber,
                        foregroundColor: AppTheme.white,
                        disabledBackgroundColor: AppTheme.gray200,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      ),
                      child: _isSyncing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.black),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  S
                                      .of(context, 'syncing_msg')
                                      .replaceFirst(
                                          '{count}', _syncedCount.toString())
                                      .replaceFirst(
                                          '{total}', _totalToSync.toString()),
                                  style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : Text(
                              pendingCount > 0
                                  ? S
                                      .of(context, 'sync_now_with_count')
                                      .replaceFirst(
                                          '{count}', pendingCount.toString())
                                  : S.of(context, 'synced_check'),
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenItem(Map<String, dynamic> tokenData) {
    String formattedDate = "";
    try {
      final date = DateTime.parse(tokenData['created_at']);
      formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (_) {
      formattedDate = tokenData['created_at'] ?? "";
    }

    final token = tokenData['token'] ?? "";
    final displayToken =
        token.length > 15 ? "${token.substring(0, 12)}..." : token;
    final amount = tokenData['amount'] ?? 0.0;

    return Container(
      color: AppTheme.gray100,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: AppTheme.offlineAmber),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S
                          .of(context, 'token_label')
                          .replaceFirst('{token}', displayToken),
                      style: GoogleFonts.cairo(
                          color: AppTheme.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    Text(
                      '$amount ILS  •  $formattedDate',
                      style: GoogleFonts.cairo(
                          color: AppTheme.gray400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Text(
                S.of(context, 'pending'),
                style: GoogleFonts.cairo(
                    color: AppTheme.offlineAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
