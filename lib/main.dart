import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wallet/providers/wallet_provider.dart';
import 'package:smart_wallet/screens/wallet_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WalletProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Wallet',
        home: WalletScreen(),
      ),
    );
  }
}