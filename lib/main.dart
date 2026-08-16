import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/customer_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(const SariSariLedgerApp());
}

class SariSariLedgerApp extends StatelessWidget {
  const SariSariLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider()..loadCustomers()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'SariSari Ledger',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 20),
            bodyMedium: TextStyle(fontSize: 18),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
