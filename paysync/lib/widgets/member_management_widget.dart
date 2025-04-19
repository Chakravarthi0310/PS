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
      // Get creator's data first
      final creatorDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(event.createdBy)
              .get();

      if (creatorDoc.exists && creatorDoc.data() != null) {
        final creatorData = creatorDoc.data()!;
        membersData.add({
          'id': creatorDoc.id,
          'name': creatorData['username'] ?? 'Unknown',
          'email': creatorData['email'] ?? 'No email',
          'isCreator': true,
        });
      }

      // Get other members' data
      if (event.members.isNotEmpty) {
        final otherMembers =
            event.members
                .where(
                  (memberId) =>
                      memberId.isNotEmpty && memberId != event.createdBy,
                )
                .toList();

        if (otherMembers.isNotEmpty) {
          final userDocs =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: otherMembers)
                  .get();

          for (var doc in userDocs.docs) {
            if (doc.exists && doc.data().isNotEmpty) {
              membersData.add({
                'id': doc.id,
                'name': doc.data()['username'] ?? 'Unknown',
                'email': doc.data()['email'] ?? 'No email',
                'isCreator': false,
              });
            }
          }
        }
      }

      return membersData;
    } catch (e) {
      print('Error fetching members: $e');
      return membersData;
    }
  }

  Future<void> _removeMember(BuildContext context, String memberId) async {
    try {
      // Show confirmation dialog
      final bool confirm =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Remove Member'),
                  content: const Text(
                    'Are you sure you want to remove this member?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Remove'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!confirm) return;

      // Remove member using DatabaseHelper
      final success = await DatabaseHelper().removeMemberFromEvent(
        event.eventId,
        memberId,
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member removed successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove member')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Member'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getMembersData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No members found');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final member = snapshot.data![index];
                    final String memberName = member['name'] ?? 'Unknown';
                    final String initial =
                        memberName.isNotEmpty
                            ? memberName[0].toUpperCase()
                            : '?';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          initial,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(memberName),
                      subtitle: Text(member['email'] ?? 'No email'),
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
