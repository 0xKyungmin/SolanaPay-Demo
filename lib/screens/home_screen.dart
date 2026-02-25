import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/brand.dart';
import '../services/settings_service.dart';
import '../services/solana_service.dart';
import '../config.dart';
import '../utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _solanaService = SolanaService.instance;
  int _walletIndex = 0; // 0 = 지갑#1 (고객), 1 = 지갑#2 (판매자)
  final List<String> _addresses = ['', ''];
  final List<double> _solBalances = [0, 0];
  final List<double> _usdcBalances = [0, 0];
  bool _loading = true;
  bool _hasError = false;

  String get _walletAddress => _addresses[_walletIndex];
  String get _merchantAddress => _addresses[1]; // 항상 #2가 판매자
  double get _sol => _solBalances[_walletIndex];
  double get _usdc => _usdcBalances[_walletIndex];

  Brand get _brand => SettingsService.instance.selectedBrand;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _loading = true);
    try {
      final wallet = await loadWallet();
      final merchant = await loadMerchantWallet();
      _addresses[0] = wallet.address;
      _addresses[1] = merchant.address;

      final results = await Future.wait([
        _solanaService.getSolBalance(wallet.address),
        _solanaService.getUsdcBalance(wallet.address),
        _solanaService.getSolBalance(merchant.address),
        _solanaService.getUsdcBalance(merchant.address),
      ]);

      if (mounted) {
        setState(() {
          _solBalances[0] = results[0];
          _usdcBalances[0] = results[1];
          _solBalances[1] = results[2];
          _usdcBalances[1] = results[3];
          _loading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  void _toggleWallet() {
    setState(() => _walletIndex = _walletIndex == 0 ? 1 : 0);
  }

  Future<void> _openSettings() async {
    final result = await Navigator.pushNamed(context, '/settings');
    if (result == true && mounted) {
      setState(() {}); // rebuild with new brand
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header: [Brand Logo] x [Solana Logo] + Title
              Row(
                children: [
                  // Brand logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _brand.logoAsset,
                      width: 40,
                      height: 40,
                      errorBuilder: (c, e, s) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _brand.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _brand.displayName[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
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
                          _brand.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1E2E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Devnet',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Wallet card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _brand.primaryColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleWallet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _brand.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '지갑 #${_walletIndex + 1}',
                                  style: TextStyle(color: _brand.primaryColor, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.swap_horiz_rounded, size: 16, color: _brand.primaryColor.withValues(alpha: 0.6)),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _walletAddress));
                            showAppSnackBar(context, '지갑 주소 복사됨');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  shortAddress(_walletAddress),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontFamily: 'monospace'),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.copy_rounded, size: 12, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_loading)
                      Center(child: CircularProgressIndicator(color: _brand.primaryColor, strokeWidth: 2))
                    else if (_hasError)
                      GestureDetector(
                        onTap: _loadWallet,
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, size: 16, color: Colors.red.shade300),
                            const SizedBox(width: 6),
                            Text('네트워크 오류', style: TextStyle(fontSize: 13, color: Colors.red.shade300)),
                            const SizedBox(width: 4),
                            Text('탭하여 재시도', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          _buildBalanceItem('SOL', _sol.toStringAsFixed(4)),
                          const SizedBox(width: 32),
                          _buildBalanceItem('USDC', _usdc.toStringAsFixed(2)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _loadWallet,
                            child: Icon(Icons.refresh_rounded, size: 20, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                '무엇을 하시겠어요?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E1E2E)),
              ),
              const SizedBox(height: 16),

              // QR 생성 (Generate QR - Solana Pay)
              _buildActionCard(
                icon: Icons.qr_code_rounded,
                title: 'QR 생성',
                subtitle: 'Solana Pay QR 코드 생성',
                gradient: [const Color(0xFF9945FF), const Color(0xFF7B3FCC)],
                onTap: () => Navigator.pushNamed(
                  context,
                  '/merchant/amount',
                  arguments: {'walletAddress': _merchantAddress},
                ),
              ),
              const SizedBox(height: 12),

              // QR 촬영 (Scan QR)
              _buildActionCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'QR 촬영',
                subtitle: 'QR 코드 스캔 후 결제',
                gradient: [const Color(0xFF14F195), const Color(0xFF0EA571)],
                textColor: const Color(0xFF1E1E2E),
                onTap: () => Navigator.pushNamed(context, '/customer/scan'),
              ),

              const Spacer(),

              // Powered by Solana → Settings
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: _openSettings,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/logos/solana.png', width: 16, height: 16,
                            errorBuilder: (c, e, s) => const Icon(Icons.currency_bitcoin, size: 16)),
                          const SizedBox(width: 6),
                          Text(
                            'Powered by Solana  •  Devnet',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF1E1E2E), fontSize: 24, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: textColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E1E2E))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 18),
          ],
        ),
      ),
    );
  }
}
