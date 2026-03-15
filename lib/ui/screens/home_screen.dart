import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../widgets/transaction_item.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../sync/sync_service.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'topup_screen.dart';
import 'send_screen.dart';
import 'scan_screen.dart';
import 'scan_offline_screen.dart';
import '../../utils/translations.dart';
import '../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedFilter = 'all';
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      // First load — show whatever is cached / last known
      await walletProvider.refreshWalletData();

      // Silently sync any pending offline tokens
      final anySynced = await SyncService.syncOnLogin();

      // If we synced something, refresh balance from server
      if (anySynced && mounted) {
        await walletProvider.refreshWalletData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title:  Text(
          S.of(context, 'app_name'),
          style: GoogleFonts.cairo(
            color: AppTheme.black,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: const [],
      ),
      drawer: _buildDrawer(authProvider),
      body: Stack(
        children: [
          // Aesthetic Background Blobs
          PositionedDirectional(
            top: -100,
            end: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(0.1),
              ),
            ),
          ),
          PositionedDirectional(
            top: 200,
            start: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.offlineAmber.withOpacity(0.05),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () => walletProvider.refreshWalletData(),
            color: AppTheme.primaryYellow,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User Info Card with Glassmorphism
                        ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: AppTheme.glassBlurSigma,
                                sigmaY: AppTheme.glassBlurSigma),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: AppTheme.glassDecoration(
                                opacity: 0.2, // Slightly more visible glass
                                borderRadius: 16,
                                borderOpacity: 0.3,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final iban = walletProvider.iban ??
                                              walletProvider.updatedUser?.iban ??
                                              authProvider.user?.iban;

                                          if (iban != null && iban.isNotEmpty) {
                                            Clipboard.setData(
                                                ClipboardData(text: iban));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(S.of(context,
                                                    'copied_to_clipboard')),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                backgroundColor: AppTheme.black,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(S.of(context,
                                                    'iban_not_available')),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Icon(Icons.copy_rounded,
                                            size: 18),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        color: AppTheme.accentOlive,
                                        child: Text(
                                          S.of(context, 'default'),
                                          style: GoogleFonts.cairo(
                                               color: Colors.white,
                                               fontSize: 11), // Slightly smaller but closer to 13
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    S.of(context, 'user_info_title'),
                                    textAlign: TextAlign.start,
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: AppTheme.black,
                                        letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildInfoRow(
                                      context,
                                      S.of(context, 'full_name'),
                                      walletProvider.updatedUser?.name ??
                                          authProvider.user?.name ??
                                          '---'),
                                  _buildInfoRow(
                                      context,
                                      S.of(context, 'mobile_number'),
                                      walletProvider.updatedUser?.phone ??
                                          authProvider.user?.phone ??
                                          '---'),
                                  _buildInfoRow(
                                      context,
                                      S.of(context, 'email'),
                                      walletProvider.updatedUser?.email ??
                                          authProvider.user?.email ??
                                          '---'),
                                  _buildInfoRow(
                                      context,
                                      S.of(context, 'wallet_name'),
                                      S.of(context, 'app_name')),
                                  _buildInfoRow(
                                      context,
                                      S.of(context, 'wallet_balance'),
                                      '${walletProvider.balance.toStringAsFixed(2)} ${S.of(context, 'amount_ils')}'),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.gray200),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.primaryYellow),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.gray200),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Services section
                        Text(
                          S.of(context, 'services'),
                          textAlign: TextAlign.start,
                           style: GoogleFonts.cairo(
                               fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildServiceItem(
                                S.of(context, 'send'),
                                Icons.call_made,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SendScreen()))),
                            _buildServiceItem(
                                S.of(context, 'request'),
                                Icons.call_received,
                                () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ScanScreen()))),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Last Transactions Title
                        Text(
                          S.of(context, 'last_transactions'),
                          textAlign: TextAlign.start,
                          style: GoogleFonts.cairo(
                              color: AppTheme.black,
                               fontWeight: FontWeight.w900,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                // Transactions List
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 50),
                  sliver: walletProvider.isLoading &&
                          walletProvider.transactions.isEmpty
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => const TransactionShimmer(),
                            childCount: 5,
                          ),
                        )
                      : _filteredTransactions(walletProvider).isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Center(
                                    child: Text(
                                        S.of(context, 'no_transactions'))),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final tx = _filteredTransactions(
                                      walletProvider)[index];
                                  return TransactionItem(transaction: tx);
                                },
                                childCount:
                                    _filteredTransactions(walletProvider)
                                        .length,
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            textAlign: TextAlign.start,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.gray500, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w800, // Explicitly heavy for iPhone style
                color: AppTheme.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryYellow.withOpacity(0.1),
            ),
            child: Icon(icon, color: AppTheme.primaryYellow, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required EdgeInsets margin,
  }) {
    return Container(
      margin: margin,
      child: MaterialButton(
        onPressed: onPressed,
        elevation: 0,
        highlightElevation: 0,
        color: AppTheme.gray100,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppTheme.gray200, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.black, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: AppTheme.black,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _filteredTransactions(WalletProvider walletProvider) {
    final all = walletProvider.transactions;
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        return all.where((tx) {
          try {
            final d = DateTime.parse(tx.createdAt);
            return d.year == now.year &&
                d.month == now.month &&
                d.day == now.day;
          } catch (_) {
            return false;
          }
        }).toList();
      case 'this_week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return all.where((tx) {
          try {
            final d = DateTime.parse(tx.createdAt);
            return d.isAfter(weekStart.subtract(const Duration(seconds: 1)));
          } catch (_) {
            return false;
          }
        }).toList();
      case 'this_month':
        return all.where((tx) {
          try {
            final d = DateTime.parse(tx.createdAt);
            return d.year == now.year && d.month == now.month;
          } catch (_) {
            return false;
          }
        }).toList();
      case 'this_year':
        return all.where((tx) {
          try {
            final d = DateTime.parse(tx.createdAt);
            return d.year == now.year;
          } catch (_) {
            return false;
          }
        }).toList();
      case 'custom':
        if (_customDateRange == null) return all;
        return all.where((tx) {
          try {
            final d = DateTime.parse(tx.createdAt);
            final start = _customDateRange!.start;
            final end = _customDateRange!.end.add(const Duration(days: 1));
            return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
                d.isBefore(end);
          } catch (_) {
            return false;
          }
        }).toList();
      default:
        return all;
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryYellow,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'custom';
      });
    }
  }

  Widget _buildFilterChip(String labelKey) {
    final String label = S.of(context, labelKey);
    final isSelected = _selectedFilter == label || _selectedFilter == labelKey;
    final isCustom = labelKey == 'custom';

    String displayLabel = label;
    if (isCustom && _customDateRange != null && isSelected) {
      final s = _customDateRange!.start;
      final e = _customDateRange!.end;
      displayLabel = '${s.day}/${s.month} – ${e.day}/${e.month}';
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8.0),
      child: ChoiceChip(
        label: Text(displayLabel),
        selected: isSelected,
        onSelected: (selected) {
          if (isCustom) {
            _pickCustomRange();
          } else if (selected) {
            setState(() {
              _selectedFilter = labelKey;
              _customDateRange = null;
            });
          }
        },
        backgroundColor: const Color(0xFFF9FAFB),
        selectedColor: AppTheme.primaryYellow.withOpacity(0.15),
        side: isSelected
            ? BorderSide(
                color: AppTheme.primaryYellow.withOpacity(0.5), width: 1)
            : const BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
        labelStyle: GoogleFonts.cairo(
          color: isSelected ? AppTheme.primaryYellow : AppTheme.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }

  Widget _buildDrawer(AuthProvider authProvider) {
    return Drawer(
      backgroundColor: AppTheme.white,
      child: Column(
        children: [
          // Header - email only
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
            color: AppTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.user?.email ?? '',
                  style: GoogleFonts.cairo(
                    color: AppTheme.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFE5E7EB), height: 1),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    S.of(context, 'services'),
                    style: GoogleFonts.cairo(
                      color: AppTheme.gray400,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.call_received,
                  label: S.of(context, 'request'),
                  subtitle: S.of(context, 'scan_qr'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ScanScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.call_made,
                  label: S.of(context, 'send'),
                  subtitle: S.of(context, 'send'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SendScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_circle_outline,
                  label: S.of(context, 'topup'),
                  subtitle: S.of(context, 'topup'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const TopupScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.qr_code_scanner,
                  label: S.of(context, 'offline_scanner'),
                  subtitle: S.of(context, 'offline_scanner'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScanScreen(isOffline: true)));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.cloud_sync_outlined,
                  label: S.of(context, 'sync_queue'),
                  subtitle: S.of(context, 'sync_queue'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScanOfflineScreen()));
                  },
                ),

                const Divider(color: Color(0xFFE5E7EB), height: 15),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    S.of(context, 'account'),
                    style: GoogleFonts.cairo(
                      color: AppTheme.gray400,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  label: S.of(context, 'settings'),
                  subtitle: S.of(context, 'settings'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
                _buildDrawerItem(
                  icon: Icons.sync_rounded,
                  label: S.of(context, 'instant_sync'),
                  subtitle: S.of(context, 'schedule_sync_desc'),
                  onTap: () {
                    SyncService().scheduleSync();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context, 'sync_scheduled'))),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout
          const Divider(color: Color(0xFFE5E7EB), height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            title: Text(S.of(context, 'logout'),
                style: const TextStyle(
                    color: AppTheme.danger, fontWeight: FontWeight.bold)),
            onTap: () {
              authProvider.logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.black, size: 22),
      title: Text(label,
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppTheme.black)),
      subtitle: Text(subtitle,
          style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.gray400)),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    );
  }
}
