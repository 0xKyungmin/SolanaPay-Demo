import 'package:flutter/material.dart';

import '../../config.dart';
import '../../models/payment_request.dart';
import '../../utils.dart';
import '../../widgets/token_selector.dart';

class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key});

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  String _amountStr = '0';
  PaymentToken _token = PaymentToken.sol;
  late TextEditingController _recipientController;
  String _recipientLabel = '내 지갑';
  List<SavedAddress> _resolvedAddresses = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final walletAddr = args?['walletAddress'] as String? ?? '';
    _recipientController = TextEditingController(text: walletAddr);
    _buildResolvedAddresses(walletAddr);
  }

  void _buildResolvedAddresses(String walletAddr) {
    _resolvedAddresses = savedAddresses.map((a) {
      if (a.name == '내 지갑' && a.address.isEmpty) {
        return SavedAddress(name: a.name, address: walletAddr);
      }
      return a;
    }).toList();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    setState(() {
      if (_amountStr == '0' && digit != '.') {
        _amountStr = digit;
      } else if (digit == '.' && _amountStr.contains('.')) {
        return;
      } else {
        // Limit decimal places
        if (_amountStr.contains('.')) {
          final decimals = _amountStr.split('.')[1].length;
          final maxDecimals = _token == PaymentToken.sol ? 9 : 6;
          if (decimals >= maxDecimals) return;
        }
        _amountStr += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amountStr.length <= 1) {
        _amountStr = '0';
      } else {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      }
    });
  }

  void _showRecipientDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final inputController = TextEditingController(text: _recipientController.text);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx2, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).viewPadding.bottom + 24,
              ),
              child: ListView(
                controller: scrollController,
                shrinkWrap: true,
                children: [
                  const Text(
                    '수신자 주소 (To)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E1E2E)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: inputController,
                    decoration: InputDecoration(
                      hintText: 'Solana 주소 입력...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF9945FF), width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // 저장된 주소 목록
                  if (_resolvedAddresses.isNotEmpty) ...[
                    Text('저장된 주소', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._resolvedAddresses.where((a) => a.address.isNotEmpty).map((addr) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(addr.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          shortAddress(addr.address),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          _recipientController.text = addr.address;
                          setState(() => _recipientLabel = addr.name);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        _recipientController.text = inputController.text.trim();
                        setState(() => _recipientLabel = '직접 입력');
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9945FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('확인', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onGenerate() {
    final amount = double.tryParse(_amountStr);
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, '금액을 입력해주세요');
      return;
    }
    if (_recipientController.text.trim().isEmpty) {
      showAppSnackBar(context, '수신자 주소를 입력해주세요');
      return;
    }
    Navigator.pushNamed(context, '/merchant/qr', arguments: {
      'amount': amount,
      'token': _token,
      'recipient': _recipientController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final symbol = _token == PaymentToken.sol ? 'SOL' : 'USDC';
    final shortRecipient = shortAddress(_recipientController.text);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('QR 생성')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Recipient address
              GestureDetector(
                onTap: _showRecipientDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF9945FF)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('수신자 (To)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          Text(
                            '$_recipientLabel  $shortRecipient',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1E2E)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Token selector
              TokenSelector(selected: _token, onChanged: (t) => setState(() => _token = t)),
              const SizedBox(height: 16),

              // Amount
              Text(
                formatAmount(_amountStr),
                style: const TextStyle(color: Color(0xFF1E1E2E), fontSize: 44, fontWeight: FontWeight.w300, letterSpacing: -1),
              ),
              const SizedBox(height: 2),
              Text(symbol, style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),

              // Keypad
              Expanded(child: _buildKeypad()),

              // Generate QR
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9945FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('QR 코드 생성', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '<'],
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _buildKey(key),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    return GestureDetector(
      onTap: () => key == '<' ? _onBackspace() : _onDigit(key),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: key == '<'
            ? Icon(Icons.backspace_outlined, color: Colors.grey.shade500, size: 22)
            : Text(key, style: const TextStyle(color: Color(0xFF1E1E2E), fontSize: 24, fontWeight: FontWeight.w400)),
      ),
    );
  }
}
