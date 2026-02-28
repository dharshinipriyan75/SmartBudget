import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'sb_transaction.dart';
import 'sms_services.dart';

class Expenses {
  String category;
  int budget;

  Expenses(this.category, this.budget);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController merchantController = TextEditingController();

  Map<String, int> categoryLimits = {
    "Travel": 1500,
    "Food": 1000,
    "Entertainment": 400,
    "Miscellaneous": 300,
    "Laundry": 500,
    "Subscription": 750,
    "Movies": 500,
    "Self-Care": 500,
    "Shopping": 1000,
  };

  @override
  void initState() {
    super.initState();

    SmsService().fetchAndStoreTransactions();
  }

  @override
  void dispose() {
    amountController.dispose();
    merchantController.dispose();
    super.dispose();
  }

  String mapMerchantToCategory(String merchant) {
    final m = merchant.toLowerCase();

    if (m.contains("swiggy") || m.contains("zomato")) {
      return "Food";
    } else if (m.contains("uber") || m.contains("ola")) {
      return "Travel";
    } else if (m.contains("netflix") || m.contains("spotify")) {
      return "Subscription";
    } else if (m.contains("pvr") || m.contains("cinema")) {
      return "Movies";
    } else if (m.contains('zepto')) {
      return 'Shopping';
    } else {
      return "Miscellaneous";
    }
  }

  int budgetRemaining(String category) {
    final box = Hive.box<SBTransaction>('sb_transactions');
    final transactions = box.values.toList();

    int spent = transactions
        .where((txn) => mapMerchantToCategory(txn.merchant) == category)
        .fold(0, (sum, txn) => sum + txn.amount.toInt());

    return (categoryLimits[category] ?? 0) - spent;
  }

  void showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: merchantController,
                decoration: const InputDecoration(labelText: "Merchant"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null) return;

                final box = Hive.box<SBTransaction>('sb_transactions');

                await box.add(
                  SBTransaction(
                    id: DateTime.now().millisecondsSinceEpoch,
                    amount: amount,
                    merchant: merchantController.text,
                    timestamp: DateTime.now(),
                    type: "debit",
                  ),
                );

                amountController.clear();
                merchantController.clear();

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        title: const Text("SmartBudget", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddExpenseDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Card(
              color: const Color(0xFF1B263B),
              elevation: 15.0,
              child: ValueListenableBuilder(
                valueListenable: Hive.box<SBTransaction>(
                  'sb_transactions',
                ).listenable(),
                builder: (context, Box<SBTransaction> box, _) {
                  final transactions = box.values.toList();

                  Map<String, int> categoryTotals = {};

                  for (var txn in transactions) {
                    final category = mapMerchantToCategory(txn.merchant);
                    categoryTotals[category] =
                        (categoryTotals[category] ?? 0) + txn.amount.toInt();
                  }

                  final chartData = categoryTotals.entries
                      .map((e) => Expenses(e.key, e.value))
                      .toList();

                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Total Expenses Spent",
                        style: TextStyle(
                          fontSize: 26,
                          color: Color(0xFFE0E1DD),
                        ),
                      ),
                      SfCircularChart(
                        legend: const Legend(
                          isVisible: true,
                          textStyle: TextStyle(color: Colors.white),
                        ),
                        series: <CircularSeries>[
                          DoughnutSeries<Expenses, String>(
                            dataSource: chartData,
                            xValueMapper: (Expenses data, _) => data.category,
                            yValueMapper: (Expenses data, _) => data.budget,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Remaining Budget",
            style: TextStyle(
              color: Color(0xFFE0E1DD),
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 275,
            child: GridView.count(
              scrollDirection: Axis.horizontal,
              crossAxisCount: 2,
              children: categoryLimits.keys.map((category) {
                return Card(
                  color: const Color(0xFF1E2A38),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "₹${budgetRemaining(category)} left",
                        style: const TextStyle(color: Color(0xFF9FB3C8)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
