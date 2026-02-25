import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/merchant/amount_screen.dart';
import 'screens/merchant/qr_screen.dart';
import 'screens/merchant/success_screen.dart';
import 'screens/customer/scan_screen.dart';
import 'screens/customer/confirm_screen.dart';
import 'screens/customer/sent_screen.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await SettingsService.getInstance();
  runApp(const SolanaPayApp());
}

class SolanaPayApp extends StatelessWidget {
  const SolanaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solana Pay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF7C3AED),
          secondary: const Color(0xFF10B981),
          surface: Colors.white,
          onSurface: const Color(0xFF1E1E2E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1E1E2E)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E1E2E),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/merchant/amount': (_) => const AmountScreen(),
        '/merchant/qr': (_) => const QrScreen(),
        '/merchant/success': (_) => const MerchantSuccessScreen(),
        '/customer/scan': (_) => const ScanScreen(),
        '/customer/confirm': (_) => const ConfirmScreen(),
        '/customer/sent': (_) => const SentScreen(),
      },
    );
  }
}
