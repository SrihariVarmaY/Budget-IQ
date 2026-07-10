import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final currentMonthExpenses = state.expenses.where((e) => e.month == now.month && e.year == now.year).toList();
    final totalSpent = currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final categoryTotals = state.categoryTotals;

    if (currentMonthExpenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Spending Analytics')),
        body: const Center(child: Text('No expenses recorded this month')),
      );
    }

    double maxExpense = 0.0;
    for (var e in currentMonthExpenses) {
      if (e.amount > maxExpense) maxExpense = e.amount;
    }
    final avgExpense = totalSpent / currentMonthExpenses.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSummaryCard('Total Spent', '₹${totalSpent.toStringAsFixed(0)}', Colors.deepPurpleAccent),
                const SizedBox(width: 12),
                _buildSummaryCard('Transactions', '${currentMonthExpenses.length}', Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryCard('Average', '₹${avgExpense.toStringAsFixed(0)}', Colors.orangeAccent),
                const SizedBox(width: 12),
                _buildSummaryCard('Highest', '₹${maxExpense.toStringAsFixed(0)}', Colors.redAccent),
              ],
            ),
            
            const SizedBox(height: 40),
            const Text('Category Distribution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: _buildPieChartSections(categoryTotals, totalSpent),
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Text('Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 16),
            ...categoryTotals.entries.map((entry) => _buildLegendItem(
              entry.key, 
              entry.value, 
              (entry.value / totalSpent * 100).toStringAsFixed(1),
              _getCategoryColor(entry.key),
            )),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> totals, double totalSpent) {
    if (totalSpent <= 0) return [];
    return totals.entries.map((entry) {
      final percentage = (entry.value / totalSpent) * 100;
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildLegendItem(String category, double amount, String percent, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 16),
          Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$percent%', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.deepPurpleAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.yellowAccent,
    ];
    return colors[category.toLowerCase().hashCode % colors.length];
  }
}
