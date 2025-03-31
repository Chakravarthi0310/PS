import 'package:flutter/material.dart';
import 'package:paysync/models/event_model.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:paysync/utils/currency_formatter.dart';

class EventSpendingCard extends StatelessWidget {
  final EventModel event;
  final List<TransactionModel> transactions;
  final String period;
  final UserModel currentUser; // Add this

  const EventSpendingCard({
    Key? key,
    required this.event,
    required this.transactions,
    required this.period,
    required this.currentUser, // Add this
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventTransactions = _filterTransactions();

    // Convert all transactions to user's currency
    final totalSpent = eventTransactions.fold<double>(0, (sum, transaction) {
      String fromCurrency = _getCurrencyCode(transaction.currency);
      String toCurrency = _getCurrencyCode(currentUser.currencyName);

      if (fromCurrency != toCurrency) {
        return sum +
            CurrencyConverter.convert(
              transaction.amount,
              fromCurrency,
              toCurrency,
            );
      }
      return sum + transaction.amount;
    });

    // Convert budget to user's currency if needed
    double? convertedBudget;
    if (event.budget != null) {
      String fromCurrency = _getCurrencyCode(event.currency);
      String toCurrency = _getCurrencyCode(currentUser.currencySymbol);

      convertedBudget =
          fromCurrency != toCurrency
              ? CurrencyConverter.convert(
                event.budget!,
                fromCurrency,
                toCurrency,
              )
              : event.budget;
    }

    final progress =
        convertedBudget != null ? (totalSpent / convertedBudget) : null;

    // Update the display to show both currencies
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  event.nameOfEvent,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(
                      totalSpent,
                      currentUser.currencyName,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  if (event.currency != currentUser.currencySymbol)
                    Text(
                      '(${CurrencyFormatter.format(eventTransactions.fold<double>(0, (sum, t) => sum + t.amount), event.currency)})',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
          if (progress != null) ...[
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.red : Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Budget: ${CurrencyFormatter.format(convertedBudget!, currentUser.currencyName)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (event.currency != currentUser.currencyName)
              Text(
                '(${event.currency}${event.budget})',
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
          ],
          SizedBox(height: 8),
          Text(
            '${eventTransactions.length} transactions',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

    return transactions
        .where(
          (transaction) =>
              transaction.eventId == event.eventId &&
              transaction.dateTime.isAfter(startDate),
        )
        .toList();
  }

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
        return currencySymbol;
    }
  }
}
