import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/screens/auth/login_screen.dart';
import 'package:paysync/screens/profile/profile_screen.dart';
import 'package:paysync/utils/currency_converter.dart';
import 'package:paysync/widgets/common/futuristic_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  late Future<UserModel?> userFuture;
  String selectedCurrency = 'USD';
  bool isDarkMode = false;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    userFuture = DatabaseHelper().getUser(currentUser!.uid);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() async {
      selectedCurrency = (await userFuture)?.currencyName ?? 'USD';
      isDarkMode = prefs.getBool('darkMode') ?? false;
      notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
    await prefs.setBool('notifications', notificationsEnabled);

    final user = await userFuture;
    if (user != null) {
      // Convert balances to new currency
      final newOnlineAmount = CurrencyConverter.convert(
        user.onlineAmount,
        user.currencyName,
        selectedCurrency,
      );
      final newOfflineAmount = CurrencyConverter.convert(
        user.offlineAmount,
        user.currencyName,
        selectedCurrency,
      );

      // Update user with new currency and converted amounts
      await DatabaseHelper().updateUserWithNewCurrency(
        user.userId,
        _getCurrencySymbol(selectedCurrency),
        selectedCurrency,
        newOnlineAmount,
        newOfflineAmount,
      );
    }

    // Refresh user data
    setState(() {
      userFuture = DatabaseHelper().getUser(currentUser!.uid);
    });
  }

  String _getCurrencySymbol(String currencyName) {
    switch (currencyName) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      default:
        return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FuturisticAppBar(title: 'Settings'),
      body: FutureBuilder<UserModel?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading user data'));
          }

          final userData = snapshot.data;

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        userData?.profileImageUrl.isNotEmpty == true
                            ? FileImage(File(userData!.profileImageUrl))
                            : null,
                    child:
                        userData?.profileImageUrl.isEmpty ?? true
                            ? Icon(Icons.person)
                            : null,
                  ),
                  title: Text(userData?.username ?? 'User'),
                  subtitle: Text(userData?.email ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      final updatedUser = await Navigator.push<UserModel>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(currentUser: userData!),
                        ),
                      );
                      
                      if (updatedUser != null) {
                        setState(() {
                          userFuture = Future.value(updatedUser);
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),

              // General Settings
              Text('General', style: Theme.of(context).textTheme.titleMedium),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.currency_exchange),
                      title: Text('Currency'),
                      trailing: DropdownButton<String>(
                        value: selectedCurrency,
                        items:
                            ['USD', 'EUR', 'GBP', 'JPY', 'INR']
                                .map(
                                  (currency) => DropdownMenuItem(
                                    value: currency,
                                    child: Text(currency),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCurrency = value!;
                            _saveSettings();
                          });
                        },
                      ),
                    ),
                    SwitchListTile(
                      secondary: Icon(Icons.dark_mode),
                      title: Text('Dark Mode'),
                      value: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          isDarkMode = value;
                          _saveSettings();
                        });
                      },
                    ),
                    SwitchListTile(
                      secondary: Icon(Icons.notifications),
                      title: Text('Notifications'),
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                          _saveSettings();
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Security Section
              Text('Security', style: Theme.of(context).textTheme.titleMedium),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.lock),
                      title: Text('Change Password'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement password change
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.security),
                      title: Text('Privacy Policy'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Show privacy policy
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // About Section
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info),
                      title: Text('Version'),
                      trailing: Text('1.0.0'),
                    ),
                    ListTile(
                      leading: Icon(Icons.description),
                      title: Text('Terms of Service'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Show terms of service
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Logout Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Logout'),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
