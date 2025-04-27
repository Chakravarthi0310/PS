import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/event_model.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/widgets/common/futuristic_app_bar.dart';
import 'package:paysync/widgets/insightWidgets/insight_card.dart';
import 'package:paysync/widgets/insightWidgets/pie_chart_card.dart';
import 'package:paysync/widgets/insightWidgets/event_spending_card.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';

class InsightsScreen extends StatefulWidget {
  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  List<TransactionModel> _transactions = [];
  List<EventModel> _events = [];
  String _selectedPeriod = 'Month';
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      _currentUser = await DatabaseHelper().getUser(currentUser!.uid);
      final transactions = await DatabaseHelper().getUserTransactions(
        currentUser.uid,
      );
      final events = await DatabaseHelper().getUserEvents(currentUser.uid);
      setState(() {
        _transactions = transactions;
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading insights data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load insights')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FuturisticAppBar(title: 'Insights'),
      body:
          _isLoading || _currentUser == null
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButton<String>(
                            value: _selectedPeriod,
                            items:
                                ['Week', 'Month', 'Year']
                                    .map(
                                      (period) => DropdownMenuItem(
                                        value: period,
                                        child: Text(period),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() => _selectedPeriod = value!);
                            },
                          ),
                          if (_events.isNotEmpty)
                            DropdownButton<String>(
                              value: _selectedEventId,
                              hint: Text('All Events'),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('All Events'),
                                ),
                                // DropdownMenuItem(
                                //   value: '',
                                //   child: Text('Default Event'),
                                // ),
                                ..._events.map(
                                  (event) => DropdownMenuItem(
                                    value: event.eventId,
                                    child: Text(event.nameOfEvent),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedEventId = value);
                              },
                            ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildOverallMetricsCard(),
                      SizedBox(height: 20),
                      _buildBudgetGaugeCard(),
                      SizedBox(height: 20),
                      InsightCard(
                        title: 'Total Spending',
                        transactions: _transactions,
                        selectedEventId: _selectedEventId,
                        period: _selectedPeriod,
                        currentUser: _currentUser!,
                      ),
                      SizedBox(height: 20),
                      _buildMemberActivityCard(),
                      SizedBox(height: 20),
                      PieChartCard(
                        transactions: _transactions,
                        selectedEventId: _selectedEventId,
                        period: _selectedPeriod,
                      ),
                      SizedBox(height: 20),
                      _buildPaymentMethodDistribution(),
                      SizedBox(height: 20),
                      _buildEventComparisonChart(),
                      if (_selectedEventId == null) ...[
                        SizedBox(height: 20),
                        Text(
                          'Event-wise Spending',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 12),
                        ...(_events.map(
                          (event) => Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: EventSpendingCard(
                              event: event,
                              transactions: _transactions,
                              period: _selectedPeriod,
                              currentUser: _currentUser!,
                            ),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildOverallMetricsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('Total Events', _events.length.toString()),
                _buildMetricItem(
                  'Active Members',
                  _events
                      .fold<Set<String>>(
                        {},
                        (prev, event) => prev..addAll(event.members),
                      )
                      .length
                      .toString(),
                ),
                _buildMetricItem(
                  'Transactions',
                  _transactions.length.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetGaugeCard() {
    final selectedEvent =
        _selectedEventId != null
            ? _events.firstWhere((e) => e.eventId == _selectedEventId)
            : null;

    if (selectedEvent?.budget == null) return SizedBox.shrink();

    final progress =
        -(selectedEvent!.onlineAmountOfEvent +
            selectedEvent.offlineAmountOfEvent) /
        selectedEvent.budget!;

    return Card(
      child: Container(
        height: 200,
        padding: EdgeInsets.all(16),
        child: SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 100,
              ranges: <GaugeRange>[
                GaugeRange(
                  startValue: 0,
                  endValue: progress * 100,
                  color: _getBudgetColor(progress),
                  startWidth: 20,
                  endWidth: 20,
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Text(
                    '${(progress * 100).toStringAsFixed(1)}%\nBudget Used',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  angle: 90,
                  positionFactor: 0.5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberActivityCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxActivityValue(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final members = _getTopMembers();
                          if (value.toInt() >= members.length) return Text('');
                          return Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              members[value.toInt()]['name'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barGroups: _getMemberActivityData(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getMemberActivityData() {
    // Get all unique member IDs from events
    final Set<String> allMemberIds = _events.fold<Set<String>>(
      {},
      (prev, event) => prev..addAll(event.members),
    );

    // Filter transactions based on selected period and event
    final filteredTransactions = _transactions.where((transaction) {
      if (_selectedEventId != null && transaction.eventId != _selectedEventId) {
        return false;
      }
      return _isInSelectedPeriod(transaction.dateTime);
    }).toList();

    // Calculate activity for each member
    final memberActivity = <String, int>{};
    for (final memberId in allMemberIds) {
      final memberTransactions = filteredTransactions.where(
        (t) => t.userId == memberId,
      );
      memberActivity[memberId] = memberTransactions.length;
    }

    // Sort members by activity
    final sortedMembers = memberActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top 5 most active members
    final topMembers = sortedMembers.take(5).toList();

    // Create bar chart data
    return List.generate(
      topMembers.length,
      (index) {
        final member = topMembers[index];
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: member.value.toDouble(),
              color: Theme.of(context).primaryColor,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      },
    );
  }

  bool _isInSelectedPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Week':
        return date.isAfter(now.subtract(Duration(days: 7)));
      case 'Month':
        return date.isAfter(now.subtract(Duration(days: 30)));
      case 'Year':
        return date.isAfter(now.subtract(Duration(days: 365)));
      default:
        return true;
    }
  }

  double _getMaxActivityValue() {
    final activityData = _getMemberActivityData();
    if (activityData.isEmpty) return 10;
    return activityData
        .map((group) => group.barRods.first.toY)
        .reduce((a, b) => a > b ? a : b)
        .ceilToDouble();
  }

  List<Map<String, dynamic>> _getTopMembers() {
    final Set<String> allMemberIds = _events.fold<Set<String>>(
      {},
      (prev, event) => prev..addAll(event.members),
    );

    final filteredTransactions = _transactions.where((transaction) {
      if (_selectedEventId != null && transaction.eventId != _selectedEventId) {
        return false;
      }
      return _isInSelectedPeriod(transaction.dateTime);
    }).toList();

    final memberActivity = <String, int>{};
    for (final memberId in allMemberIds) {
      final memberTransactions = filteredTransactions.where(
        (t) => t.userId == memberId,
      );
      memberActivity[memberId] = memberTransactions.length;
    }

    final sortedMembers = memberActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMembers.take(5).map((entry) {
      return {
        'id': entry.key,
        'name': _getMemberName(entry.key),
        'count': entry.value,
      };
    }).toList();
  }

  String _getMemberName(String memberId) {
    // This is a placeholder - you should implement proper member name lookup
    // from your user database
    return 'Member ${memberId.substring(0, 4)}';
  }

  Widget _buildPaymentMethodDistribution() {
    // Implementation for payment method distribution
    return Card();
  }

  Widget _buildEventComparisonChart() {
    // Implementation for event comparison chart
    return Card();
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Color _getBudgetColor(double progress) {
    if (progress > 1) return Colors.red;
    if (progress > 0.8) return Colors.orange;
    return Colors.green;
  }
}
