import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/event_model.dart';
import 'package:paysync/screens/events/add_event_screen.dart';
import 'package:paysync/screens/events/event_details_screen.dart';
import 'package:paysync/widgets/common/futuristic_app_bar.dart';
import 'package:paysync/widgets/eventWidgets/futuristic_event_search.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _filterEvents(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredEvents = List.from(_events);
        print("Empty seacrh");
        print(_filteredEvents);
      } else {
        final searchQuery = query.trim().toLowerCase();
        _filteredEvents =
            _events.where((event) {
              final eventName = event.nameOfEvent.toLowerCase();
              final memberEmails =
                  event.members.map((e) => e.toLowerCase()).toList();

              return eventName.contains(searchQuery) ||
                  memberEmails.any((email) => email.contains(searchQuery));
            }).toList();
        print("Seacrh gvhdsj");
        print(_filteredEvents);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FuturisticAppBar(title: 'Events'),
      body: Column(
        children: [
          FuturisticEventSearch(
            controller: _searchController,
            onSearch: _filterEvents,
          ),
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredEvents.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            _events.isEmpty
                                ? 'No Events Yet'
                                : 'No Results Found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create your first event to get started',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                event.nameOfEvent[0].toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              event.nameOfEvent,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.group,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text('${event.members.length} members'),
                                  ],
                                ),
                                if (event.budget != null) ...[
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Budget: ${event.currency}${event.budget}',
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              // Get UserModel from database
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              if (currentUser != null) {
                                final userModel = await DatabaseHelper()
                                    .getUser(currentUser.uid);
                                if (userModel != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => EventDetailsScreen(
                                            event: event,
                                            currentUser: userModel,
                                          ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddEventScreen()),
            );
            if (result == true) {
              _loadEvents();
            }
          },
          backgroundColor: Theme.of(context).primaryColor,
          icon: Icon(Icons.event_available, color: Colors.white),
          label: Text(
            'New Event',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userEvents = await DatabaseHelper().getUserEvents(
          currentUser.uid,
        );
        setState(() {
          _events = userEvents;
          _filteredEvents = userEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load events')));
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
