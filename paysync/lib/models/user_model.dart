import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String username;
  final String? email;
  final String profileImageUrl;
  final String defaultCurrency;
  double onlineAmount;
  double offlineAmount;
  final List<String> savingsGoals; // Add this

  final List<String> events;
  final String defaultEventId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, bool> preferences;
  final String currencySymbol;
  final String currencyName;

  UserModel({
    required this.userId,
    required this.username,
    this.email,
    required this.profileImageUrl,
    required this.defaultCurrency,
    required this.onlineAmount,
    required this.offlineAmount,
    required this.events,
    required this.defaultEventId,
    required this.createdAt,
    required this.updatedAt,
    required this.preferences,
    required this.currencySymbol,
    required this.currencyName,
    this.savingsGoals = const [], // Initialize with an empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'defaultCurrency': defaultCurrency,
      'onlineAmount': onlineAmount,
      'offlineAmount': offlineAmount,
      'events': events,
      'defaultEventId': defaultEventId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferences': preferences,
      'currencySymbol': currencySymbol,
      'currencyName': currencyName,
      'savingsGoals': savingsGoals,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      email: map['email'],
      profileImageUrl: map['profileImageUrl'] ?? '',
      defaultCurrency: map['defaultCurrency'] ?? 'USD',
      onlineAmount: (map['onlineAmount'] ?? 0).toDouble(),
      offlineAmount: (map['offlineAmount'] ?? 0).toDouble(),
      events: List<String>.from(map['events'] ?? []),
      defaultEventId: map['defaultEventId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      currencySymbol: map['currencySymbol'] ?? '\$',
      currencyName: map['currencyName'] ?? 'USD',
      preferences: Map<String, bool>.from(map['preferences'] ?? {}),
      savingsGoals: List<String>.from(map['savingsGoals'] ?? []),
    );
  }

  UserModel copyWith({
    String? userId,
    String? username,
    String? email,
    String? profileImageUrl,
    String? defaultCurrency,
    double? onlineAmount,
    double? offlineAmount,
    List<String>? events,
    String? defaultEventId,
    List<String>? savingsGoals,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, bool>? preferences,
    String? currencySymbol,
    String? currencyName,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      onlineAmount: onlineAmount ?? this.onlineAmount,
      offlineAmount: offlineAmount ?? this.offlineAmount,
      events: events ?? this.events,
      defaultEventId: defaultEventId ?? this.defaultEventId,
      savingsGoals: savingsGoals ?? this.savingsGoals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyName: currencyName ?? this.currencyName,
    );
  }
}
