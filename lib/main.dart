import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'sb_transaction.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapter
  Hive.registerAdapter(SBTransactionAdapter());

  // Open Hive Box
  await Hive.openBox<SBTransaction>('sb_transactions');

  runApp(const SmartBudgetApp());
}

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartBudget',
      theme: ThemeData.dark(), // You can change this if needed
      home: const HomePage(),
    );
  }
}
