import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/screens/events/invite_screen.dart';
import '../models/event_model.dart';

class MemberManagementWidget extends StatelessWidget {
  final EventModel event;
  final String currentUserId;

  const MemberManagementWidget({
    Key? key,
    required this.event,
    required this.currentUserId,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> _getMembersData() async {
    final membersData = <Map<String, dynamic>>[];

    try {
      // First, get the creator's data
      final creatorDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(event.createdBy)
              .get();
      print(creatorDoc);
      if (creatorDoc.exists) {
        membersData.add({
          'id': creatorDoc.id,
          'name': creatorDoc.data()?['username'] ?? 'Unknown',
          'email': creatorDoc.data()?['email'] ?? 'No email',
          'isCreator': true,
        });
      }

      print("members: ${event.members}");

      // Then get other members' data
      List<String> otherMembers =
          event.members
              .where(
                (memberId) =>
                    memberId != event.createdBy && memberId.isNotEmpty,
              )
              .toList();
      print("other members: ${otherMembers}");
      if (otherMembers.isNotEmpty) {
        final userDocs =
            await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: otherMembers)
                .get();

        for (var doc in userDocs.docs) {
          membersData.add({
            'id': doc.id,
            'name': doc.data()['username'] ?? 'Unknown',
            'email': doc.data()['email'] ?? 'No email',
            'isCreator': false,
          });
        }
      }

      print("Members data: $membersData"); // Debug print
      return membersData;
    } catch (e) {
      print('Error fetching members: $e');
      return membersData;
    }
  }

  Future<void> _removeMember(BuildContext context, String memberId) async {
    if (event.createdBy == currentUserId) {
      try {
        // Update Firestore
        await DatabaseHelper().removeMemberFromEvent(event.eventId, memberId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member removed successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove member: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Members',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (event.createdBy == currentUserId)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Member'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => InviteScreen(
                                eventId: event.eventId,
                                userId: currentUserId,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getMembersData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No members');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final member = snapshot.data![index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(member['name'][0].toUpperCase()),
                      ),
                      title: Text(member['name']),
                      subtitle: Text(member['email']),
                      trailing:
                          event.createdBy == currentUserId &&
                                  !member['isCreator']
                              ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                                onPressed:
                                    () => _removeMember(context, member['id']),
                              )
                              : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
