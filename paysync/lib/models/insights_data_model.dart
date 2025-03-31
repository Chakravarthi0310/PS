class InsightsDataModel {
  final Map<String, double> savingsProgress;
  final double onlineBalance;
  final double offlineBalance;
  final Map<DateTime, double> spendingHeatmap;
  final List<TransactionFlow> cashFlow;
  final List<EventBudgetUtilization> eventBudgets;
  final List<PaymentMethod> paymentMethods;

  InsightsDataModel({
    required this.savingsProgress,
    required this.onlineBalance,
    required this.offlineBalance,
    required this.spendingHeatmap,
    required this.cashFlow,
    required this.eventBudgets,
    required this.paymentMethods,
  });
}

class TransactionFlow {
  final DateTime date;
  final double income;
  final double expenses;

  TransactionFlow({
    required this.date,
    required this.income,
    required this.expenses,
  });
}

class EventBudgetUtilization {
  final String eventName;
  final double budget;
  final double spent;

  EventBudgetUtilization({
    required this.eventName,
    required this.budget,
    required this.spent,
  });
}

class PaymentMethod {
  final String type;
  final String lastFourDigits;
  final String holderName;
  final String expiryDate;

  PaymentMethod({
    required this.type,
    required this.lastFourDigits,
    required this.holderName,
    required this.expiryDate,
  });
}