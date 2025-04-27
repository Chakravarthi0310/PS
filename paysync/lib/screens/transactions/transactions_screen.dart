import 'package:flutter/material.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/utils/currency_formatter.dart';

class TransactionsScreen extends StatefulWidget {
  final UserModel currentUser;

  const TransactionsScreen({Key? key, required this.currentUser})
    : super(key: key);

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  String _searchQuery = '';
  String? _selectedEvent;
  // Filter states
  String? _selectedType;
  String? _selectedPaymentMethod;
  DateTimeRange? _selectedDateRange;
  bool? _isOnline;

  // Add this map to store event names
  final Map<String, String> _eventNames = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadEventNames(); // Add this line
  }

  // Add this method to load event names
  Future<void> _loadEventNames() async {
    final eventIds = _transactions.map((t) => t.eventId).toSet().toList();
    print('Event IDs: ${eventIds.length}');
    for (String eventId in eventIds) {
      final event = await _dbHelper.getEvent(eventId);
      if (event != null) {
        setState(() {
          _eventNames[eventId] = event.nameOfEvent;
        });
      }
    }
  }

  // Update the _getUniqueEvents method
  List<String> _getUniqueEvents() {
    final eventNames =
        _transactions
            .where((t) => t.eventId.isNotEmpty)
            .map((t) => _eventNames[t.eventId] ?? 'Default Event')
            .toSet()
            .toList();
    return eventNames;
  }

  // Update the _applyFilters method's event filter section

  Future<void> _loadTransactions() async {
    final transactions = await _dbHelper.getUserTransactions(
      widget.currentUser.userId,
    );
    print('All Transactions loaded:');
    for (var transaction in transactions) {
      print(
        'Transaction: ID=${transaction.transactionId}, EventID=${transaction.eventId}, Amount=${transaction.amount}, PaymentMethod=${transaction.paymentMethod}',
      );
    }
    setState(() {
      _transactions = transactions;
      _applyFilters();
    });
    print('Transactions loaded: ${_transactions.first}');
    await _loadEventNames(); // Load event names before applying filters
  }

  void _applyFilters() {
    List<TransactionModel> filtered = List.from(_transactions);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (t) =>
                    t.paymentMethod.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (t.note?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false) ||
                    (t.eventId.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    )),
              )
              .toList();
    }
    if (_selectedEvent != null && _selectedEvent != 'All') {
      if (_selectedEvent == 'Default Event') {
        print("selected event: $_selectedEvent");

        filtered = filtered.where((t) => t.eventId == 'default').toList();
      } else {
        final eventId =
            _eventNames.entries
                .firstWhere(
                  (entry) => entry.value == _selectedEvent,
                  orElse: () => MapEntry(_selectedEvent!, _selectedEvent!),
                )
                .key;
        filtered = filtered.where((t) => t.eventId == eventId).toList();
      }
    }
    // Apply type filter
    if (_selectedType != null && _selectedType != 'All') {
      filtered =
          filtered
              .where(
                (t) =>
                    (_selectedType == 'Credit' && t.isCredit) ||
                    (_selectedType == 'Debit' && !t.isCredit),
              )
              .toList();
    }

    // Apply payment method filter
    if (_selectedPaymentMethod != null && _selectedPaymentMethod != 'All') {
      filtered =
          filtered
              .where((t) => t.paymentMethod == _selectedPaymentMethod)
              .toList();
    }
    // Apply event filter

    // Apply date range filter
    if (_selectedDateRange != null) {
      filtered =
          filtered
              .where(
                (t) =>
                    t.dateTime.isAfter(_selectedDateRange!.start) &&
                    t.dateTime.isBefore(
                      _selectedDateRange!.end.add(Duration(days: 1)),
                    ),
              )
              .toList();
    }

    // Apply online/offline filter
    if (_isOnline != null) {
      filtered = filtered.where((t) => t.isOnline == _isOnline).toList();
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child:
                _filteredTransactions.isEmpty
                    ? Center(child: Text('No transactions found'))
                    : ListView.builder(
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(
                          _filteredTransactions[index],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Type',
            selectedValue: _selectedType,
            options: ['All', 'Credit', 'Debit'],
            onSelected: (value) {
              setState(() {
                _selectedType = _selectedType == value ? null : value;
                _applyFilters();
              });
            },
          ),
          SizedBox(width: 8),
          _buildFilterChip(
            label: 'Payment Method',
            selectedValue: _selectedPaymentMethod,
            options: ['All', ..._getUniquePaymentMethods()],
            onSelected: (value) {
              setState(() {
                _selectedPaymentMethod =
                    _selectedPaymentMethod == value ? null : value;
                _applyFilters();
              });
            },
          ),
          SizedBox(width: 8),
          _buildFilterChip(
            label: 'Event',
            selectedValue: _selectedEvent,
            options: ['All', ..._getUniqueEvents()],
            onSelected: (value) {
              setState(() {
                _selectedEvent = _selectedEvent == value ? null : value;
                _applyFilters();
              });
            },
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Date Range'),
            selected: _selectedDateRange != null,
            onSelected: (selected) async {
              if (selected) {
                final DateTimeRange? range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  setState(() {
                    _selectedDateRange = range;
                    _applyFilters();
                  });
                }
              } else {
                setState(() {
                  _selectedDateRange = null;
                  _applyFilters();
                });
              }
            },
          ),
          SizedBox(width: 8),
          _buildFilterChip(
            label: 'Mode',
            selectedValue:
                _isOnline == null ? null : (_isOnline! ? 'Online' : 'Offline'),
            options: ['Online', 'Offline'],
            onSelected: (value) {
              setState(() {
                if (_isOnline == null) {
                  _isOnline = value == 'Online';
                } else if (_isOnline == (value == 'Online')) {
                  _isOnline = null;
                } else {
                  _isOnline = value == 'Online';
                }
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? selectedValue,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text(
          selectedValue ?? label,
          style: TextStyle(
            color: selectedValue != null ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor:
            selectedValue != null
                ? Theme.of(context).primaryColor
                : Colors.grey[200],
      ),
      itemBuilder:
          (context) =>
              options
                  .map(
                    (option) =>
                        PopupMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),
      onSelected: onSelected,
    );
  }

  List<String> _getUniquePaymentMethods() {
    return _transactions.map((t) => t.paymentMethod).toSet().toList();
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isCredit ? Colors.green : Colors.red,
          child: Icon(
            transaction.isCredit ? Icons.add : Icons.remove,
            color: Colors.white,
          ),
        ),
        title: Text(transaction.paymentMethod),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.note?.isNotEmpty ?? false) 
              Text(
                transaction.note!,
                style: TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              '${transaction.dateTime.toString().split('.')[0]} • ${transaction.location}',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 2),
            Wrap(
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet, size: 12, color: Colors.blue),
                    SizedBox(width: 2),
                    Text(
                      '${CurrencyFormatter.format(transaction.onlineBalanceAfter, widget.currentUser.currencyName)}',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.money_off, size: 12, color: Colors.orange),
                    SizedBox(width: 2),
                    Text(
                      '${CurrencyFormatter.format(transaction.offlineBalanceAfter, widget.currentUser.currencyName)}',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          '${transaction.isCredit ? '+' : '-'}${CurrencyFormatter.format(transaction.amount, widget.currentUser.currencyName)}',
          style: TextStyle(
            color: transaction.isCredit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
