import 'package:flutter/material.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:paysync/utils/currency_formatter.dart';

class InsightCard extends StatelessWidget {
  final String title;
  final List<TransactionModel> transactions;
  final String? selectedEventId;
  final String period;
  final UserModel currentUser; // Add this

  const InsightCard({
    Key? key,
    required this.title,
    required this.transactions,
    this.selectedEventId,
    required this.period,
    required this.currentUser, // Add this
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filterTransactions();

    // Convert amounts to user's currency
    final spending = filteredTransactions
        .where((t) => !t.isCredit)
        .fold<double>(0, (sum, t) {
          String fromCurrency = _getCurrencyCode(t.currency);
          String toCurrency = _getCurrencyCode(currentUser.currencyName);
          
          if (fromCurrency != toCurrency) {
            return sum + CurrencyConverter.convert(
              t.amount,
              fromCurrency,
              toCurrency,
            );
          }
          return sum + t.amount;
        });

    final income = filteredTransactions
        .where((t) => t.isCredit)
        .fold<double>(0, (sum, t) {
          String fromCurrency = _getCurrencyCode(t.currency);
          String toCurrency = _getCurrencyCode(currentUser.currencyName);
          
          if (fromCurrency != toCurrency) {
            return sum + CurrencyConverter.convert(
              t.amount,
              fromCurrency,
              toCurrency,
            );
          }
          return sum + t.amount;
        });

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.2),
            Theme.of(context).primaryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(spending, currentUser.currencyName),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Income: ${CurrencyFormatter.format(income, currentUser.currencyName)}',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${filteredTransactions.length} transactions',
            style: TextStyle(color: Colors.grey[600]),
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

  // Add helper method for currency code conversion
  String _getCurrencyCode(String currencySymbol) {
    switch (currencySymbol) {
      case '₹':
        return 'INR';
      case '\$':
        return 'USD';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case '¥':
        return 'JPY';
      default:
        return currencySymbol; // Return as-is if it's already a currency code
    }
  }
}
