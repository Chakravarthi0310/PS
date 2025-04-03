import 'package:flutter/material.dart';
import 'package:paysync/models/event_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/utils/currency_formatter.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:fl_chart/fl_chart.dart';

class EventTransactionsScreen extends StatelessWidget {
  final EventModel event;
  final UserModel currentUser;

  const EventTransactionsScreen({
    Key? key,
    required this.event,
    required this.currentUser,
  }) : super(key: key);

  Future<Map<String, dynamic>> _getTransactionsData() async {
    final db = DatabaseHelper();
    final transactions = <TransactionModel>[];
    final memberData = <String, Map<String, dynamic>>{};
    
    // Get all transactions
    for (String transactionId in event.transactions) {
      final transaction = await db.getTransaction(transactionId);
      if (transaction != null) {
        transactions.add(transaction);
        
        // Get member details if not already fetched
        if (!memberData.containsKey(transaction.userId)) {
          final user = await db.getUser(transaction.userId);
          memberData[transaction.userId] = {
            'name': user?.username ?? 'Unknown',
            'totalSpent': 0.0,
            'transactions': 0,
          };
        }
        
        // Update member statistics
        memberData[transaction.userId]!['totalSpent'] += transaction.amount;
        memberData[transaction.userId]!['transactions']++;
      }
    }

    return {
      'transactions': transactions,
      'memberData': memberData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Transactions'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getTransactionsData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final transactions = data['transactions'] as List<TransactionModel>;
          final memberData = data['memberData'] as Map<String, Map<String, dynamic>>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMemberInsights(memberData),
                _buildTransactionsList(transactions, memberData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberInsights(Map<String, Map<String, dynamic>> memberData) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Member Insights',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: memberData.entries.map((entry) {
                  final spent = entry.value['totalSpent'] as double;
                  final total = memberData.values
                      .fold(0.0, (sum, member) => sum + (member['totalSpent'] as double));
                  return PieChartSectionData(
                    value: spent.abs(),
                    title: '${(spent.abs() / total * 100).toStringAsFixed(1)}%',
                    color: Colors.primaries[
                      memberData.keys.toList().indexOf(entry.key) %
                          Colors.primaries.length
                    ],
                    radius: 100,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: memberData.length,
            itemBuilder: (context, index) {
              final entry = memberData.entries.elementAt(index);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.primaries[index % Colors.primaries.length],
                  child: Text(
                    entry.value['name'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(entry.value['name']),
                subtitle: Text(
                  '${entry.value['transactions']} transactions',
                ),
                trailing: Text(
                  CurrencyFormatter.format(
                    CurrencyConverter.convert(
                      entry.value['totalSpent'],
                      event.currency,
                      currentUser.currencyName,
                    ),
                    currentUser.currencyName,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    List<TransactionModel> transactions,
    Map<String, Map<String, dynamic>> memberData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'All Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final member = memberData[transaction.userId];
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(member?['name'][0].toUpperCase() ?? 'U'),
                ),
                title: Row(
                  children: [
                    Text(member?['name'] ?? 'Unknown'),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(
                        transaction.amount,
                        transaction.currency,
                      ),
                      style: TextStyle(
                        color: transaction.isCredit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (transaction.note?.isNotEmpty ?? false)
                      Text(transaction.note!),
                    Text(
                      transaction.dateTime.toString().split('.')[0],
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Icon(
                  transaction.isOnline
                      ? Icons.account_balance
                      : Icons.money,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}