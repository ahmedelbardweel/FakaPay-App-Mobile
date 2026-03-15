import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../../providers/wallet_provider.dart';
import '../../data/api/api_service.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/auth_models.dart' as models;
import '../../utils/translations.dart';
import '../widgets/success_dialog.dart';

class ScanScreen extends StatefulWidget {
  final bool isOffline;
  const ScanScreen({super.key, this.isOffline = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _tokenController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isManualEntry = false;
  final bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: Text(
          widget.isOffline ? S.of(context, 'offline_pay') : S.of(context, 'scan_qr'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isOffline)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: AppTheme.offlineAmber,
                      child: Text(
                        S.of(context, 'offline_mode_no_internet'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
            // Camera Preview Section
            Expanded(
              child: ClipRect(
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            _scannerController.stop();
                            _showAmountDialog(barcode.rawValue!);
                            break;
                          }
                        }
                      },
                    ),
                    // Scanner Overlay (Only on camera area)
                    if (!_isManualEntry)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: const ShapeDecoration(
                              shape: QrScannerOverlayShape(
                                borderColor: AppTheme.primaryYellow,
                                borderRadius: 0,
                                borderLength: 30,
                                borderWidth: 10,
                                cutOutSize: 250,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Controls
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: S.of(context, 'manual_entry'),
                      hintText: S.of(context, 'enter_token_here'),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isManualEntry = value.isNotEmpty;
                        if (_isManualEntry) {
                          _scannerController.stop();
                        } else {
                          _scannerController.start();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processManualToken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: AppTheme.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.white),
                                ),
                                SizedBox(width: 8),
                                Text('Processing...'), // Placeholder for loading text
                              ],
                            )
                          : Text(S.of(context, 'verify_token')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.image, color: AppTheme.black),
                      label: Text(S.of(context, 'gallery')),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.gray100,
                        foregroundColor: AppTheme.black,
                        side:
                            const BorderSide(color: AppTheme.gray200, width: 1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processManualToken() {
    final token = _tokenController.text.trim();
    if (token.isNotEmpty) {
      _showAmountDialog(token);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && mounted) {
      setState(() => _isManualEntry = true); // Hide camera while processing
      try {
        final BarcodeCapture? capture =
            await _scannerController.analyzeImage(image.path);
        if (capture == null || capture.barcodes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context, 'no_qr_found'))),
            );
            setState(() => _isManualEntry = false);
          }
        } else {
          // Process the first found barcode
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null && mounted) {
             _showAmountDialog(barcode.rawValue!);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
          setState(() => _isManualEntry = false);
        }
      }
    }
  }

  void _showAmountDialog(String token) {
    if (token.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final amountController = TextEditingController();
        bool isProcessingLocal = false;

        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.white,
            surfaceTintColor: Colors.transparent,
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            insetPadding: const EdgeInsets.symmetric(horizontal: 10),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  S.of(context, 'enter_amount'),
                  style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.black,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context, 'how_much_to_send'),
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppTheme.gray500,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: amountController,
                  cursorWidth: 250,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.black,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20),
                    suffixText: S.of(context, 'amount_ils').trim(),
                    suffixStyle: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray500,
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  enabled: !isProcessingLocal,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed:
                          isProcessingLocal ? null : () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        S.of(context, 'cancel'),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppTheme.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: isProcessingLocal
                          ? null
                          : () async {
                              final amt =
                                  double.tryParse(amountController.text);
                              if (amt != null && amt > 0) {
                                setDialogState(() => isProcessingLocal = true);
                                final String? successMessage =
                                    await _processTokenInternal(token, amt);
                                if (successMessage != null && mounted) {
                                  Navigator.pop(ctx);
                                  _onSuccess(successMessage);
                                } else {
                                  setDialogState(
                                      () => isProcessingLocal = false);
                                }
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: isProcessingLocal
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.black,
                              ),
                            )
                          : Text(
                              S.of(context, 'confirm'),
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppTheme.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<String?> _processTokenInternal(String token, double amount) async {
    if (widget.isOffline) {
      await DatabaseHelper().insertOfflineToken(token, amount);
      // Immediately reflect the deduction in the UI
      if (mounted) {
        Provider.of<WalletProvider>(context, listen: false)
            .deductBalance(amount);
      }
      return S.of(context, 'save_offline_pending');
    }

    final apiService = ApiService();
    try {
      final response = await apiService.processTransfer(token, amount);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Provider.of<WalletProvider>(context, listen: false)
              .refreshWalletData();
        }
        return S.of(context, 'operation_success');
      } else {
        _onError('خطأ: ${response.data['message'] ?? 'خطأ غير معروف'}');
        return null;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        _onError('${e.response?.data['message'] ?? 'خطأ في الشبكة'}');
      } else {
        await _captureOffline(token, amount);
        return S.of(context, 'save_offline_network_fail');
      }
      return null;
    } catch (e) {
      _onError('Error: $e');
      return null;
    }
  }

  void _onError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  Future<void> _captureOffline(String token, double amount) async {
    final dbHelper = DatabaseHelper();
    final tx = models.Transaction(
      description: S.of(context, 'offline_transfer_description'),
      type: 'DEBIT',
      amount: amount,
      createdAt: DateTime.now().toIso8601String(),
      reference: token,
    );

    // Queue for sync
    await dbHelper.insertOfflineToken(token, amount);
    // Show in history
    await dbHelper.insertTransaction(tx);
  }

  void _onSuccess(String message) {
    if (!mounted) return;
    Navigator.pop(context);
    SuccessDialog.show(
      context,
      message: message,
      onConfirm: () {},
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 8.0,
    this.borderRadius = 0,
    this.borderLength = 40.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final center = Offset(rect.left + width / 2, rect.top + height / 2);
    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              cutOutRect, Radius.circular(borderRadius))),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.square; // Geometric precision

    final path = Path();

    // Top left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    if (borderRadius > 0) {
      path.arcToPoint(Offset(cutOutRect.left + borderRadius, cutOutRect.top),
          radius: Radius.circular(borderRadius));
    } else {
      path.lineTo(cutOutRect.left, cutOutRect.top);
      path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);
    }
    path.moveTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);
    path.moveTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderLength);

    // Top right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom left
    path.moveTo(cutOutRect.left, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.bottom);

    // Bottom right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
        borderColor: borderColor,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
        borderLength: borderLength,
        cutOutSize: cutOutSize,
      );
}
