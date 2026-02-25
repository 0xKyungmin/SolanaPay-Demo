import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../models/payment_request.dart';

class MerchantSuccessScreen extends StatefulWidget {
  const MerchantSuccessScreen({super.key});

  @override
  State<MerchantSuccessScreen> createState() => _MerchantSuccessScreenState();
}

class _MerchantSuccessScreenState extends State<MerchantSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final signature = args['signature'] as String;
    final amount = args['amount'] as double;
    final token = args['token'] as PaymentToken;
    final symbol = token == PaymentToken.sol ? 'SOL' : 'USDC';
    final shortSig = '${signature.substring(0, 8)}...${signature.substring(signature.length - 8)}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Checkmark
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                '결제 완료!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${amount.toStringAsFixed(token == PaymentToken.sol ? 4 : 2)} $symbol',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 28),

              // Tx info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '트랜잭션',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shortSig,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: Color(0xFF1E1E2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _openExplorer(signature),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF9945FF)),
                            SizedBox(width: 8),
                            Text('Solana Explorer에서 보기', style: TextStyle(color: Color(0xFF9945FF), fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // New Payment
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/merchant/amount',
                      (route) => route.isFirst,
                      arguments: {'walletAddress': args['recipient']},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '새 결제 받기',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openExplorer(String signature) async {
    final url = Uri.parse(explorerUrl(signature));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
