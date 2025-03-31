import 'package:flutter/material.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/savings_goal_model.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:paysync/utils/currency_formatter.dart';

class ManageSavingsScreen extends StatefulWidget {
  final UserModel currentUser;
  final SavingsGoalModel savingsGoal;

  const ManageSavingsScreen({
    Key? key,
    required this.currentUser,
    required this.savingsGoal,
  }) : super(key: key);

  @override
  _ManageSavingsScreenState createState() => _ManageSavingsScreenState();
}

class _ManageSavingsScreenState extends State<ManageSavingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isAdding = true;
  bool _isOnline = true;
  String _selectedCurrency = '';

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentUser.currencyName;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      default:
        return '\$';
    }
  }

  Future<void> _processSavingsUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    double amount = double.parse(_amountController.text);
    // Convert amount if currencies are different
    double convertedAmount = amount;
    if (_selectedCurrency != widget.currentUser.currencyName) {
      convertedAmount = CurrencyConverter.convert(
        amount,
        _selectedCurrency,
        widget.currentUser.currencyName,
      );
    }

    try {
      // Update user balance
      UserModel updatedUser = widget.currentUser;
      if (_isOnline) {
        updatedUser = updatedUser.copyWith(
          // When adding to savings, subtract from balance; when removing, add to balance
          onlineAmount:
              updatedUser.onlineAmount + (_isAdding ? -amount : amount),
        );
      } else {
        updatedUser = updatedUser.copyWith(
          // When adding to savings, subtract from balance; when removing, add to balance
          offlineAmount:
              updatedUser.offlineAmount + (_isAdding ? -amount : amount),
        );
      }

      final bool goalReached =
          (widget.savingsGoal.currentSavings +
              (_isAdding ? convertedAmount : -convertedAmount)) >=
          widget.savingsGoal.targetAmount;

      // Update savings goal
      final updatedGoal = widget.savingsGoal.copyWith(
        currentSavings:
            widget.savingsGoal.currentSavings +
            (_isAdding ? convertedAmount : -convertedAmount),
        updatedAt: DateTime.now(),
        status: goalReached ? 'completed' : 'in-progress',
      );

      // Create a transaction record
      final transaction = TransactionModel(
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.currentUser.userId,
        eventId: widget.currentUser.defaultEventId,
        isOnline: _isOnline,
        isCredit:
            !_isAdding, // credit when removing from savings (adding to balance)
        amount: amount,
        currency: _selectedCurrency,
        paymentMethod: 'Savings Transfer',
        location: 'Savings',
        dateTime: DateTime.now(),
        note:
            _isAdding
                ? 'Added to savings: ${widget.savingsGoal.goalName}'
                : 'Removed from savings: ${widget.savingsGoal.goalName}',
        recurring: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        onlineBalanceAfter: updatedUser.onlineAmount,
        offlineBalanceAfter: updatedUser.offlineAmount,
      );

      final db = DatabaseHelper();
      await db.updateUser(updatedUser);
      await db.updateSavingsGoal(updatedGoal);
      await db.insertTransaction(transaction);

      if (goalReached && _isAdding) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Wrap(
              children: [
                Text(
                  'Congratulations! You\'ve reached your savings goal for ${widget.savingsGoal.goalName}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update savings'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Text(
          _isAdding ? 'Add to Savings' : 'Remove from Savings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
              Colors.white,
            ],
            stops: [0.0, 0.2, 0.2],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Info Card with enhanced design
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 30,
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              widget.savingsGoal.goalName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value:
                              widget.savingsGoal.currentSavings /
                              widget.savingsGoal.targetAmount,
                          backgroundColor: Colors.grey[200],
                          minHeight: 8,
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(
                                  widget.savingsGoal.currentSavings,
                                  widget.currentUser.currencyName,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Target',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(
                                  widget.savingsGoal.targetAmount,
                                  widget.currentUser.currencyName,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),

                // Main Form Container
                Container(
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Action Type Toggle with new style
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: true,
                              label: Text('Add'),
                              icon: Icon(Icons.add_circle_outline),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('Remove'),
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                          ],
                          selected: {_isAdding},
                          onSelectionChanged: (Set<bool> selected) {
                            setState(() {
                              _isAdding = selected.first;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 20),

                      // Amount Input with enhanced style
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: 'Enter amount',
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 12,
                            ),
                            child: Text(
                              getCurrencySymbol(_selectedCurrency),
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          double amount = double.parse(value);
                          if (amount <= 0) {
                            return 'Amount must be greater than 0';
                          }

                          // Only check balance when adding to savings
                          if (_isAdding) {
                            if (_isOnline &&
                                amount > widget.currentUser.onlineAmount) {
                              return 'Insufficient online balance';
                            }
                            if (!_isOnline &&
                                amount > widget.currentUser.offlineAmount) {
                              return 'Insufficient offline balance';
                            }
                          } else {
                            // When removing from savings, check if enough savings available
                            if (amount > widget.savingsGoal.currentSavings) {
                              return 'Insufficient savings balance';
                            }
                          }
                          return null;
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          _isAdding
                              ? 'Deduct from ${_isOnline ? 'online' : 'offline'} balance'
                              : 'Add to ${_isOnline ? 'online' : 'offline'} balance',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Balance Type Toggle with new style
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: true,
                              label: Text('Online'),
                              icon: Icon(Icons.wifi),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('Offline'),
                              icon: Icon(Icons.wifi_off),
                            ),
                          ],
                          selected: {_isOnline},
                          onSelectionChanged: (Set<bool> selected) {
                            setState(() {
                              _isOnline = selected.first;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 20),

                      // Currency Selector with enhanced style
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: InputDecoration(
                          labelText: 'Currency',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        items:
                            ['USD', 'EUR', 'GBP', 'JPY', 'INR'].map((
                              String currency,
                            ) {
                              return DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCurrency = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Submit Button with enhanced style
                Container(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _processSavingsUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                      shadowColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isAdding ? Icons.add : Icons.remove,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          _isAdding ? 'Add to Savings' : 'Remove from Savings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
