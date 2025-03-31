import 'package:flutter/material.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paysync/widgets/common/futuristic_app_bar.dart';
import 'package:paysync/widgets/eventWidgets/futuristic_budget_input.dart';
import 'package:paysync/widgets/eventWidgets/futuristic_currency_dropdown.dart';
import 'package:paysync/widgets/eventWidgets/futuristic_event_input.dart';
import 'package:paysync/widgets/eventWidgets/futuristic_save_event_button.dart';
import 'package:uuid/uuid.dart';

class AddEventScreen extends StatefulWidget {
  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _budgetController = TextEditingController();
  // final _memberEmailController = TextEditingController();
  String _selectedCurrency = '\$';
  List<String> _members = [];
  bool _isLoading = false;

  final List<String> _currencies = ['\$', '€', '£', '¥', '₹'];

  // Future<void> _addMember() {
  //   if (_memberEmailController.text.isEmpty) return Future.value();

  //   setState(() {
  //     _members.add(_memberEmailController.text);
  //     _memberEmailController.clear();
  //   });
  //   return Future.value();
  // }

  // void _removeMember(String email) {
  //   setState(() {
  //     _members.remove(email);
  //   });
  // }

  Future<void> _saveEvent() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final currentUser = FirebaseAuth.instance.currentUser!;
        final event = EventModel(
          eventId: Uuid().v4(),
          nameOfEvent: _eventNameController.text,
          createdBy: currentUser.uid,
          transactions: [],
          onlineAmountOfEvent: 0,
          offlineAmountOfEvent: 0,
          members: [currentUser.email!, ..._members],
          currency: _selectedCurrency,
          budget:
              _budgetController.text.isNotEmpty
                  ? double.parse(_budgetController.text)
                  : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await DatabaseHelper().insertEvent(event);
        print('Event created successfully: ${event.eventId}');
        print(
          'Event details: ${event.nameOfEvent}, Members: ${event.members.length}',
        );

        // Update user's events list
        final userDetails = await DatabaseHelper().getUser(currentUser.uid);
        if (userDetails != null) {
          userDetails.events.add(event.eventId);
          await DatabaseHelper().updateUser(userDetails);
          print(
            'User events updated. Total events: ${userDetails.events.length}',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.nameOfEvent}" created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, true);
      } catch (e) {
        print('Error creating event: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create event'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FuturisticAppBar(title: "Create New Event"),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FuturisticEventInput(
                controller: _eventNameController,
                label: 'Event Name',
                icon: Icons.event,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Please enter event name'
                            : null,
              ),
              SizedBox(height: 20),
              FuturisticCurrencyDropdown(
                value: _selectedCurrency,
                currencies: _currencies,
                onChanged: (String newValue) {
                  setState(() => _selectedCurrency = newValue);
                },
              ),
              SizedBox(height: 20),
              FuturisticBudgetInput(
                controller: _budgetController,
                currency: _selectedCurrency,
              ),
              SizedBox(height: 20),
              // Row(
              //   children: [
              //     Expanded(
              //       child: TextFormField(
              //         controller: _memberEmailController,
              //         decoration: InputDecoration(
              //           labelText: 'Add Member (Email)',
              //           border: OutlineInputBorder(
              //             borderRadius: BorderRadius.circular(15),
              //           ),
              //           prefixIcon: Icon(Icons.person_add),
              //         ),
              //       ),
              //     ),
              //     SizedBox(width: 10),
              //     IconButton(
              //       onPressed: _addMember,
              //       icon: Icon(Icons.add_circle),
              //       color: Theme.of(context).primaryColor,
              //       iconSize: 32,
              //     ),
              //   ],
              // ),
              // SizedBox(height: 20),
              // Text(
              //   'Members:',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              // ListView.builder(
              //   shrinkWrap: true,
              //   physics: NeverScrollableScrollPhysics(),
              //   itemCount: _members.length,
              //   itemBuilder: (context, index) {
              //     return ListTile(
              //       leading: Icon(Icons.person),
              //       title: Text(_members[index]),
              //       trailing: IconButton(
              //         icon: Icon(Icons.remove_circle, color: Colors.red),
              //         onPressed: () => _removeMember(_members[index]),
              //       ),
              //     );
              //   },
              // ),
              SizedBox(height: 24),
              FuturisticSaveEventButton(
                isLoading: _isLoading,
                onPressed: _saveEvent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
