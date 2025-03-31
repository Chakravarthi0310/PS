import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/savings_goal_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/screens/savings/add_savings_goal_screen.dart';
import 'package:paysync/screens/savings/manage_savings_screen.dart';
import 'package:paysync/screens/transactions/transaction_details_screen.dart';
import 'package:paysync/screens/transactions/transactions_screen.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:paysync/utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// In your HomeScreen classr
class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<TransactionModel> _recentTransactions = [];
  List<SavingsGoalModel> _savingsGoals = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTransactions();
    _loadSavingsGoals();
  }

  Future<void> _loadSavingsGoals() async {
    if (_currentUser != null) {
      try {
        final goals = await _dbHelper.getUserSavingsGoals(_currentUser!.userId);
        print('Loaded savings goals: ${goals.length}'); // Debug log
        if (mounted) {
          setState(() {
            _savingsGoals = goals;
            print(
              'Updated state with savings goals: ${_savingsGoals.length}',
            ); // Debug log
          });
        }
      } catch (e) {
        print('Error loading savings goals: $e');
      }
    }
  }

  Future<void> _loadUserData() async {
    final user = await _dbHelper.getUser(
      FirebaseAuth.instance.currentUser!.uid,
    );
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadTransactions() async {
    final transactions = await _dbHelper.getUserTransactions(
      FirebaseAuth.instance.currentUser!.uid,
    );
    if (mounted) {
      setState(() {
        _recentTransactions = transactions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildTopSection(), _buildMiddleSection()],
          ),
        ),
      ),
    );
  }

  // Remove _buildBottomNavBar() method and _selectedIndex variable
  Widget _buildTopSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${_currentUser?.username ?? 'User'}!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Welcome back',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
              // Profile Avatar
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    _currentUser?.profileImageUrl != null &&
                                            _currentUser!
                                                .profileImageUrl
                                                .isNotEmpty
                                        ? FileImage(
                                          File(_currentUser!.profileImageUrl),
                                        )
                                        : null,
                                child:
                                    _currentUser?.profileImageUrl == null ||
                                            _currentUser!
                                                .profileImageUrl
                                                .isEmpty
                                        ? Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                          size: 50,
                                        )
                                        : null,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _currentUser?.username ?? 'User',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentUser?.email ?? '',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                  );
                },
                child: Hero(
                  tag: 'profileImage',
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white24,
                    backgroundImage:
                        _currentUser?.profileImageUrl != null &&
                                _currentUser!.profileImageUrl.isNotEmpty
                            ? FileImage(File(_currentUser!.profileImageUrl))
                            : null,
                    child:
                        _currentUser?.profileImageUrl == null ||
                                _currentUser!.profileImageUrl.isEmpty
                            ? Icon(Icons.person, color: Colors.white)
                            : null,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 25),
          // Balance Cards Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Total Balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(
                            (_currentUser?.onlineAmount ?? 0) +
                                (_currentUser?.offlineAmount ?? 0),
                            _currentUser?.currencyName ?? 'USD',
                          ),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
                Divider(height: 30),
                // Online and Offline Balance Row
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceCard(
                        'Online Balance',
                        CurrencyFormatter.format(
                          _currentUser?.onlineAmount ?? 0,
                          _currentUser?.currencyName ?? 'USD',
                        ),
                        Icons.account_balance,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _buildBalanceCard(
                        'Offline Balance',
                        CurrencyFormatter.format(
                          _currentUser?.offlineAmount ?? 0,
                          _currentUser?.currencyName ?? 'USD',
                        ),
                        Icons.money,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                Divider(height: 30),
                // Savings Goal Section
                FutureBuilder<List<SavingsGoalModel>>(
                  future: _dbHelper.getUserSavingsGoals(
                    _currentUser?.userId ?? '',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final goals = snapshot.data ?? [];
                    if (goals.isEmpty) {
                      return _buildCompactAddSavingsGoalCard();
                    }
                    _savingsGoals = goals;
                    return _buildCompactSavingsGoalCard(goals.first);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCompactAddSavingsGoalCard() {
    return InkWell(
      onTap: () async {
        if (_currentUser != null) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddSavingsGoalScreen(currentUser: _currentUser!),
            ),
          );
          if (result == true) {
            await _loadSavingsGoals();
            setState(() {});
          }
        }
      },
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.savings_outlined,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              'Create Savings Goal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCompactSavingsGoalCard(SavingsGoalModel goal) {
    // Convert amounts to user's currency
    double displayCurrentSavings = goal.currentSavings;
    double displayTargetAmount = goal.targetAmount;

    if (_currentUser != null && goal.currency != _currentUser?.currencyName) {
      displayCurrentSavings = CurrencyConverter.convert(
        goal.currentSavings,
        goal.currency ?? 'USD',
        _currentUser!.currencyName,
      );
      displayTargetAmount = CurrencyConverter.convert(
        goal.targetAmount,
        goal.currency ?? 'USD',
        _currentUser!.currencyName,
      );
    }

    return Column(
      children: [
        InkWell(
          onTap: () async {
            if (_currentUser != null) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ManageSavingsScreen(
                        currentUser: _currentUser!,
                        savingsGoal: goal,
                      ),
                ),
              );
              if (result == true) {
                _loadUserData();
                _loadSavingsGoals();
              }
            }
          },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Savings Goal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          goal.status == 'completed'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      goal.status,
                      style: TextStyle(
                        color:
                            goal.status == 'completed'
                                ? Colors.green
                                : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CustomPaint(
                      painter: SemiCircleProgressPainter(
                        percentage: goal.currentSavings / goal.targetAmount,
                        primaryColor: Theme.of(context).primaryColor,
                        backgroundColor: Colors.grey[200]!,
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.goalName,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${CurrencyFormatter.format(displayCurrentSavings, _currentUser?.currencyName ?? 'USD')} / ${CurrencyFormatter.format(displayTargetAmount, _currentUser?.currencyName ?? 'USD')}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (goal.currency != _currentUser?.currencyName)
                              Text(
                                '(Original: ${CurrencyFormatter.format(goal.currentSavings, goal.currency ?? 'USD')} / ${CurrencyFormatter.format(goal.targetAmount, goal.currency ?? 'USD')})',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (goal.status == 'completed') ...[
          SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_currentUser != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddSavingsGoalScreen(currentUser: _currentUser!),
                    ),
                  );
                  if (result == true) {
                    await _loadSavingsGoals();
                    setState(() {});
                  }
                }
              },
              icon: Icon(Icons.add_circle_outline, size: 20),
              label: Text('Start New Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiddleSection() {
    return Padding(
      padding: EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                TransactionsScreen(currentUser: _currentUser!),
                      ),
                    ),
                child: Text(
                  'View All',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _recentTransactions.isEmpty
              ? Center(
                child: Text(
                  'No transactions yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recentTransactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionCard(_recentTransactions[index]);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    double displayAmount = transaction.amount;
    if (transaction.currency != _currentUser?.currencyName &&
        _currentUser?.currencyName != null) {
      displayAmount = CurrencyConverter.convert(
        transaction.amount,
        transaction.currency,
        _currentUser!.currencyName,
      );
    }
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TransactionDetailsScreen(
                    transaction: transaction,
                    currentUser: _currentUser!,
                  ),
            ),
          );
        },
        contentPadding: EdgeInsets.all(15),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              transaction.imageUrl != null && transaction.imageUrl!.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        transaction.imageUrl!.startsWith('http')
                            ? Image.network(
                              transaction.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildTransactionIcon(transaction),
                            )
                            : Image.file(
                              File(
                                transaction.imageUrl!.replaceAll(
                                  RegExp(r'file:\/\/\/'),
                                  '',
                                ),
                              ),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildTransactionIcon(transaction),
                            ),
                  )
                  : _buildTransactionIcon(transaction),
        ),
        title: Row(
          children: [
            Text(
              transaction.paymentMethod,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (transaction.note?.isNotEmpty ?? false) ...[
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  transaction.note!,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${transaction.dateTime.toString().split('.')[0]} • ${transaction.location}',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${transaction.isCredit ? '+' : '-'}${CurrencyFormatter.format(displayAmount, _currentUser?.currencyName ?? 'USD')}',
              style: TextStyle(
                color: transaction.isCredit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (transaction.currency != _currentUser?.currencySymbol)
              Text(
                '(${CurrencyFormatter.format(transaction.amount, transaction.currency)})',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(TransactionModel transaction) {
    return Icon(
      transaction.isCredit ? Icons.add_circle : Icons.remove_circle,
      color: transaction.isCredit ? Colors.green : Colors.red,
      size: 30,
    );
  }

  Widget _buildBalanceCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          SizedBox(height: 5),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class SemiCircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color primaryColor;
  final Color backgroundColor;

  SemiCircleProgressPainter({
    required this.percentage,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw shadow
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawArc(rect, pi, pi, false, shadowPaint);

    // Draw background with gradient
    final backgroundGradient = SweepGradient(
      startAngle: pi,
      endAngle: 2 * pi,
      colors: [backgroundColor.withOpacity(0.5), backgroundColor],
    );
    final backgroundPaint =
        Paint()
          ..shader = backgroundGradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round;

    // Draw progress with gradient
    final progressGradient = SweepGradient(
      startAngle: pi,
      endAngle: 2 * pi,
      colors: [primaryColor.withOpacity(0.7), primaryColor],
    );
    final foregroundPaint =
        Paint()
          ..shader = progressGradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round;

    // Draw dotted background
    final dashWidth = 4.0;
    final dashSpace = 4.0;
    final dashCount = (pi * radius) ~/ (dashWidth + dashSpace);
    final dottedBackgroundPaint =
        Paint()
          ..color = backgroundColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = pi + (i * (dashWidth + dashSpace)) / radius;
      canvas.drawArc(
        rect,
        startAngle,
        dashWidth / radius,
        false,
        dottedBackgroundPaint,
      );
    }

    // Draw main arcs
    canvas.drawArc(rect, pi, pi, false, backgroundPaint);
    canvas.drawArc(rect, pi, pi * percentage, false, foregroundPaint);

    // Draw end dot
    if (percentage > 0) {
      final dotPaint =
          Paint()
            ..color = primaryColor
            ..style = PaintingStyle.fill;
      final dotPosition = Offset(
        center.dx + radius * cos(pi + (pi * percentage)),
        center.dy + radius * sin(pi + (pi * percentage)),
      );
      canvas.drawCircle(dotPosition, 6, dotPaint);

      // Draw dot shadow
      final dotShadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.2)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(dotPosition, 7, dotShadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
