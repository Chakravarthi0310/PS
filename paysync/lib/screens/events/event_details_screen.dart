import 'package:flutter/material.dart';
import 'package:paysync/models/event_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/screens/transaction/add_transaction_screen.dart';
import 'package:paysync/screens/transactions/transaction_details_screen.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:paysync/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/widgets/member_management_widget.dart';
import 'package:paysync/screens/events/event_transactions_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;
  final UserModel currentUser;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildEventSummaryCard(),
                // _buildBudgetSection(),
                _buildBudgetProgress(context),

                MemberManagementWidget(
                  event: event,
                  currentUserId: currentUser.userId,
                ),
                _buildTransactionsSection(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(event: event),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Add Transaction'),
      ),
    );
  }

  Widget _buildBudgetProgress(BuildContext context) {
    // Calculate how much of the budget has been spent
    final double totalSpent = CurrencyConverter.convert(
      event.onlineAmountOfEvent + event.offlineAmountOfEvent,
      event.currency,
      currentUser.currencyName,
    );
    print('Total Spent: $totalSpent');
    print("event currency: ${event.currency}");
    print("current user currency: ${currentUser.currencyName}");
    final double totalBudget = CurrencyConverter.convert(
      event.budget!,
      event.currency,
      currentUser.currencyName,
    );

    final double progress = -totalSpent / totalBudget;
    final Color progressColor = _getBudgetColor(progress);
    final String percentageText = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    progress > 1 ? 'Over Budget!' : 'Within Budget',
                    style: TextStyle(
                      color: progress > 1 ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: Icon(Icons.edit, size: 18),
                label: Text('Edit Budget'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showBudgetEditDialog(context),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: progress * 100,
                          color: progressColor,
                          title: '$percentageText%',
                          titleStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 2),
                            ],
                          ),
                          radius: 45,
                        ),
                        PieChartSectionData(
                          value: (1 - progress) * 100,
                          color: Colors.grey[200],
                          radius: 40,
                          title: '',
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBudgetInfoRow(
                        'Total Budget',
                        event.budget!,
                        Colors.black87,
                      ),
                      SizedBox(height: 8),
                      _buildBudgetInfoRow(
                        'Spent',
                        event.onlineAmountOfEvent + event.offlineAmountOfEvent,
                        progressColor,
                      ),
                      SizedBox(height: 8),
                      _buildBudgetInfoRow(
                        'Remaining',
                        event.budget! +
                            (event.onlineAmountOfEvent +
                                event.offlineAmountOfEvent),
                        Colors.grey[600]!,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInfoRow(String label, double amount, Color textColor) {
    // Convert amount to user's currency
    final convertedAmount = CurrencyConverter.convert(
      amount,
      event.currency,
      currentUser.currencyName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(
          CurrencyFormatter.format(convertedAmount, currentUser.currencyName),
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Show original amount in event currency
        if (event.currency != currentUser.currencyName)
          Text(
            '(${CurrencyFormatter.format(amount, event.currency)})',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  void _showBudgetEditDialog(BuildContext context) {
    final TextEditingController budgetController = TextEditingController(
      text: event.budget?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 10),
                Text('Edit Budget'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Budget Amount',
                    prefixText: '${event.currency} ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current spending: ${CurrencyFormatter.format(event.onlineAmountOfEvent + event.offlineAmountOfEvent, event.currency)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newBudget = double.tryParse(budgetController.text);
                  if (newBudget != null && newBudget > 0) {
                    await DatabaseHelper().updateEventBudget(
                      event.eventId,
                      newBudget,
                    );
                    Navigator.pop(context);
                    // Refresh the screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EventDetailsScreen(
                              event: event.copyWith(budget: newBudget),
                              currentUser: currentUser,
                            ),
                      ),
                    );
                  }
                },
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Add this method for app bar edit functionality
  void _showEditEventDialog(BuildContext context) {
    final nameController = TextEditingController(text: event.nameOfEvent);
    final currencyController = TextEditingController(text: event.currency);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).primaryColor),
                SizedBox(width: 10),
                Text('Edit Event'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.event),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: currencyController,
                  decoration: InputDecoration(
                    labelText: 'Currency Symbol',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  final newCurrency = currencyController.text.trim();

                  if (newName.isNotEmpty && newCurrency.isNotEmpty) {
                    await DatabaseHelper().updateEvent(
                      event.eventId,
                      newName,
                      newCurrency,
                    );
                    Navigator.pop(context);
                    // Refresh the screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EventDetailsScreen(
                              event: event.copyWith(
                                nameOfEvent: newName,
                                currency: newCurrency,
                              ),
                              currentUser: currentUser,
                            ),
                      ),
                    );
                  }
                },
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Update the app bar edit button
  Widget _buildSliverAppBar(BuildContext context) {
    final double totalSpent = CurrencyConverter.convert(
      event.onlineAmountOfEvent + event.offlineAmountOfEvent,
      event.currency,
      currentUser.currencyName,
    );
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          event.nameOfEvent,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(
                    -(totalSpent),
                    currentUser.currencyName,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => _showEditEventDialog(context),
        ),
        IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Implement more options
          },
        ),
      ],
    );
  }

  Widget _buildEventSummaryCard() {
    double onlineAmount = event.onlineAmountOfEvent;
    double offlineAmount = event.offlineAmountOfEvent;
    onlineAmount = CurrencyConverter.convert(
      onlineAmount,
      event.currency,
      currentUser.currencyName,
    );
    offlineAmount = CurrencyConverter.convert(
      offlineAmount,
      event.currency,
      currentUser.currencyName,
    );
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Online',
              onlineAmount,
              Icons.account_balance,
              Colors.blue,
            ),
            VerticalDivider(thickness: 1),
            _buildSummaryItem(
              'Offline',
              offlineAmount,
              Icons.money,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount, currentUser.currencyName),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getBudgetColor(double progress) {
    if (progress > 1) return Colors.red; // Over budget
    if (progress > 0.8) return Colors.orange; // Close to budget
    return Colors.green; // Well within budget
  }

  // In the _buildTransactionsSection method, add a "View All" button
  Widget _buildTransactionsSection(BuildContext context) {
    return FutureBuilder<List<TransactionModel>>(
      future: _getEventTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No transactions yet')),
          );
        }

        final transactions = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Get member details from database
                      final db = DatabaseHelper();
                      final members = <String, UserModel>{};
                      
                      // Add current user to members list
                      members[currentUser.userId] = currentUser;
                      
                      // Add event creator to members list
                      final creator = await db.getUser(event.createdBy);
                      if (creator != null) {
                        members[event.createdBy] = creator;
                      }
                      
                      // Add other event members
                      for (String memberId in event.members) {
                        if (memberId != currentUser.userId && memberId != event.createdBy) {
                          final member = await db.getUser(memberId);
                          if (member != null) {
                            members[memberId] = member;
                          }
                        }
                      }
                      print("members are ${members}");

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventTransactionsScreen(
                            event: event,
                            currentUser: currentUser,
                            members: members,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length.clamp(0, 5), // Show only recent 5
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return TransactionCard(
                    transaction: transaction,
                    currentUser: currentUser,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<TransactionModel>> _getEventTransactions() async {
    print('🔄 Fetching transactions for event: ${event.eventId}');
    final db = DatabaseHelper();
    final _firestore = firestore.FirebaseFirestore.instance;
    List<TransactionModel> transactions = [];

    // First, try to get transactions from Firestore
    try {
      print('🌐 Fetching from Firestore...');
      final eventDoc = await _firestore.collection('events').doc(event.eventId).get();
      if (eventDoc.exists) {
        final eventData = eventDoc.data()!;
        List<String> transactionIds = [];
        
        // Handle both string and list formats for transactions
        if (eventData['transactions'] != null) {
          if (eventData['transactions'] is String) {
            transactionIds = eventData['transactions'].toString().split(',').where((e) => e.isNotEmpty).toList();
          } else if (eventData['transactions'] is List) {
            transactionIds = List<String>.from(eventData['transactions']);
          }
        }

        print('📋 Found ${transactionIds.length} transaction IDs in Firestore');
        
        // Fetch all transactions in parallel
        final transactionFutures = transactionIds.map((id) => _firestore.collection('transactions').doc(id).get());
        final transactionDocs = await Future.wait(transactionFutures);

        for (var doc in transactionDocs) {
          if (doc.exists) {
            final data = doc.data()!;
            print('✅ Found transaction in Firestore: ${doc.id}');
            
            final transaction = TransactionModel(
              transactionId: doc.id,
              userId: data['userId'],
              eventId: data['eventId'],
              isOnline: data['isOnline'] == 1 || data['isOnline'] == true,
              isCredit: data['isCredit'] == 1 || data['isCredit'] == true,
              amount: data['amount'].toDouble(),
              currency: data['currency'],
              paymentMethod: data['paymentMethod'],
              location: data['location'],
              dateTime: data['dateTime'] is firestore.Timestamp 
                ? (data['dateTime'] as firestore.Timestamp).toDate()
                : DateTime.parse(data['dateTime']),
              note: data['note'],
              imageUrl: data['imageUrl'],
              recurring: data['recurring'] == 1 || data['recurring'] == true,
              recurringType: data['recurringType'],
              createdAt: data['createdAt'] is firestore.Timestamp 
                ? (data['createdAt'] as firestore.Timestamp).toDate()
                : DateTime.parse(data['createdAt']),
              updatedAt: data['updatedAt'] is firestore.Timestamp 
                ? (data['updatedAt'] as firestore.Timestamp).toDate()
                : DateTime.parse(data['updatedAt']),
              onlineBalanceAfter: data['onlineBalanceAfter']?.toDouble() ?? 0.0,
              offlineBalanceAfter: data['offlineBalanceAfter']?.toDouble() ?? 0.0,
            );

            // Store in local database for offline access
            await db.insertTransaction(transaction);
            transactions.add(transaction);
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching from Firestore: $e');
    }

    // If no transactions found in Firestore, try local database
    if (transactions.isEmpty) {
      print('📱 Falling back to local database...');
      for (String transactionId in event.transactions) {
        final transaction = await db.getTransaction(transactionId);
        if (transaction != null) {
          print('✅ Found transaction in local DB: $transactionId');
          transactions.add(transaction);
        }
      }
    }

    // Sort by date, most recent first
    transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    print('📊 Total transactions found: ${transactions.length}');
    return transactions;
  }
}

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final UserModel currentUser;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              transaction.isCredit ? Colors.green[100] : Colors.red[100],
          child: Icon(
            transaction.isOnline ? Icons.account_balance : Icons.money,
            color: transaction.isCredit ? Colors.green : Colors.red,
          ),
        ),
        title: Row(
          children: [
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
            SizedBox(width: 8),
            Text(
              transaction.paymentMethod,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.note?.isNotEmpty ?? false) Text(transaction.note!),
            Text(
              _formatDate(transaction.dateTime),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TransactionDetailsScreen(
                    transaction: transaction,
                    currentUser: currentUser,
                  ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
