import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:solana/solana.dart';

import '../../config.dart';
import '../../models/payment_request.dart';
import '../../services/solana_pay.dart';
import '../../services/solana_service.dart';
import '../../utils.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _solanaService = SolanaService.instance;
  final _cancelled = ValueNotifier(false);
  String? _payUrl;
  String? _referenceAddress;
  String? _merchantAddress;
  bool _polling = false;
  bool _demoPaying = false;

  late final double _amount;
  late final PaymentToken _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_payUrl == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _amount = args['amount'] as double;
      _token = args['token'] as PaymentToken;
      _generateQr();
    }
  }

  @override
  void dispose() {
    _cancelled.value = true;
    _cancelled.dispose();
    super.dispose();
  }

  Future<void> _generateQr() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final recipient = args['recipient'] as String;
    final reference = await Ed25519HDKeyPair.random();

    final url = buildSolanaPayUrl(
      recipient: recipient,
      amount: _amount,
      token: _token,
      reference: reference.address,
    );

    setState(() {
      _payUrl = url;
      _referenceAddress = reference.address;
      _merchantAddress = recipient;
    });

    _startPolling();
  }

  void _startPolling() {
    if (_polling) return;
    _polling = true;

    _solanaService.pollForPayment(_referenceAddress!, cancelled: _cancelled).then((signature) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/merchant/success', arguments: {
          'signature': signature,
          'amount': _amount,
          'token': _token,
          'recipient': _merchantAddress,
        });
      }
    }).catchError((_) {
      if (mounted) {
        showAppSnackBar(context, '결제 대기 시간이 초과되었습니다');
      }
    });
  }

  Future<void> _demoPay() async {
    setState(() => _demoPaying = true);
    try {
      final customer = await loadCustomerWallet();
      String signature;

      if (_token == PaymentToken.sol) {
        signature = await _solanaService.transferSol(
          sender: customer,
          recipientAddress: _merchantAddress!,
          lamports: (_amount * 1e9).round(),
          referenceAddress: _referenceAddress!,
        );
      } else {
        signature = await _solanaService.transferUsdc(
          sender: customer,
          recipientAddress: _merchantAddress!,
          amount: (_amount * 1e6).round(),
          referenceAddress: _referenceAddress!,
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/merchant/success', arguments: {
          'signature': signature,
          'amount': _amount,
          'token': _token,
          'recipient': _merchantAddress,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _demoPaying = false);
        showAppSnackBar(context, '데모 결제 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = _token == PaymentToken.sol ? 'SOL' : 'USDC';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('QR 코드')),
      body: SafeArea(
        child: _payUrl == null
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Amount
                    Text(
                      '${_amount.toStringAsFixed(_token == PaymentToken.sol ? 4 : 2)} $symbol',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      merchantLabel,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 24),

                    // QR Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _payUrl!,
                        version: QrVersions.auto,
                        size: 240,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: Color(0xFF7C3AED),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Color(0xFF1E1E2E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Waiting indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 8),
                        Text('결제 대기 중...', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Demo Pay
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _demoPaying ? null : _demoPay,
                        icon: _demoPaying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                              )
                            : const Icon(Icons.flash_on_rounded, size: 20),
                        label: Text(
                          _demoPaying ? '전송 중...' : '데모 결제',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
}
