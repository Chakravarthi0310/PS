import 'package:flutter/material.dart';
import 'package:paysync/screens/home/home_screen.dart';
import 'package:paysync/screens/insights/insights_screen.dart';
import 'package:paysync/screens/events/events_screen.dart';
import 'package:paysync/screens/settings/settings_screen.dart';
import 'package:paysync/screens/transaction/add_transaction_screen.dart';
import 'package:paysync/widgets/navigation/navigation_bar_item.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    InsightsScreen(),
    EventsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Add this line
      body: _pages[_selectedIndex],
      floatingActionButton:
          MediaQuery.of(context).viewInsets.bottom == 0
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(),
                    ),
                  );
                  if (result == true) {
                    // Refresh transactions if needed
                  }
                },
                elevation: 8,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Icon(Icons.add, size: 32),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  NavigationBarItem(
                    icon: Icons.home,
                    label: 'Home',
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  NavigationBarItem(
                    icon: Icons.insights,
                    label: 'Insights',
                    isSelected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ],
              ),
              Row(
                children: [
                  NavigationBarItem(
                    icon: Icons.event,
                    label: 'Events',
                    isSelected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  NavigationBarItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    isSelected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
