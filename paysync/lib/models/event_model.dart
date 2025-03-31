import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String nameOfEvent;
  final String createdBy;
  final List<String> transactions;
  final double onlineAmountOfEvent;
  final double offlineAmountOfEvent;
  final List<String> members;
  final String currency;
  final double? budget;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.eventId,
    required this.nameOfEvent,
    required this.createdBy,
    required this.transactions,
    required this.onlineAmountOfEvent,
    required this.offlineAmountOfEvent,
    required this.members,
    required this.currency,
    this.budget,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'nameOfEvent': nameOfEvent,
      'createdBy': createdBy,
      'transactions': transactions,
      'onlineAmountOfEvent': onlineAmountOfEvent,
      'offlineAmountOfEvent': offlineAmountOfEvent,
      'members': members,
      'currency': currency,
      'budget': budget,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      eventId: map['eventId'] ?? '',
      nameOfEvent: map['nameOfEvent'] ?? '',
      createdBy: map['createdBy'] ?? '',
      transactions: List<String>.from(map['transactions'] ?? []),
      onlineAmountOfEvent: (map['onlineAmountOfEvent'] ?? 0).toDouble(),
      offlineAmountOfEvent: (map['offlineAmountOfEvent'] ?? 0).toDouble(),
      members: List<String>.from(map['members'] ?? []),
      currency: map['currency'] ?? 'USD',
      budget: map['budget']?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  EventModel copyWith({
      String? eventId,
      String? nameOfEvent,
      String? createdBy,
      List<String>? transactions,
      double? onlineAmountOfEvent,
      double? offlineAmountOfEvent,
      List<String>? members,
      String? currency,
      double? budget,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      return EventModel(
        eventId: eventId ?? this.eventId,
        nameOfEvent: nameOfEvent ?? this.nameOfEvent,
        createdBy: createdBy ?? this.createdBy,
        transactions: transactions ?? List.from(this.transactions),
        onlineAmountOfEvent: onlineAmountOfEvent ?? this.onlineAmountOfEvent,
        offlineAmountOfEvent: offlineAmountOfEvent ?? this.offlineAmountOfEvent,
        members: members ?? List.from(this.members),
        currency: currency ?? this.currency,
        budget: budget ?? this.budget,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
    }
}