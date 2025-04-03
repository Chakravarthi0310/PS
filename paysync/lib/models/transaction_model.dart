import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String transactionId;
  final String userId;
  final String eventId;
  final bool isOnline;
  final bool isCredit;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String location;
  final DateTime dateTime;
  final String? note;
  final String? imageUrl;
  final bool recurring;
  final String? recurringType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double onlineBalanceAfter; // New field
  final double offlineBalanceAfter; // New field

  TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.eventId,
    required this.isOnline,
    required this.isCredit,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.location,
    required this.dateTime,
    this.note,
    this.imageUrl,
    required this.recurring,
    this.recurringType,
    required this.createdAt,
    required this.updatedAt,
    required this.onlineBalanceAfter, // Add to constructor
    required this.offlineBalanceAfter, // Add to constructor
  });
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      transactionId: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      isCredit: data['isCredit'] ?? false,
      note: data['note'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      currency: data['currency'] ?? 'USD',
      paymentMethod: data['paymentMethod'] ?? '',
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      recurring: data['recurring'] ?? false,
      recurringType: data['recurringType'],
      onlineBalanceAfter:
          (data['onlineBalanceAfter'] ?? data['amount'] ?? 0).toDouble(),
      offlineBalanceAfter:
          (data['offlineBalanceAfter'] ?? data['amount'] ?? 0).toDouble(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'eventId': eventId,
      'isOnline': isOnline,
      'isCredit': isCredit,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'location': location,
      'dateTime': Timestamp.fromDate(dateTime),
      'note': note,
      'imageUrl': imageUrl,
      'recurring': recurring,
      'recurringType': recurringType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'onlineBalanceAfter': onlineBalanceAfter, // Add to map
      'offlineBalanceAfter': offlineBalanceAfter, // Add to map
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['transactionId'] ?? '',
      userId: map['userId'] ?? '',
      eventId: map['eventId'] ?? '',
      isOnline: map['isOnline'] ?? false,
      isCredit: map['isCredit'] ?? false,
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      paymentMethod: map['paymentMethod'] ?? '',
      location: map['location'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      note: map['note'],
      imageUrl: map['imageUrl'],
      recurring: map['recurring'] ?? false,
      recurringType: map['recurringType'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Add null-safe handling for new fields
      onlineBalanceAfter:
          (map['onlineBalanceAfter'] ?? map['amount'] ?? 0).toDouble(),
      offlineBalanceAfter:
          (map['offlineBalanceAfter'] ?? map['amount'] ?? 0).toDouble(),
    );
  }
}
