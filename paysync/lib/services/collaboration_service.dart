import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collaboration_model.dart';

class CollaborationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> inviteToEvent(String eventId, String inviterId, String inviteeEmail) async {
    final collaboration = CollaborationModel(
      eventId: eventId,
      inviterId: inviterId,
      inviteeEmail: inviteeEmail,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _firestore.collection('collaborations').add(collaboration.toMap());
  }

  Future<void> respondToInvitation(String collaborationId, String status) async {
    await _firestore.collection('collaborations').doc(collaborationId).update({
      'status': status,
      'respondedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'accepted') {
      final collab = await _firestore
          .collection('collaborations')
          .doc(collaborationId)
          .get();
      
      final eventId = collab.data()?['eventId'];
      final inviteeEmail = collab.data()?['inviteeEmail'];

      // Get user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: inviteeEmail)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userId = userQuery.docs.first.id;
        
        // Add to event members
        await _firestore.collection('events').doc(eventId).update({
          'members': FieldValue.arrayUnion([userId])
        });
      }
    }
  }

  Stream<List<CollaborationModel>> getPendingInvitations(String userEmail) {
    return _firestore
        .collection('collaborations')
        .where('inviteeEmail', isEqualTo: userEmail)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CollaborationModel.fromMap(doc.data()))
            .toList());
  }
}