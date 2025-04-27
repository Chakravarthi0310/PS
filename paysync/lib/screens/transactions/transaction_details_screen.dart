import 'dart:io';
import 'package:flutter/material.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:paysync/utils/currency_formatter.dart';
import 'package:share_plus/share_plus.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final TransactionModel transaction;
  final UserModel currentUser;

  const TransactionDetailsScreen({
    Key? key,
    required this.transaction,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double displayAmount = transaction.amount;
    if (transaction.currency != currentUser.currencyName) {
      displayAmount = CurrencyConverter.convert(
        transaction.amount,
        transaction.currency,
        currentUser.currencyName,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareTransaction(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Section with Amount
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '${transaction.isCredit ? 'Income' : 'Expense'}',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  '${transaction.isCredit ? '+' : '-'}${CurrencyFormatter.format(displayAmount, currentUser.currencyName)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (transaction.currency != currentUser.currencyName)
                  Text(
                    '(${CurrencyFormatter.format(transaction.amount, transaction.currency)})',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
              ],
            ),
          ),

          // Bottom Section with Details
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Image/Receipt
                    if (transaction.imageUrl?.isNotEmpty ?? false)
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildTransactionImage(),
                        ),
                      ),

                    // Details Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 1.5,
                      children: [
                        _buildDetailCard(
                          'Payment Method',
                          transaction.paymentMethod,
                          Icons.payment,
                          Colors.blue,
                        ),
                        _buildDetailCard(
                          'Date',
                          transaction.dateTime.toString().split(' ')[0],
                          Icons.calendar_today,
                          Colors.orange,
                        ),
                        _buildDetailCard(
                          'Time',
                          transaction.dateTime
                              .toString()
                              .split(' ')[1]
                              .split('.')[0],
                          Icons.access_time,
                          Colors.purple,
                        ),
                        _buildDetailCard(
                          'Location',
                          transaction.location,
                          Icons.location_on,
                          Colors.green,
                        ),
                        _buildDetailCard(
                          'Mode',
                          transaction.isOnline ? 'Online' : 'Offline',
                          transaction.isOnline ? Icons.wifi : Icons.wifi_off,
                          transaction.isOnline ? Colors.teal : Colors.brown,
                        ),
                        _buildDetailCard(
                          'Type',
                          transaction.isCredit ? 'Credit' : 'Debit',
                          transaction.isCredit ? Icons.add_circle : Icons.remove_circle,
                          transaction.isCredit ? Colors.green : Colors.red,
                        ),
                      ],
                    ),

                    // Balance Information
                    SizedBox(height: 20),
                    Text(
                      'Balance After Transaction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Online Balance',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  CurrencyFormatter.format(transaction.onlineBalanceAfter, currentUser.currencyName),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.money_off, color: Colors.orange, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Offline Balance',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  CurrencyFormatter.format(transaction.offlineBalanceAfter, currentUser.currencyName),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Note Section (if exists)
                    if (transaction.note?.isNotEmpty ?? false) ...[
                      SizedBox(height: 20),
                      Text(
                        'Note',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          transaction.note!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionImage() {
    return transaction.imageUrl!.startsWith('http')
        ? Image.network(
          transaction.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(Icons.error_outline, size: 40, color: Colors.grey),
        )
        : Image.file(
          File(transaction.imageUrl!.replaceAll(RegExp(r'file:\/\/\/'), '')),
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(Icons.error_outline, size: 40, color: Colors.grey),
        );
  }

  void _shareTransaction(BuildContext context) {
    String shareText = '''
Transaction Details:
Type: ${transaction.isCredit ? 'Income' : 'Expense'}
Amount: ${CurrencyFormatter.format(transaction.amount, transaction.currency)}
Payment Method: ${transaction.paymentMethod}
Date: ${transaction.dateTime.toString().split('.')[0]}
Location: ${transaction.location}
${transaction.note?.isNotEmpty ?? false ? 'Note: ${transaction.note}' : ''}
''';
    Share.share(shareText);
  }
}
