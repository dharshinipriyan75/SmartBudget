import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'sb_transaction.dart';

class CategoryData {
  final String category;
  final double amount;
  CategoryData(this.category, this.amount);
}

class MonthlyData {
  final String month;
  final double amount;
  MonthlyData(this.month, this.amount);
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedView = 'Category';

  String mapMerchantToCategory(String merchant) {
    final m = merchant.toLowerCase();
    if (m.contains("swiggy") || m.contains("zomato")) return "Food";
    if (m.contains("uber") || m.contains("ola")) return "Travel";
    if (m.contains("netflix") || m.contains("spotify")) return "Subscription";
    if (m.contains("pvr") || m.contains("cinema")) return "Movies";
    if (m.contains('zepto')) return 'Shopping';
    return "Miscellaneous";
  }

  Map<String, double> _getCategoryTotals(List<SBTransaction> transactions) {
    final Map<String, double> totals = {};
    for (var txn in transactions) {
      final cat = mapMerchantToCategory(txn.merchant);
      totals[cat] = (totals[cat] ?? 0) + txn.amount;
    }
    return totals;
  }

  Map<String, double> _getMonthlyTotals(List<SBTransaction> transactions) {
    final Map<String, double> totals = {};
    final monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    for (var txn in transactions) {
      final key = '${monthNames[txn.timestamp.month]} ${txn.timestamp.year}';
      totals[key] = (totals[key] ?? 0) + txn.amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<SBTransaction>('sb_transactions').listenable(),
      builder: (context, Box<SBTransaction> box, _) {
        final transactions = box.values.toList();

        if (transactions.isEmpty) {
          return const Center(
            child: Text(
              "No transactions yet.\nAdd some expenses to see reports!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
          );
        }

        final categoryTotals = _getCategoryTotals(transactions);
        final monthlyTotals = _getMonthlyTotals(transactions);

        final categoryData = categoryTotals.entries
            .map((e) => CategoryData(e.key, e.value))
            .toList();

        final monthlyData = monthlyTotals.entries
            .map((e) => MonthlyData(e.key, e.value))
            .toList();

        final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
        final topCategory = categoryTotals.entries.isEmpty
            ? null
            : categoryTotals.entries.reduce(
                (a, b) => a.value > b.value ? a : b,
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  _summaryCard(
                    "Total Spent",
                    "₹${totalSpent.toStringAsFixed(0)}",
                    Icons.account_balance_wallet,
                    Colors.blueAccent,
                  ),
                  const SizedBox(width: 12),
                  _summaryCard(
                    "Top Category",
                    topCategory?.key ?? "-",
                    Icons.category,
                    Colors.orangeAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Toggle buttons
              Row(
                children: [
                  _toggleBtn('Category'),
                  const SizedBox(width: 10),
                  _toggleBtn('Monthly'),
                ],
              ),
              const SizedBox(height: 16),

              // Chart
              Card(
                color: const Color(0xFF1B263B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _selectedView == 'Category'
                      ? Column(
                          children: [
                            const Text(
                              "Spending by Category",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SfCartesianChart(
                              primaryXAxis: CategoryAxis(
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                                labelRotation: -30,
                              ),
                              primaryYAxis: NumericAxis(
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                labelFormat: '₹{value}',
                              ),
                              series: <CartesianSeries>[
                                BarSeries<CategoryData, String>(
                                  dataSource: categoryData,
                                  xValueMapper: (d, _) => d.category,
                                  yValueMapper: (d, _) => d.amount,
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(6),
                                  dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                    textStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            const Text(
                              "Monthly Spending Trend",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SfCartesianChart(
                              primaryXAxis: CategoryAxis(
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              primaryYAxis: NumericAxis(
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                labelFormat: '₹{value}',
                              ),
                              series: <CartesianSeries>[
                                LineSeries<MonthlyData, String>(
                                  dataSource: monthlyData,
                                  xValueMapper: (d, _) => d.month,
                                  yValueMapper: (d, _) => d.amount,
                                  color: Colors.greenAccent,
                                  width: 3,
                                  markerSettings: const MarkerSettings(
                                    isVisible: true,
                                  ),
                                  dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                    textStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Category breakdown list
              const Text(
                "Category Breakdown",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...categoryData.map((d) => _categoryRow(d, totalSpent)),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleBtn(String label) {
    final isSelected = _selectedView == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedView = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xFF1B263B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _categoryRow(CategoryData d, double totalSpent) {
    final pct = totalSpent > 0 ? d.amount / totalSpent : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                d.category,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                "₹${d.amount.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(1)}%)",
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFF1E2A38),
              color: Colors.blueAccent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
