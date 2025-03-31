import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:paysync/database/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class SyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static Timer? _syncTimer;
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static const String _baseUrl =
      'https://paysyncserver-production.up.railway.app/api/sync';

  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static void startAutoSync() {
    // Sync every 5 minutes
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => syncIfNeeded(),
    );

    // Listen for connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
              if (result != ConnectivityResult.none) {
                syncIfNeeded();
              }
            })
            as StreamSubscription<ConnectivityResult>?;
  }

  // static void stopAutoSync() {
  //   _syncTimer?.cancel();
  //   _connectivitySubscription?.cancel();
  // }

  static Future<void> markForSync(
    String collectionName,
    String documentId,
  ) async {
    try {
      final db = await DatabaseHelper().database;

      // Insert into sync_status table
      await db.insert('sync_status', {
        'id':
            '${collectionName}_${documentId}_${DateTime.now().millisecondsSinceEpoch}',
        'table_name': collectionName,
        'record_id': documentId,
        'action': 'update',
        'sync_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      print('Marked for sync: $collectionName:$documentId');

      // Trigger immediate sync if online
      if (await isOnline()) {
        syncIfNeeded();
      }
    } catch (e) {
      print('Error marking for sync: $e');
    }
  }

  static Future<void> syncIfNeeded() async {
    if (!await isOnline()) {
      print('Sync skipped: Device offline');
      return;
    }

    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> pendingSync = await db.query(
        'sync_status',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
      );

      if (pendingSync.isEmpty) {
        print('Sync skipped: No pending changes');
        return;
      }

      print('Starting sync with ${pendingSync.length} pending changes');
      Map<String, Map<String, dynamic>> changes = {};

      for (var item in pendingSync) {
        final collection = item['table_name'];
        final docId = item['record_id'];

        // Get local data from SQLite
        final data = await DatabaseHelper().getDocument(collection, docId);
        if (data != null) {
          if (!changes.containsKey(collection)) {
            changes[collection] = {};
          }
          changes[collection]![docId] = data;
        }
      }

      print('Changes to sync: $changes');

      // Send changes to server
      // Add retry logic
      int maxRetries = 3;
      for (int retry = 0; retry < maxRetries; retry++) {
        try {
          final client = http.Client();
          try {
            final response = await client
                .post(
                  Uri.parse('$_baseUrl/changes'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode(changes),
                )
                .timeout(const Duration(seconds: 15));

            if (response.statusCode == 200) {
              await db.update(
                'sync_status',
                {'sync_status': 'synced'},
                where: 'sync_status = ?',
                whereArgs: ['pending'],
              );
              print('Successfully synced changes to server');
              return;
            }
            print('Failed to sync. Status code: ${response.statusCode}');
            break;
          } finally {
            client.close();
          }
        } catch (e) {
          print('Sync attempt ${retry + 1} failed: $e');
          if (retry < maxRetries - 1) {
            await Future.delayed(Duration(seconds: (retry + 1) * 2));
            print('Retrying sync...');
          }
        }
      }
    } catch (e) {
      print('Sync error after all retries: $e');
    }
  }

  static Future<void> initialSync(String userId) async {
      print('Starting initial sync for user: $userId');
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/users/$userId'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 30));
  
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
  
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          print('Parsed data structure: ${data.keys}');  // Debug log
          
          final db = await DatabaseHelper().database;
          
          await db.transaction((txn) async {
            // Clear existing data for this user
            print('Clearing existing data for user: $userId');
            await txn.delete('events', where: 'createdBy = ?', whereArgs: [userId]);
            await txn.delete('transactions', where: 'userId = ?', whereArgs: [userId]);
            
            // Process users data
            if (data.containsKey('users')) {
              final users = data['users'] as Map<String, dynamic>;
              print('Processing users: ${users.length}');
              for (var entry in users.entries) {
                await txn.insert('users', entry.value as Map<String, dynamic>,
                    conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }

            // Process events data
            if (data.containsKey('events')) {
              final events = data['events'] as Map<String, dynamic>;
              print('Processing events: ${events.length}');
              for (var entry in events.entries) {
                final eventData = Map<String, dynamic>.from(entry.value);
                eventData['eventId'] = entry.key;
                await txn.insert('events', eventData,
                    conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }

            // Process transactions data
            if (data.containsKey('transactions')) {
              final transactions = data['transactions'] as Map<String, dynamic>;
              print('Processing transactions: ${transactions.length}');
              for (var entry in transactions.entries) {
                final transactionData = Map<String, dynamic>.from(entry.value);
                transactionData['transactionId'] = entry.key;
                await txn.insert('transactions', transactionData,
                    conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }
          });
          
          print('Initial sync completed successfully');
        } else {
          print('Initial sync failed: ${response.statusCode}');
        }
      } catch (e) {
        print('Initial sync error: $e');
      }
    }

  // static String get _baseUrl {
  //   if (kIsWeb) {
  //     return 'http://localhost:8080/api/sync';  // Web/Chrome
  //   } else if (Platform.isAndroid) {
  //     return 'http://10.0.2.2:8080/api/sync';   // Android emulator
  //   } else {
  //     return 'http://localhost:8080/api/sync';   // iOS or desktop
  //   }
  // }
}
