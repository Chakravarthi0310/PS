import 'package:flutter/material.dart';
import 'package:paysync/models/event_model.dart';
import 'package:paysync/models/transaction_model.dart';

class MemberActivityChart extends StatelessWidget {
  final List<EventModel> events;
  final List<TransactionModel> transactions;

  const MemberActivityChart({
    Key? key,
    required this.events,
    required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementation
    return Container();
  }
}
