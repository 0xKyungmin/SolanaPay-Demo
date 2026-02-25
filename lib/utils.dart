import 'package:flutter/material.dart';

class AppColors {
  static const darkText = Color(0xFF1E1E2E);
  static const purple = Color(0xFF7C3AED);
  static const green = Color(0xFF10B981);
  static const solanaGradient1 = Color(0xFF9945FF);
  static const solanaGradient2 = Color(0xFF7B3FCC);
  static const mintGradient1 = Color(0xFF14F195);
  static const mintGradient2 = Color(0xFF0EA571);
}

String shortAddress(String addr) {
  if (addr.length < 10) return addr;
  return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
}

void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1200),
      dismissDirection: DismissDirection.horizontal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

String formatAmount(String raw) {
  if (!raw.contains('.')) {
    // Add thousand separators to integer part
    final chars = raw.split('');
    final result = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) result.add(',');
      result.add(chars[i]);
    }
    return result.join();
  }
  final parts = raw.split('.');
  final intPart = formatAmount(parts[0].isEmpty ? '0' : parts[0]);
  return '$intPart.${parts[1]}';
}
