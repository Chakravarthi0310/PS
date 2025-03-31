class SavingsGoalModel {
  final String goalId;
  final String goalName;
  final double targetAmount;
  final double currentSavings;
  final DateTime deadline;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String currency; // Add this field

  SavingsGoalModel({
    required this.goalId,
    required this.goalName,
    required this.targetAmount,
    required this.currentSavings,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.currency, // Add this parameter
  });

  Map<String, dynamic> toMap() {
    return {
      'goalId': goalId,
      'goalName': goalName,
      'targetAmount': targetAmount,
      'currentSavings': currentSavings,
      'deadline': deadline.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'currency': currency, // Add this field
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      goalId: map['goalId'],
      goalName: map['goalName'],
      targetAmount: map['targetAmount'],
      currentSavings: map['currentSavings'],
      deadline: DateTime.parse(map['deadline']),
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      currency: map['currency'] ?? 'USD', // Add with default value
    );
  }

  SavingsGoalModel copyWith({
    String? goalId,
    String? goalName,
    double? targetAmount,
    double? currentSavings,
    DateTime? deadline,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currency,
  }) {
    return SavingsGoalModel(
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      targetAmount: targetAmount ?? this.targetAmount,
      currentSavings: currentSavings ?? this.currentSavings,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currency: currency ?? this.currency,
    );
  }
}
