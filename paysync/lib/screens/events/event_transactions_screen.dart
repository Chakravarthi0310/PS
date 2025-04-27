import 'package:flutter/material.dart';
import 'package:paysync/models/event_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/utils/currency_formatter.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:provider/provider.dart';
import 'package:paysync/providers/theme_provider.dart';

class EventTransactionsScreen extends StatefulWidget {
  final EventModel event;
  final UserModel currentUser;
  final Map<String, UserModel> members;

  const EventTransactionsScreen({
    Key? key,
    required this.event,
    required this.currentUser,
    required this.members,
  }) : super(key: key);

  @override
  _EventTransactionsScreenState createState() => _EventTransactionsScreenState();
}

class _EventTransactionsScreenState extends State<EventTransactionsScreen> {
  String _selectedFilter = 'All';
  bool _showOnlyCredits = false;
  bool _showOnlyDebits = false;
  bool _showOnlyOnline = false;
  bool _showOnlyOffline = false;

  Future<Map<String, dynamic>> _getTransactionsData() async {
    final db = DatabaseHelper();
    final transactions = <TransactionModel>[];
    final memberData = <String, Map<String, dynamic>>{};
    
    print('Members passed to screen: ${widget.members.length}');
    widget.members.forEach((id, user) {
      print('Member ID: $id, Username: ${user.username}');
    });
    
    // Get all transactions from Firestore first
    try {
      final _firestore = firestore.FirebaseFirestore.instance;
      final eventDoc = await _firestore.collection('events').doc(widget.event.eventId).get();
      if (eventDoc.exists) {
        final eventData = eventDoc.data()!;
        List<String> transactionIds = [];
        
        if (eventData['transactions'] != null) {
          if (eventData['transactions'] is String) {
            transactionIds = eventData['transactions'].toString().split(',').where((e) => e.isNotEmpty).toList();
          } else if (eventData['transactions'] is List) {
            transactionIds = List<String>.from(eventData['transactions']);
          }
        }

        print('Found ${transactionIds.length} transaction IDs in Firestore');
        final transactionFutures = transactionIds.map((id) => _firestore.collection('transactions').doc(id).get());
        final transactionDocs = await Future.wait(transactionFutures);

        for (var doc in transactionDocs) {
          if (doc.exists) {
            final data = doc.data()!;
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

            print('Processing transaction: ${transaction.transactionId} by user: ${transaction.userId}');
            
            // If user not in members map, try to fetch from database
            if (!widget.members.containsKey(transaction.userId)) {
              print('User ${transaction.userId} not found in members map, fetching from database...');
              final user = await db.getUser(transaction.userId);
              if (user != null) {
                widget.members[transaction.userId] = user;
                print('Found user in database: ${user.username}');
              } else {
                print('Warning: User ${transaction.userId} not found in database either');
              }
            }

            // Store in local database for offline access
            await db.insertTransaction(transaction);
            transactions.add(transaction);
            
            // Update member statistics using the passed members map
            if (widget.members.containsKey(transaction.userId)) {
              final user = widget.members[transaction.userId]!;
              if (!memberData.containsKey(transaction.userId)) {
                memberData[transaction.userId] = {
                  'name': user.username,
                  'totalSpent': 0.0,
                  'transactions': 0,
                  'profileImageUrl': user.profileImageUrl,
                };
              }
              memberData[transaction.userId]!['totalSpent'] += transaction.amount;
              memberData[transaction.userId]!['transactions']++;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching transactions from Firestore: $e');
    }

    // If no transactions found in Firestore, try local database
    if (transactions.isEmpty) {
      for (String transactionId in widget.event.transactions) {
        final transaction = await db.getTransaction(transactionId);
        if (transaction != null) {
          print('Processing local transaction: ${transaction.transactionId} by user: ${transaction.userId}');
          
          // If user not in members map, try to fetch from database
          if (!widget.members.containsKey(transaction.userId)) {
            print('User ${transaction.userId} not found in members map, fetching from database...');
            final user = await db.getUser(transaction.userId);
            if (user != null) {
              widget.members[transaction.userId] = user;
              print('Found user in database: ${user.username}');
            } else {
              print('Warning: User ${transaction.userId} not found in database either');
            }
          }
          
          transactions.add(transaction);
          
          // Update member statistics using the passed members map
          if (widget.members.containsKey(transaction.userId)) {
            final user = widget.members[transaction.userId]!;
            if (!memberData.containsKey(transaction.userId)) {
              memberData[transaction.userId] = {
                'name': user.username,
                'totalSpent': 0.0,
                'transactions': 0,
                'profileImageUrl': user.profileImageUrl,
              };
            }
            memberData[transaction.userId]!['totalSpent'] += transaction.amount;
            memberData[transaction.userId]!['transactions']++;
          }
        }
      }
    }

    // Sort transactions by date
    transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return {
      'transactions': transactions,
      'memberData': memberData,
    };
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    return transactions.where((transaction) {
      if (_selectedFilter != 'All' && transaction.userId != widget.currentUser.userId) {
        return false;
      }
      if (_showOnlyCredits && !transaction.isCredit) return false;
      if (_showOnlyDebits && transaction.isCredit) return false;
      if (_showOnlyOnline && !transaction.isOnline) return false;
      if (_showOnlyOffline && transaction.isOnline) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Transactions'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All', child: Text('All Transactions')),
              PopupMenuItem(value: 'Mine', child: Text('My Transactions')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Credits'),
                  selected: _showOnlyCredits,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyCredits = selected;
                      if (selected) _showOnlyDebits = false;
                    });
                  },
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Debits'),
                  selected: _showOnlyDebits,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyDebits = selected;
                      if (selected) _showOnlyCredits = false;
                    });
                  },
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Online'),
                  selected: _showOnlyOnline,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyOnline = selected;
                      if (selected) _showOnlyOffline = false;
                    });
                  },
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Offline'),
                  selected: _showOnlyOffline,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyOffline = selected;
                      if (selected) _showOnlyOnline = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getTransactionsData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                final transactions = _filterTransactions(data['transactions'] as List<TransactionModel>);
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
          ),
        ],
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
                      widget.event.currency,
                      widget.currentUser.currencyName,
                    ),
                    widget.currentUser.currencyName,
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
            final user = widget.members[transaction.userId];
            
            if (user == null) {
              print('User not found for transaction ${transaction.transactionId}: ${transaction.userId}');
            }
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: user?.profileImageUrl != null 
                            ? NetworkImage(user!.profileImageUrl)
                            : null,
                          child: user?.profileImageUrl == null
                            ? Text(
                                user?.username[0].toUpperCase() ?? 'U',
                                style: TextStyle(color: Colors.white),
                              )
                            : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.username ?? 'Unknown User',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                transaction.dateTime.toString().split('.')[0],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: transaction.isCredit ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                transaction.isOnline ? Icons.account_balance : Icons.money,
                                size: 16,
                                color: transaction.isCredit ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
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
                        ),
                      ],
                    ),
                    if (transaction.note?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          transaction.note!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          transaction.paymentMethod,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          transaction.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}