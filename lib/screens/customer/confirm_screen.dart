import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../../models/payment_request.dart';
import '../../services/solana_service.dart';
import '../../utils.dart';

class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  final _solanaService = SolanaService.instance;
  double _solBalance = 0;
  double _usdcBalance = 0;
  bool _loadingBalance = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final customer = await loadCustomerWallet();
      final results = await Future.wait([
        _solanaService.getSolBalance(customer.address),
        _solanaService.getUsdcBalance(customer.address),
      ]);
      if (mounted) {
        setState(() {
          _solBalance = results[0];
          _usdcBalance = results[1];
          _loadingBalance = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBalance = false);
    }
  }

  Future<void> _pay(PaymentRequest payment) async {
    if (payment.token == PaymentToken.sol && _solBalance < payment.amount) {
      showAppSnackBar(context, 'SOL 잔액이 부족합니다');
      return;
    }
    if (payment.token == PaymentToken.usdc && _usdcBalance < payment.amount) {
      showAppSnackBar(context, 'USDC 잔액이 부족합니다');
      return;
    }

    setState(() => _sending = true);
    try {
      final customer = await loadCustomerWallet();
      String signature;

      if (payment.isSol) {
        signature = await _solanaService.transferSol(
          sender: customer,
          recipientAddress: payment.recipient,
          lamports: payment.lamports,
          referenceAddress: payment.reference,
        );
      } else {
        signature = await _solanaService.transferUsdc(
          sender: customer,
          recipientAddress: payment.recipient,
          amount: payment.usdcRawAmount,
          referenceAddress: payment.reference,
        );
      }

      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/customer/sent',
          arguments: {'signature': signature},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        showAppSnackBar(context, '전송 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = ModalRoute.of(context)?.settings.arguments as PaymentRequest?;
    if (payment == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
      return const SizedBox.shrink();
    }
    final shortRecipient = shortAddress(payment.recipient);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('송금 확인')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Payment card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: payment.isSol
                        ? [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
                        : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (payment.isSol ? const Color(0xFF7C3AED) : const Color(0xFF2563EB))
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '보내는 금액',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${payment.amount.toStringAsFixed(payment.isSol ? 4 : 2)} ${payment.tokenSymbol}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '받는 사람: $shortRecipient',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    if (payment.label.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        payment.label,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Balance card
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 잔액',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingBalance)
                      const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                        ),
                      )
                    else
                      Row(
                        children: [
                          _buildBalanceChip('SOL', _solBalance.toStringAsFixed(4)),
                          const SizedBox(width: 12),
                          _buildBalanceChip('USDC', _usdcBalance.toStringAsFixed(2)),
                        ],
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Pay button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _sending ? null : () => _pay(payment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '결제하기',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E1E2E),
        ),
      ),
    );
  }
}
