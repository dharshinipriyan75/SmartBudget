import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'sb_transaction.dart';

// ─────────────────────────────────────────────
// Rule Engine Model
// ─────────────────────────────────────────────

enum SuggestionType { overBudget, nearLimit, savingsProjection, categoryTrend }

class RuleSuggestion {
  final SuggestionType type;
  final String category;
  final String headline;
  final String detail;
  final Color color;
  final IconData icon;

  RuleSuggestion({
    required this.type,
    required this.category,
    required this.headline,
    required this.detail,
    required this.color,
    required this.icon,
  });
}

// ─────────────────────────────────────────────
// DateTime helpers
// ─────────────────────────────────────────────

extension DateTimeExtras on DateTime {
  int get dayOfYear => difference(DateTime(year, 1, 1)).inDays + 1;
  bool get isLeapYear =>
      (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

// ─────────────────────────────────────────────
// Rule Engine Logic
// ─────────────────────────────────────────────

class BudgetRuleEngine {
  static const Map<String, int> categoryLimits = {
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

  static int get totalBudget => categoryLimits.values.fold(0, (a, b) => a + b);

  static String mapMerchantToCategory(String merchant) {
    final m = merchant.toLowerCase();
    if (m.contains("swiggy") || m.contains("zomato")) return "Food";
    if (m.contains("uber") || m.contains("ola")) return "Travel";
    if (m.contains("netflix") || m.contains("spotify")) return "Subscription";
    if (m.contains("pvr") || m.contains("cinema")) return "Movies";
    if (m.contains('zepto')) return 'Shopping';
    return "Miscellaneous";
  }

  static List<RuleSuggestion> generate({
    required List<SBTransaction> transactions,
    required bool isYearly,
    required double savingsPct,
  }) {
    final now = DateTime.now();
    final List<RuleSuggestion> results = [];

    final filtered = transactions.where((t) {
      if (isYearly) return t.timestamp.year == now.year;
      return t.timestamp.year == now.year && t.timestamp.month == now.month;
    }).toList();

    final Map<String, double> categorySpent = {};
    for (var txn in filtered) {
      final cat = mapMerchantToCategory(txn.merchant);
      categorySpent[cat] = (categorySpent[cat] ?? 0) + txn.amount;
    }

    final double totalSpent = categorySpent.values.fold(0.0, (a, b) => a + b);

    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final int daysElapsed = isYearly ? now.dayOfYear : now.day;
    final int daysInPeriod = isYearly
        ? (now.isLeapYear ? 366 : 365)
        : daysInMonth;
    final int daysRemaining = daysInPeriod - daysElapsed;
    final double periodProgress = daysElapsed / daysInPeriod;

    // ── RULE 1: Over budget ──
    for (var entry in categorySpent.entries) {
      final double limit =
          (categoryLimits[entry.key] ?? 0) * (isYearly ? 12.0 : 1.0);
      final double spent = entry.value;
      final double pct = limit > 0 ? spent / limit : 0.0;

      if (pct >= 1.0) {
        final double overspend = spent - limit;
        final double reducePerDay = daysRemaining > 0
            ? overspend / daysRemaining
            : overspend;
        results.add(
          RuleSuggestion(
            type: SuggestionType.overBudget,
            category: entry.key,
            headline: "🚨 Over budget on ${entry.key}",
            detail:
                "You've spent ₹${spent.toStringAsFixed(0)} on ${entry.key}, which is "
                "₹${overspend.toStringAsFixed(0)} (${((pct - 1) * 100).toStringAsFixed(0)}%) "
                "over your ${isYearly ? 'yearly' : 'monthly'} limit of ₹${limit.toStringAsFixed(0)}. "
                "${daysRemaining > 0 ? 'To recover, reduce your ${entry.key} spending by ₹${reducePerDay.toStringAsFixed(0)}/day for the rest of the ${isYearly ? 'year' : 'month'}.' : ''}",
            color: Colors.redAccent,
            icon: Icons.warning_amber_rounded,
          ),
        );
      } else if (pct >= 0.75) {
        // ── RULE 2: Nearing limit ──
        final double remaining = limit - spent;
        final double dailyBudget = daysRemaining > 0
            ? remaining / daysRemaining
            : 0.0;
        results.add(
          RuleSuggestion(
            type: SuggestionType.nearLimit,
            category: entry.key,
            headline:
                "⚡ ${(pct * 100).toStringAsFixed(0)}% of ${entry.key} budget used",
            detail:
                "You've spent ₹${spent.toStringAsFixed(0)} of your ₹${limit.toStringAsFixed(0)} "
                "${entry.key} budget this ${isYearly ? 'year' : 'month'}. "
                "You have ₹${remaining.toStringAsFixed(0)} left"
                "${daysRemaining > 0 ? ' and $daysRemaining days to go — that\'s ₹${dailyBudget.toStringAsFixed(0)}/day.' : '.'}",
            color: Colors.orangeAccent,
            icon: Icons.trending_up,
          ),
        );
      }
    }

    // ── RULE 3: Spending faster than time elapsed ──
    for (var entry in categorySpent.entries) {
      final double limit =
          (categoryLimits[entry.key] ?? 0) * (isYearly ? 12.0 : 1.0);
      final double spent = entry.value;
      final double pct = limit > 0 ? spent / limit : 0.0;

      if (pct < 1.0 && pct > periodProgress + 0.10) {
        final double projectedEnd = periodProgress > 0
            ? spent / periodProgress
            : spent;
        final double projectedOverspend = projectedEnd - limit;
        if (projectedOverspend > 0) {
          results.add(
            RuleSuggestion(
              type: SuggestionType.categoryTrend,
              category: entry.key,
              headline: "📈 ${entry.key} spending pace is high",
              detail:
                  "You're ${(periodProgress * 100).toStringAsFixed(0)}% through the "
                  "${isYearly ? 'year' : 'month'} but have used ${(pct * 100).toStringAsFixed(0)}% "
                  "of your ${entry.key} budget. At this rate, you'll spend "
                  "₹${projectedEnd.toStringAsFixed(0)} total — that's "
                  "₹${projectedOverspend.toStringAsFixed(0)} over your limit. "
                  "Try to slow down your ${entry.key} spending to stay on track.",
              color: Colors.yellowAccent,
              icon: Icons.speed,
            ),
          );
        }
      }
    }

    // ── RULE 4: Savings projection ──
    final double periodBudget = totalBudget * (isYearly ? 12.0 : 1.0);
    final double targetSavings = periodBudget * (savingsPct / 100);
    final double maxSpend = periodBudget - targetSavings;
    final double remainingSpendAllowed = maxSpend - totalSpent;
    final double projectedSpend = periodProgress > 0
        ? totalSpent / periodProgress
        : totalSpent;
    final double projectedSavings = periodBudget - projectedSpend;

    if (projectedSavings >= targetSavings) {
      results.add(
        RuleSuggestion(
          type: SuggestionType.savingsProjection,
          category: "Savings",
          headline:
              "✅ On track to save ₹${projectedSavings.toStringAsFixed(0)}",
          detail:
              "At your current spending rate, you'll save about "
              "₹${projectedSavings.toStringAsFixed(0)} by end of the ${isYearly ? 'year' : 'month'} "
              "— that's ${((projectedSavings / periodBudget) * 100).toStringAsFixed(1)}% of your total budget. "
              "Your target was ${savingsPct.toStringAsFixed(0)}% (₹${targetSavings.toStringAsFixed(0)}). "
              "${isYearly ? 'Monthly equivalent: ₹${(projectedSavings / 12).toStringAsFixed(0)}/month.' : 'Yearly equivalent if maintained: ₹${(projectedSavings * 12).toStringAsFixed(0)}/year.'}",
          color: Colors.greenAccent,
          icon: Icons.savings,
        ),
      );
    } else if (remainingSpendAllowed > 0) {
      results.add(
        RuleSuggestion(
          type: SuggestionType.savingsProjection,
          category: "Savings",
          headline: "⚠️ Savings goal at risk",
          detail:
              "To hit your ${savingsPct.toStringAsFixed(0)}% savings goal "
              "(₹${targetSavings.toStringAsFixed(0)}), you can only spend "
              "₹${remainingSpendAllowed.toStringAsFixed(0)} more this ${isYearly ? 'year' : 'month'}. "
              "But at your current pace, you'll spend ₹${projectedSpend.toStringAsFixed(0)} total, "
              "saving only ₹${(periodBudget - projectedSpend).clamp(0, double.infinity).toStringAsFixed(0)}. "
              "${isYearly ? 'Try cutting ₹${((projectedSpend - maxSpend) / 12).toStringAsFixed(0)}/month to get back on track.' : 'Try cutting ₹${((projectedSpend - maxSpend) / daysRemaining.clamp(1, 31)).toStringAsFixed(0)}/day for the rest of the month.'}",
          color: Colors.orangeAccent,
          icon: Icons.savings_outlined,
        ),
      );
    } else {
      results.add(
        RuleSuggestion(
          type: SuggestionType.savingsProjection,
          category: "Savings",
          headline:
              "❌ Savings goal not achievable this ${isYearly ? 'year' : 'month'}",
          detail:
              "You've already spent more than allowed to reach your "
              "${savingsPct.toStringAsFixed(0)}% savings goal. "
              "Focus on cutting back now and aim for a fresh start next ${isYearly ? 'year' : 'month'}. "
              "${isYearly ? 'Monthly savings needed next year: ₹${(targetSavings / 12).toStringAsFixed(0)}/month.' : 'Yearly impact: missing this month costs approximately ₹${(targetSavings * 12).toStringAsFixed(0)}/year in savings.'}",
          color: Colors.redAccent,
          icon: Icons.money_off,
        ),
      );
    }

    return results;
  }
}

// ─────────────────────────────────────────────
// Suggestions Page UI (no Scaffold — lives inside HomePage)
// ─────────────────────────────────────────────

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key});

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  bool _isYearly = false;
  double _savingsPct = 20;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<SBTransaction>('sb_transactions').listenable(),
      builder: (context, Box<SBTransaction> box, _) {
        final transactions = box.values.toList();
        final suggestions = BudgetRuleEngine.generate(
          transactions: transactions,
          isYearly: _isYearly,
          savingsPct: _savingsPct,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Period toggle ──
              Row(
                children: [
                  const Text(
                    "View:",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  _toggleBtn(
                    "Monthly",
                    !_isYearly,
                    () => setState(() => _isYearly = false),
                  ),
                  const SizedBox(width: 8),
                  _toggleBtn(
                    "Yearly",
                    _isYearly,
                    () => setState(() => _isYearly = true),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Savings target slider ──
              Card(
                color: const Color(0xFF1B263B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "🎯 Savings Target",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${_savingsPct.toStringAsFixed(0)}%",
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${(BudgetRuleEngine.totalBudget * (_isYearly ? 12 : 1) * (_savingsPct / 100)).toStringAsFixed(0)} target for this ${_isYearly ? 'year' : 'month'}",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Slider(
                        value: _savingsPct,
                        min: 5,
                        max: 50,
                        divisions: 9,
                        activeColor: Colors.blueAccent,
                        inactiveColor: const Color(0xFF1E2A38),
                        onChanged: (val) => setState(() => _savingsPct = val),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "5%",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            "50%",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Suggestion cards ──
              if (suggestions.isEmpty)
                const Center(
                  child: Text(
                    "No suggestions yet. Add some transactions!",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              else
                ...suggestions.map((s) => _suggestionCard(s)),
            ],
          ),
        );
      },
    );
  }

  Widget _toggleBtn(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent : const Color(0xFF1B263B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _suggestionCard(RuleSuggestion s) {
    return Card(
      color: const Color(0xFF1B263B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.headline,
                    style: TextStyle(
                      color: s.color,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A192F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                s.detail,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
