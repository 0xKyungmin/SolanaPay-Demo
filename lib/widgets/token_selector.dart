import 'package:flutter/material.dart';

import '../models/payment_request.dart';

class TokenSelector extends StatelessWidget {
  final PaymentToken selected;
  final ValueChanged<PaymentToken> onChanged;

  const TokenSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDFF),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(PaymentToken.sol, 'SOL'),
          const SizedBox(width: 4),
          _buildOption(PaymentToken.usdc, 'USDC'),
        ],
      ),
    );
  }

  Widget _buildOption(PaymentToken token, String label) {
    final isSelected = selected == token;

    return GestureDetector(
      onTap: () => onChanged(token),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
