import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:paysync/models/event_model.dart';
import 'package:paysync/services/recurring_transaction_service.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:paysync/widgets/addTransactionWidgets/animated_segment_button.dart';
import 'package:paysync/widgets/addTransactionWidgets/futuristic_amount_input.dart';
import 'package:paysync/widgets/addTransactionWidgets/futuristic_attachment_button.dart';
import 'package:paysync/widgets/addTransactionWidgets/futuristic_datetime_input.dart';
import 'package:paysync/widgets/addTransactionWidgets/futuristic_event_dropdown.dart';
import 'package:paysync/widgets/addTransactionWidgets/futuristic_location_input.dart';
import 'package:paysync/widgets/addTransactionWidgets/futuristic_note_input.dart';
import 'package:paysync/widgets/addTransactionWidgets/futuristic_payment_method_dropdown.dart';
import 'package:paysync/widgets/addTransactionWidgets/futuristic_recurring_input.dart';
import 'package:paysync/widgets/addTransactionWidgets/futuristic_save_button.dart';
import 'package:paysync/widgets/addTransactionWidgets/payment_mode_segment.dart';
import 'package:paysync/widgets/common/futuristic_app_bar.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTransactionScreen extends StatefulWidget {
  final EventModel? event;

  const AddTransactionScreen({Key? key, this.event}) : super(key: key);

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _locationController = TextEditingController();
  final _recurringTypeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _currentCurrency = '₹';

  String _selectedEvent = 'default';
  String _selectedPaymentMethod = 'Cash';
  bool _isOnline = true;
  bool _isCredit = true;
  bool _isLoading = false;
  bool _isRecurring = false;
  List<EventModel> _events = [];
  String? _imageUrl;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _paymentMethods = ['Cash', 'UPI', 'Card', 'Bank Transfer'];
  final List<String> _recurringTypes = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  Future<void> _loadUserCurrency() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDetails = await DatabaseHelper().getUser(currentUser.uid);
        if (userDetails != null) {
          setState(() {
            _currentCurrency = userDetails.currencySymbol;
          });
        }
      }
    } catch (e) {
      print('Error loading user currency: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadUserCurrency();
    if (widget.event != null) {
      _selectedEvent = widget.event!.eventId;
      _currentCurrency = widget.event!.currency;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Add this method to handle time selection
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageUrl = image.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt attached successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to attach receipt'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadEvents() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDetails = await DatabaseHelper().getUser(currentUser.uid);
        if (userDetails != null) {
          List<EventModel> userEvents = [];

          List<String> eventIds =
              userDetails.events.where((e) => e.isNotEmpty).toList();

          for (String eventId in eventIds) {
            final event = await DatabaseHelper().getEvent(eventId);
            if (event != null) {
              userEvents.add(event);
            }
          }

          setState(() {
            _events = userEvents;
            if (widget.event == null && userDetails.defaultEventId.isNotEmpty) {
              _selectedEvent = userDetails.defaultEventId;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading events: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load events')));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location services are disabled'),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: () async {
                if (Theme.of(context).platform == TargetPlatform.android) {
                  await Geolocator.openAppSettings();
                } else {
                  await Geolocator.openLocationSettings();
                }
              },
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permissions are denied'),
              action: SnackBarAction(
                label: 'Open App Settings',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permissions are permanently denied'),
            action: SnackBarAction(
              label: 'Open App Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Get position with higher accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String location = '';

        // Build a more complete address
        if (place.street?.isNotEmpty ?? false) {
          location += place.street!;
        }
        if (place.locality?.isNotEmpty ?? false) {
          location +=
              location.isNotEmpty ? ', ${place.locality}' : place.locality!;
        }
        if (place.subAdministrativeArea?.isNotEmpty ?? false) {
          location +=
              location.isNotEmpty
                  ? ', ${place.subAdministrativeArea}'
                  : place.subAdministrativeArea!;
        }

        setState(() {
          _locationController.text = location;
        });
      } else {
        throw Exception('No address found');
      }
    } catch (e) {
      print('Location error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not fetch location. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FuturisticAppBar(title: 'Add Transaction'),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100, // Add padding for the floating button
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSegmentButton(
                    value: _isCredit,
                    onChanged: (value) => setState(() => _isCredit = value),
                  ),
                  SizedBox(height: 16),
                  PaymentModeSegment(
                    value: _isOnline,
                    onChanged: (value) => setState(() => _isOnline = value),
                  ),
                  SizedBox(height: 16),
                  FuturisticAmountInput(
                    controller: _amountController,
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? 'Please enter amount'
                                : null,
                    currency: _currentCurrency, // Add this line
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Event',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  FuturisticEventDropdown(
                    value: _selectedEvent,
                    events: _events,
                    onChanged: (value) {
                      final selectedEvent =
                          value == 'default'
                              ? null
                              : _events.firstWhere(
                                (event) => event.eventId == value,
                              );

                      setState(() {
                        _selectedEvent = value;
                        _currentCurrency =
                            selectedEvent?.currency ?? _currentCurrency;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Date and Time',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  FuturisticDateTimeInput(
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    onDateTap: _selectDate,
                    onTimeTap: _selectTime,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),

                  FuturisticLocationInput(
                    controller: _locationController,
                    onLocationRequest: _getCurrentLocation,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  FuturisticPaymentMethodDropdown(
                    value: _selectedPaymentMethod,
                    paymentMethods: _paymentMethods,
                    onChanged:
                        (value) =>
                            setState(() => _selectedPaymentMethod = value),
                  ),

                  SizedBox(height: 16),
                  Text(
                    'Note',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  FuturisticNoteInput(controller: _noteController),
                  SizedBox(height: 16),
                  FuturisticRecurringInput(
                    isRecurring: _isRecurring,
                    recurringType:
                        _recurringTypeController.text.isEmpty
                            ? _recurringTypes.first
                            : _recurringTypeController.text,
                    recurringTypes: _recurringTypes,
                    onRecurringChanged: (value) {
                      setState(() => _isRecurring = value);
                    },
                    onTypeChanged: (value) {
                      setState(() => _recurringTypeController.text = value);
                    },
                  ),
                  SizedBox(height: 16),
                  FuturisticAttachmentButton(onPressed: _pickImage),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FuturisticSaveButton(
              isLoading: _isLoading,
              onPressed: _saveTransaction,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final currentUser = FirebaseAuth.instance.currentUser!;
        final amount = double.parse(_amountController.text);
        final userDetails = await DatabaseHelper().getUser(currentUser.uid);
        DateTime dateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        double amountInUserCurrency = amount;
        if (_currentCurrency != userDetails!.currencyName) {
          amountInUserCurrency = CurrencyConverter.convert(
            amount,
            _currentCurrency,
            userDetails.currencyName,
          );
        }

        // Create transaction
        final transaction = TransactionModel(
          transactionId: Uuid().v4(),
          userId: currentUser.uid,
          eventId: _selectedEvent,
          isOnline: _isOnline,
          isCredit: _isCredit,
          amount: amount,
          currency: _currentCurrency, // TODO: Get from user preferences
          paymentMethod: _selectedPaymentMethod,
          location: _locationController.text,
          dateTime: _selectedDate,
          note: _noteController.text,
          imageUrl: _imageUrl,
          recurring: _isRecurring,
          recurringType: _isRecurring ? _recurringTypeController.text : null,
          createdAt: dateTime,
          updatedAt: DateTime.now(),
          onlineBalanceAfter:
              _isOnline
                  ? (userDetails.onlineAmount +
                      (_isCredit
                          ? amountInUserCurrency
                          : -amountInUserCurrency))
                  : userDetails.onlineAmount,
          offlineBalanceAfter:
              !_isOnline
                  ? (userDetails.offlineAmount +
                      (_isCredit
                          ? amountInUserCurrency
                          : -amountInUserCurrency))
                  : userDetails.offlineAmount,
        );

        // Get current user details
        // Update amounts based on transaction type
        if (_isOnline) {
          userDetails.onlineAmount +=
              _isCredit ? amountInUserCurrency : -amountInUserCurrency;
        } else {
          userDetails.offlineAmount += _isCredit ? amount : -amount;
        }

        // Update user in database
        await DatabaseHelper().updateUser(userDetails);

        // Save transaction
        await DatabaseHelper().insertTransaction(transaction);

        // Schedule next transaction if recurring
        if (_isRecurring) {
          await RecurringTransactionService.scheduleNextTransaction(
            transaction,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isRecurring
                  ? 'Transaction saved and next recurring transaction scheduled'
                  : 'Transaction saved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } catch (e) {
        print('Error saving transaction: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save transaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }
}
