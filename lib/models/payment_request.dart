enum PaymentToken { sol, usdc }

class PaymentRequest {
  final String recipient;
  final double amount;
  final PaymentToken token;
  final String reference; // base58 pubkey for tracking
  final String label;

  const PaymentRequest({
    required this.recipient,
    required this.amount,
    required this.token,
    required this.reference,
    this.label = 'Solana Pay',
  });

  bool get isUsdc => token == PaymentToken.usdc;
  bool get isSol => token == PaymentToken.sol;

  String get tokenSymbol => token == PaymentToken.sol ? 'SOL' : 'USDC';

  int get lamports => (amount * 1e9).round();
  int get usdcRawAmount => (amount * 1e6).round();

  @override
  String toString() =>
      'PaymentRequest($amount $tokenSymbol to $recipient, ref=$reference)';
}
