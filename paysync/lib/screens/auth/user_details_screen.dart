import 'package:flutter/material.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/screens/main_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  final String? email;
  final bool isGoogleSignIn;

  UserDetailsScreen({
    required this.userId,
    required this.email,
    this.isGoogleSignIn = false,
  });

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _onlineBalanceController = TextEditingController();
  final _offlineBalanceController = TextEditingController();
  String _selectedCurrency = '\$';
  File? _profileImage;
  bool _isLoading = false;

  final List<String> _currencies = ['\$', '€', '£', '¥', '₹'];

  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageUrl = image.path;
          _profileImage = File(image.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture selected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select profile picture'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveUserDetails() async {
    setState(() => _isLoading = true);
    try {
      String profileImageUrl = _imageUrl ?? '';

      final user = UserModel(
        userId: widget.userId,
        username: _usernameController.text,
        email: widget.email ?? '',
        profileImageUrl: profileImageUrl,
        defaultCurrency: _selectedCurrency,
        onlineAmount: double.parse(_onlineBalanceController.text),
        offlineAmount: double.parse(_offlineBalanceController.text),
        events: [],
        defaultEventId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: {'notifications': true},
        currencySymbol: _selectedCurrency,
        currencyName: _getCurrencyName(_selectedCurrency),
      );

      // Check if user exists
      final existingUser = await DatabaseHelper().getUser(widget.userId);
      if (existingUser != null) {
        // Update existing user
        await DatabaseHelper().updateUser(user);
      } else {
        // Insert new user
        await DatabaseHelper().insertUser(user);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } catch (e) {
      print('Error saving user details: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving user details')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                        child:
                            _profileImage == null
                                ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          radius: 20,
                          child: IconButton(
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                if (widget.isGoogleSignIn) ...[
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? 'Please enter username'
                                : null,
                  ),
                  SizedBox(height: 20),
                ],
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      hint: Text('Select Currency'),
                      items:
                          _currencies.map((String currency) {
                            return DropdownMenuItem<String>(
                              value: currency,
                              child: Text(
                                '$currency - ${_getCurrencyName(currency)}',
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCurrency = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _onlineBalanceController,
                  decoration: InputDecoration(
                    labelText: 'Current Online Balance',
                    prefixIcon: Icon(Icons.account_balance),
                    prefixText: _selectedCurrency,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value?.isEmpty ?? true
                              ? 'Please enter online balance'
                              : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _offlineBalanceController,
                  decoration: InputDecoration(
                    labelText: 'Current Offline Balance',
                    prefixIcon: Icon(Icons.money),
                    prefixText: _selectedCurrency,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value?.isEmpty ?? true
                              ? 'Please enter offline balance'
                              : null,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              await _saveUserDetails();
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Complete Setup',
                            style: TextStyle(fontSize: 18),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCurrencyName(String symbol) {
    switch (symbol) {
      case '\$':
        return 'USD';
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case '¥':
        return 'JPY';
      case '₹':
        return 'INR';
      default:
        return '';
    }
  }
}
