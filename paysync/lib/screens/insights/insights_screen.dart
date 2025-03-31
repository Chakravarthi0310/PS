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
                                DropdownMenuItem(
                                  value: 'default',
                                  child: Text('Default Event'),
                                ),
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
                  maxY: 100,
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
    // Implementation for member activity chart data
    // This would analyze member participation across events
    return [];
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
