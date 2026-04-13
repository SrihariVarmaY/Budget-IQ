import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ FIX: Use user-specific Firestore path
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          // 1. Process Data for Current Month
          final docs = snapshot.data!.docs;
          final List<Map<String, dynamic>> currentMonthExpenses = [];
          double totalSpent = 0.0;
          double maxExpense = 0.0;
          Map<String, double> categoryTotals = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['date'] as Timestamp?;
            if (timestamp != null) {
              final date = timestamp.toDate();
              // ✅ Filter only current month and year
              if (date.month == now.month && date.year == now.year) {
                final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
                final category = data['category']?.toString() ?? 'Other';

                currentMonthExpenses.add(data);
                totalSpent += amount;
                if (amount > maxExpense) maxExpense = amount;
                
                categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
              }
            }
          }

          if (currentMonthExpenses.isEmpty) {
            return const Center(child: Text('No expenses recorded this month'));
          }

          final avgExpense = totalSpent / currentMonthExpenses.length;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Summary Cards
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

                // 3. Pie Chart
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
                // 4. Legend
                const Text('Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 16),
                ...categoryTotals.entries.map((entry) => _buildLegendItem(
                  entry.key, 
                  entry.value, 
                  (entry.value / totalSpent * 100).toStringAsFixed(1),
                  _getCategoryColor(entry.key),
                )),
                
                const SizedBox(height: 100), // Extra space for FAB if needed
              ],
            ),
          );
        },
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
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
    // Use hash code to keep color consistent for the same category name
    return colors[category.toLowerCase().hashCode % colors.length];
  }
}
