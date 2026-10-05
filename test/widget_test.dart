import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_wallet/providers/wallet_provider.dart';
import 'package:smart_wallet/screens/wallet_screen.dart';

void main() {
  testWidgets('WalletScreen renders app title and AI section', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WalletProvider(),
        child: const MaterialApp(
          home: WalletScreen(),
        ),
      ),
    );

    // Verify that the screen title displays
    expect(find.text('Smart AI Wallet'), findsOneWidget);

    // Verify that the AI Insights section header exists
    expect(find.text('AI Insights'), findsOneWidget);
  });
}