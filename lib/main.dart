import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/sb_transaction.dart';
import 'models/category_model.dart';       // ← NEW
import 'services/category_service.dart';   // ← NEW
import 'screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialise Hive ────────────────────────────────────────────────────────
  await Hive.initFlutter();

  // ── Register adapters ──────────────────────────────────────────────────────
  Hive.registerAdapter(SBTransactionAdapter());
  Hive.registerAdapter(CategoryModelAdapter());    // ← NEW (typeId: 2)

  // ── Open boxes ────────────────────────────────────────────────────────────
  await Hive.openBox<SBTransaction>('sb_transactions');
  await Hive.openBox('app_meta');
  await CategoryService.openBox();                 // ← NEW

  // ── Seed default categories on first launch ────────────────────────────────
  await CategoryService.seedDefaultsIfEmpty();     // ← NEW

  runApp(const SmartBudgetApp());
}

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartBudget',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}
