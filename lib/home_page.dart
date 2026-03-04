import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'sb_transaction.dart';
import 'sms_services.dart';
import 'reports_page.dart';
import 'suggestions_page.dart';

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
  int _currentIndex = 0;

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
    SmsService().fetchAndStoreTransactions().catchError((e) {
      debugPrint("SMS fetch failed: $e");
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    merchantController.dispose();
    super.dispose();
  }

  String mapMerchantToCategory(SBTransaction txn) {
    if (txn.category != null) return txn.category!;
    final m = txn.merchant.toLowerCase();
    if (m.contains("swiggy") || m.contains("zomato")) return "Food";
    if (m.contains("uber") || m.contains("ola")) return "Travel";
    if (m.contains("netflix") || m.contains("spotify")) return "Subscription";
    if (m.contains("pvr") || m.contains("cinema")) return "Movies";
    if (m.contains('zepto')) return 'Shopping';
    return "Miscellaneous";
  }

  int getSpent(String category) {
    final box = Hive.box<SBTransaction>('sb_transactions');
    return box.values
        .where((txn) => mapMerchantToCategory(txn) == category)
        .fold(0, (sum, txn) => sum + txn.amount.toInt());
  }

  void showAddExpenseDialog() {
    String selectedCategory = categoryLimits.keys.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF1B263B),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Category"),
                    items: categoryLimits.keys
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
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
                        merchant:
                            selectedCategory, // store category as merchant
                        timestamp: DateTime.now(),
                        type: "debit",
                        category: selectedCategory, // also save as category
                      ),
                    );

                    amountController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showCategorizeMiscDialog() {
    final box = Hive.box<SBTransaction>('sb_transactions');
    final miscTransactions = box.values
        .where((txn) => mapMerchantToCategory(txn) == "Miscellaneous")
        .toList();

    if (miscTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No miscellaneous transactions to categorise!"),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B263B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Categorise Miscellaneous",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: miscTransactions.length,
                          itemBuilder: (context, index) {
                            final txn = miscTransactions[index];
                            return Card(
                              color: const Color(0xFF1E2A38),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            txn.merchant,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "₹${txn.amount.toInt()}",
                                            style: const TextStyle(
                                              color: Color(0xFF9FB3C8),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      value: txn.category ?? "Miscellaneous",
                                      dropdownColor: const Color(0xFF1B263B),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      items: categoryLimits.keys
                                          .map(
                                            (cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (selected) async {
                                        if (selected != null) {
                                          txn.category = selected;
                                          await txn.save();
                                          setSheetState(() {});
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDashboard() {
    return Column(
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
                  final category = mapMerchantToCategory(txn);
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
                      style: TextStyle(fontSize: 26, color: Color(0xFFE0E1DD)),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Remaining Budget",
              style: TextStyle(
                color: Color(0xFFE0E1DD),
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: showCategorizeMiscDialog,
              icon: const Icon(Icons.category, size: 16),
              label: const Text("Categorise"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B263B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 300,
          child: ValueListenableBuilder(
            valueListenable: Hive.box<SBTransaction>(
              'sb_transactions',
            ).listenable(),
            builder: (context, Box<SBTransaction> box, _) {
              return GridView.count(
                scrollDirection: Axis.horizontal,
                crossAxisCount: 2,
                physics: const ClampingScrollPhysics(),
                children: categoryLimits.keys.map((category) {
                  final total = categoryLimits[category] ?? 0;
                  final spent = getSpent(category);

                  double progress = total == 0 ? 0 : spent / total;
                  if (progress > 1) progress = 1;

                  final isOver = spent > total;

                  return Card(
                    color: const Color(0xFF1E2A38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹$spent / ₹$total",
                            style: const TextStyle(
                              color: Color(0xFF9FB3C8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOver
                                    ? Colors.redAccent
                                    : const Color(0xFF64B5F6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isOver ? "₹${spent - total} over budget!" : "",
                            style: TextStyle(
                              color: isOver
                                  ? Colors.redAccent
                                  : const Color(0xFF9FB3C8),
                              fontSize: 12,
                              fontWeight: isOver
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ["SmartBudget", "Reports & Charts", "Suggestions"];

    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: showAddExpenseDialog,
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF102A43),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: "Suggestions",
          ),
        ],
      ),
      body: switch (_currentIndex) {
        0 => SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: _buildDashboard(),
        ),
        1 => const ReportsPage(),
        2 => const SuggestionsPage(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
