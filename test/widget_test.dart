import 'package:flutter_test/flutter_test.dart';

import 'package:solana_pay/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SolanaPayApp());
    expect(find.text('Solana Pay Demo'), findsOneWidget);
  });
}
