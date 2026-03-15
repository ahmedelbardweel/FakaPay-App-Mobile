import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../theme.dart';
import '../../data/api/api_service.dart';
import '../widgets/success_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/translations.dart';
import '../widgets/shimmer_loading.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _amountController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedToken;
  bool _isPolling = false;
  Timer? _pollingTimer;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          S.of(context, 'send_money'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10), // android:padding="10dp"
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_generatedToken == null) ...[
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
                // Generate Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateQr,
                    child: _isGenerating
                        ? const Center(
                            child: ShimmerLoading.rectangular(
                                height: 280, width: double.infinity))
                        : Text(S.of(context, 'generate_qr')),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                // QR Card
                Center(
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: AppTheme.primaryYellow, width: 4),
                    ),
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        color: AppTheme.white, // Ensure white background for the capture
                        child: QrImageView(
                          data: _generatedToken!,
                          version: QrVersions.auto,
                          size: 240.0,
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Download Button
                SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _downloadQrCode,
                    icon: const Icon(Icons.arrow_downward,
                        color: Colors.white, size: 24),
                    label: Text(S.of(context, 'download')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Token Copy Container
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _generatedToken!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context, "token_copied"))),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _generatedToken!.length > 20
                              ? '${_generatedToken!.substring(0, 20)}...'
                              : _generatedToken!,
                          style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.black,
                        fontWeight: FontWeight.w700,
                      ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.content_copy,
                            size: 16, color: AppTheme.gray400),
                      ],
                    ),
                  ),
                ),
                if (_isPolling) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      S.of(context, 'waiting_for_payment'),
                      style: GoogleFonts.cairo(
                        color: AppTheme.primaryYellow,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateQr() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isGenerating = true);

    try {
      final apiService = ApiService();
      final response = await apiService.createTransfer(amount);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dataStr = response.data['data'];
        final String? token =
            dataStr != null ? dataStr['token'] : response.data['token'];

        if (token != null) {
          setState(() {
            _generatedToken = token;
            _isGenerating = false;
            _isPolling = true;
          });
          _startPolling();
        } else {
          throw 'Missing token in response';
        }
      } else {
        throw response.data['message'] ?? 'Failed to create transfer';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isGenerating = false);
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_generatedToken == null) {
        timer.cancel();
        return;
      }
      try {
        final apiService = ApiService();
        final response = await apiService.checkStatus(_generatedToken!);
        final data = response.data['data'] ?? response.data;

        if (data['status'] == 'completed' || data['status'] == 'success') {
          timer.cancel();
          if (mounted) {
            setState(() => _isPolling = false);
            Provider.of<WalletProvider>(context, listen: false)
                .refreshWalletData();
            SuccessDialog.show(
              context,
              message: S.of(context, 'payment_received_success'),
              onConfirm: () => Navigator.pop(context),
            );
          }
        }
      } catch (e) {
        // Ignore network/server errors during polling
      }
    });
  }

  Future<void> _downloadQrCode() async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final Map result = await ImageGallerySaverPlus.saveImage(
          image,
          quality: 100,
          name: "FakaPay_QR_${DateTime.now().millisecondsSinceEpoch}",
        );
        
        if (mounted && (result['isSuccess'] == true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context, "qr_saved_to_gallery")),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (mounted) {
          throw result['errorMessage'] ?? 'Failed to save image';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
