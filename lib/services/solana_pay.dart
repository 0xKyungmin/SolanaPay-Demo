import '../config.dart';
import '../models/payment_request.dart';

/// Build a Solana Pay URL from payment parameters.
/// Format: `solana:{recipient}?amount={amt}&spl-token={mint}&reference={ref}&label={label}`
String buildSolanaPayUrl({
  required String recipient,
  required double amount,
  required PaymentToken token,
  required String reference,
  String? label,
}) {
  // Format amount with fixed decimals to avoid floating-point artifacts
  final rawAmount = token == PaymentToken.sol
      ? amount.toStringAsFixed(9)
      : amount.toStringAsFixed(6);
  // Remove trailing zeros: "1.500000" → "1.5", "1.000000" → "1"
  final cleanAmount = rawAmount.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

  // Build query without encoding keys/values that are already URL-safe
  // (base58 addresses, numbers). Only encode label (may contain non-ASCII).
  final parts = <String>[
    'amount=$cleanAmount',
    if (token == PaymentToken.usdc) 'spl-token=$usdcMintAddress',
    'reference=$reference',
    'label=${Uri.encodeComponent(label ?? merchantLabel)}',
  ];
  return 'solana:$recipient?${parts.join('&')}';
}

/// Parse a Solana Pay URL into a PaymentRequest.
/// Returns null if the URL is invalid.
PaymentRequest? parseSolanaPayUrl(String url) {
  if (!url.startsWith('solana:')) return null;

  try {
    // Extract recipient (between "solana:" and "?")
    final withoutScheme = url.substring(7); // remove "solana:"
    final qIndex = withoutScheme.indexOf('?');
    if (qIndex == -1) return null;

    final recipient = withoutScheme.substring(0, qIndex);
    final queryString = withoutScheme.substring(qIndex + 1);
    final params = Uri.splitQueryString(queryString);

    final amountStr = params['amount'];
    if (amountStr == null) return null;

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    final splToken = params['spl-token'];
    PaymentToken token;
    if (splToken != null) {
      if (splToken == usdcMintAddress) {
        token = PaymentToken.usdc;
      } else {
        return null; // Unknown SPL token
      }
    } else {
      token = PaymentToken.sol;
    }

    final reference = params['reference'];
    if (reference == null) return null;

    final label = params['label'] ?? 'Unknown';

    return PaymentRequest(
      recipient: recipient,
      amount: amount,
      token: token,
      reference: reference,
      label: label,
    );
  } catch (_) {
    return null;
  }
}
