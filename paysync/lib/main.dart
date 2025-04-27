import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:paysync/firebase_options.dart';
import 'package:paysync/screens/splash/splash_screen.dart';
// import 'package:paysync/services/notification_service.dart';
import 'package:paysync/services/sync_service.dart';
import 'package:provider/provider.dart';
import 'package:paysync/providers/theme_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize location services
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Handle denied permission
      print('Location permission denied');
    }
    // await NotificationService.initialize();

    // Initialize local database
    final db = await DatabaseHelper().database;
    if (db == null) {
      throw Exception('Failed to initialize database');
    }

    // Start sync service
    await SyncService.syncIfNeeded(); // Initial sync
    SyncService.startAutoSync(); // Start periodic sync

    runApp(MyApp());
  } catch (e) {
    print('Initialization error: $e');
    // You might want to show an error screen instead
    runApp(MyApp()); // Or fallback initialization
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PaySync',
            theme: themeProvider.theme,
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}
