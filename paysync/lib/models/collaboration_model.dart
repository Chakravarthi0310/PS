import 'package:cloud_firestore/cloud_firestore.dart';

class CollaborationModel {
  final String eventId;
  final String inviterId;
  final String inviteeEmail;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final DateTime? respondedAt;

  CollaborationModel({
    required this.eventId,
    required this.inviterId,
    required this.inviteeEmail,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'inviterId': inviterId,
    'inviteeEmail': inviteeEmail,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
  };

  factory CollaborationModel.fromMap(Map<String, dynamic> map) {
    return CollaborationModel(
      eventId: map['eventId'] ?? '',
      inviterId: map['inviterId'] ?? '',
      inviteeEmail: map['inviteeEmail'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      respondedAt: map['respondedAt'] != null 
          ? (map['respondedAt'] as Timestamp).toDate() 
          : null,
    );
  }
}