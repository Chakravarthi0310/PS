import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:paysync/models/transaction_model.dart';

class PieChartCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String? selectedEventId;
  final String period;

  const PieChartCard({
    Key? key,
    required this.transactions,
    this.selectedEventId,
    required this.period,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filterTransactions();
    final Map<String, double> categorySpending = {};

    for (var transaction in filteredTransactions) {
      final category = transaction.paymentMethod;
      categorySpending[category] =
          (categorySpending[category] ?? 0) + transaction.amount;
    }

    final pieData =
        categorySpending.entries.map((entry) {
          return PieChartSectionData(
            value: entry.value,
            title:
                '${entry.key}\n${(entry.value / filteredTransactions.fold<double>(0, (sum, t) => sum + t.amount) * 100).toStringAsFixed(1)}%',
            color: _getColorForCategory(entry.key),
            radius: 100,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return Container(
      height: 400,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: pieData,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionModel> _filterTransactions() {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'Week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'Year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(Duration(days: 30));
    }

    return transactions.where((transaction) {
      final isInPeriod = transaction.dateTime.isAfter(startDate);
      final isInEvent =
          selectedEventId == null || transaction.eventId == selectedEventId;
      return isInPeriod && isInEvent;
    }).toList();
  }

  Color _getColorForCategory(String category) {
    final colors = {
      'Cash': Colors.green,
      'Card': Colors.blue,
      'UPI': Colors.orange,
      'Bank Transfer': Colors.purple,
    };
    return colors[category] ?? Colors.grey;
  }
}
