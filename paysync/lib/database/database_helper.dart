import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:paysync/models/savings_goal_model.dart';
import 'package:paysync/services/sync_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:paysync/models/user_model.dart';
import 'package:paysync/models/event_model.dart';
import 'package:paysync/models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'paysync.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onOpen: (db) async {
        // Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        userId TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT,
        profileImageUrl TEXT NOT NULL,
        defaultCurrency TEXT NOT NULL,
        onlineAmount REAL NOT NULL,
        offlineAmount REAL NOT NULL,
        events TEXT NOT NULL,
        defaultEventId TEXT NOT NULL,
        currencySymbol TEXT NOT NULL,
        currencyName TEXT NOT NULL,
        savingsGoals TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        preferences TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE savings_goals (
        goalId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        goalName TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentSavings REAL NOT NULL,
        currency TEXT,
        deadline TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        eventId TEXT PRIMARY KEY,
        nameOfEvent TEXT NOT NULL,
        createdBy TEXT NOT NULL,
        transactions TEXT NOT NULL,
        onlineAmountOfEvent REAL NOT NULL,
        offlineAmountOfEvent REAL NOT NULL,
        members TEXT NOT NULL,
        currency TEXT NOT NULL,
        budget REAL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        transactionId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        eventId TEXT NOT NULL,
        isOnline INTEGER NOT NULL,
        isCredit INTEGER NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        location TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        note TEXT,
        imageUrl TEXT,
        recurring INTEGER NOT NULL,
        onlineBalanceAfter REAL NOT NULL,  
        offlineBalanceAfter REAL NOT NULL,
        recurringType TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_status (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> markForSync(
    String tableName,
    String recordId,
    String action,
  ) async {
    final db = await database;
    await db.insert('sync_status', {
      'id': '${tableName}_${recordId}_${DateTime.now().millisecondsSinceEpoch}',
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'sync_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertSavingsGoal(String userId, SavingsGoalModel goal) async {
    try {
      final db = await database;
      final goalMap = {
        'goalId': goal.goalId,
        'userId': userId,
        'goalName': goal.goalName,
        'targetAmount': goal.targetAmount,
        'currentSavings': goal.currentSavings,
        'currency': goal.currency,
        'deadline': goal.deadline.toIso8601String(),
        'status': goal.status,
        'createdAt': goal.createdAt.toIso8601String(),
        'updatedAt': goal.updatedAt.toIso8601String(),
      };

      await db.insert(
        'savings_goals',
        goalMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await markForSync('savings_goals', goal.goalId, 'insert');
      // Update user's savings goals list
      final userResult = await db.query(
        'users',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      if (userResult.isNotEmpty) {
        String currentGoals = userResult.first['savingsGoals'].toString();
        List<String> goalsList =
            currentGoals.isEmpty ? [] : currentGoals.split(',');

        if (!goalsList.contains(goal.goalId)) {
          goalsList.add(goal.goalId);
          await db.update(
            'users',
            {'savingsGoals': goalsList.join(',')},
            where: 'userId = ?',
            whereArgs: [userId],
          );
        }
      }
    } catch (e) {
      print('Error inserting savings goal: $e');
      throw e;
    }
  }

  Future<List<SavingsGoalModel>> getUserSavingsGoals(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'savings_goals',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );

      print('Raw savings goals data: $maps'); // Debug print

      if (maps.isEmpty) {
        return [];
      }

      return maps
          .map(
            (map) => SavingsGoalModel(
              goalId: map['goalId'],
              goalName: map['goalName'],
              targetAmount: map['targetAmount'],
              currentSavings: map['currentSavings'],
              deadline: DateTime.parse(map['deadline']),
              status: map['status'],
              createdAt: DateTime.parse(map['createdAt']),
              updatedAt: DateTime.parse(map['updatedAt']),
              currency: map['currency'] ?? 'USD',
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching savings goals: $e');
      throw e; // Rethrow to handle in UI
    }
  }

  // Future<void> insertSavingsGoal(String userId, SavingsGoalModel goal) async {
  //   try {
  //     final db = await database;
  //     final goalMap = goal.toMap();
  //     goalMap['userId'] = userId; // Ensure userId is included in the map

  //     await db.insert(
  //       'savings_goals',
  //       goalMap,
  //       conflictAlgorithm: ConflictAlgorithm.replace,
  //     );
  //   } catch (e) {
  //     print('Error inserting savings goal: $e');
  //     throw e;
  //   }
  // }

  Future<void> updateSavingsGoal(SavingsGoalModel goal) async {
    final db = await database;
    await db.update(
      'savings_goals',
      {
        'goalName': goal.goalName,
        'targetAmount': goal.targetAmount,
        'currentSavings': goal.currentSavings,
        'deadline': goal.deadline.toIso8601String(),
        'status': goal.status,
        'updatedAt': goal.updatedAt.toIso8601String(),
      },

      where: 'goalId = ?',
      whereArgs: [goal.goalId],
    );
    await markForSync('savings_goals', goal.goalId, 'update');
  }

  // User operations
  Future<void> insertUser(UserModel user) async {
    final Database db = await database;
    await db.insert('users', {
      'userId': user.userId,
      'username': user.username,
      'email': user.email,
      'profileImageUrl': user.profileImageUrl,
      'defaultCurrency': user.defaultCurrency,
      'onlineAmount': user.onlineAmount,
      'offlineAmount': user.offlineAmount,
      'events': user.events.join(','),
      'defaultEventId': user.defaultEventId,
      'savingsGoals': user.savingsGoals.join(','), // Add this line
      'createdAt': user.createdAt.toIso8601String(),
      'updatedAt': user.updatedAt.toIso8601String(),
      'currencySymbol': user.currencySymbol,
      'currencyName': user.currencyName,
      'preferences': user.preferences.toString(),
    });

    await markForSync('users', user.userId, 'insert');
    SyncService.syncIfNeeded();
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    final db = await database;
    await db.delete('savings_goals', where: 'goalId = ?', whereArgs: [goalId]);
    await markForSync('savings_goals', goalId, 'delete');
  }

  Future<UserModel?> getUser(String userId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;

    List<String> events = [];
    if (maps[0]['events'] != null && maps[0]['events'].toString().isNotEmpty) {
      events = maps[0]['events'].toString().split(',');
    }

    List<String> savingsGoals = []; // Add this block
    if (maps[0]['savingsGoals'] != null &&
        maps[0]['savingsGoals'].toString().isNotEmpty) {
      savingsGoals = maps[0]['savingsGoals'].toString().split(',');
    }

    return UserModel(
      userId: maps[0]['userId'],
      username: maps[0]['username'],
      email: maps[0]['email'],
      profileImageUrl: maps[0]['profileImageUrl'],
      defaultCurrency: maps[0]['defaultCurrency'],
      onlineAmount: maps[0]['onlineAmount'],
      offlineAmount: maps[0]['offlineAmount'],
      events: events,
      defaultEventId: maps[0]['defaultEventId'],
      savingsGoals: savingsGoals, // Add this line
      createdAt: DateTime.parse(maps[0]['createdAt']),
      updatedAt: DateTime.parse(maps[0]['updatedAt']),
      preferences: _parsePreferences(maps[0]['preferences']),
      currencySymbol: maps[0]['currencySymbol'],
      currencyName: maps[0]['currencyName'],
    );
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final db = await database;
      await db.update(
        'users',
        {
          'username': user.username,
          'profileImageUrl': user.profileImageUrl,
          'onlineAmount': user.onlineAmount,
          'offlineAmount': user.offlineAmount,
          'events': user.events.join(','),
          'savingsGoals': user.savingsGoals.join(','), // Add this line
          'currencySymbol': user.currencySymbol,
          'currencyName': user.currencyName,
          'preferences': user.preferences.toString(),
          'updatedAt': user.updatedAt.toIso8601String(),
        },
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
      await markForSync('users', user.userId, 'update');
    } catch (e) {
      print('Error updating user: $e');
      throw e;
    }
  }

  Map<String, bool> _parsePreferences(String preferencesStr) {
    try {
      if (preferencesStr.isEmpty) return {'notifications': true};
      String cleaned = preferencesStr.replaceAll('{', '').replaceAll('}', '');
      Map<String, bool> result = {};
      cleaned.split(',').forEach((pair) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim().toLowerCase() == 'true';
          result[key] = value;
        }
      });
      return result;
    } catch (e) {
      return {'notifications': true};
    }
  }

  // Future<void> updateUser(UserModel user) async {
  //   try {
  //     final db = await database;
  //     await db.update(
  //       'users',
  //       {
  //         'onlineAmount': user.onlineAmount,
  //         'offlineAmount': user.offlineAmount,
  //         'events': user.events.join(','),
  //         'savingsGoals': user.savingsGoals.join(','),  // Add this line
  //         'currencySymbol': user.currencySymbol,
  //         'currencyName': user.currencyName,
  //         'preferences': user.preferences.toString(),
  //         'updatedAt': user.updatedAt.toIso8601String(),
  //       },
  //       where: 'userId = ?',
  //       whereArgs: [user.userId],
  //     );
  //   } catch (e) {
  //     print('Error updating user: $e');
  //     throw e;
  //   }
  // }

  // Map<String, bool> _parsePreferences(String preferencesStr) {
  //   // Remove the curly braces and split the string
  //   String cleaned = preferencesStr.replaceAll('{', '').replaceAll('}', '');
  //   if (cleaned.isEmpty) return {};

  //   Map<String, bool> result = {};
  //   cleaned.split(',').forEach((pair) {
  //     final parts = pair.split(':');
  //     if (parts.length == 2) {
  //       final key = parts[0].trim();
  //       final value = parts[1].trim().toLowerCase() == 'true';
  //       result[key] = value;
  //     }
  //   });
  //   return result;
  // }
  // Transaction operations
  // Future<void> createTransactionsTable(Database db) async {
  //   await db.execute('''
  //       CREATE TABLE transactions(
  //         transactionId TEXT PRIMARY KEY,
  //         userId TEXT NOT NULL,
  //         eventId TEXT NOT NULL,
  //         isOnline INTEGER NOT NULL,
  //         isCredit INTEGER NOT NULL,
  //         amount REAL NOT NULL,
  //         currency TEXT NOT NULL,
  //         paymentMethod TEXT NOT NULL,
  //         location TEXT NOT NULL,
  //         dateTime TEXT NOT NULL,
  //         note TEXT,
  //         imageUrl TEXT,
  //         recurring INTEGER NOT NULL,
  //         recurringType TEXT,
  //         createdAt TEXT NOT NULL,
  //         updatedAt TEXT NOT NULL
  //       )
  //     ''');
  // }
  Future<void> insertTransaction(TransactionModel transaction) async {
    try {
      final db = await database;
      final _firestore = firestore.FirebaseFirestore.instance;

      // Insert the transaction in local database
      await db.insert('transactions', {
        'transactionId': transaction.transactionId,
        'userId': transaction.userId,
        'eventId': transaction.eventId,
        'isOnline': transaction.isOnline ? 1 : 0,
        'isCredit': transaction.isCredit ? 1 : 0,
        'amount': transaction.amount,
        'currency': transaction.currency,
        'paymentMethod': transaction.paymentMethod,
        'location': transaction.location,
        'dateTime': transaction.dateTime.toIso8601String(),
        'note': transaction.note,
        'imageUrl': transaction.imageUrl,
        'recurring': transaction.recurring ? 1 : 0,
        'recurringType': transaction.recurringType,
        'createdAt': transaction.createdAt.toIso8601String(),
        'updatedAt': transaction.updatedAt.toIso8601String(),
        'onlineBalanceAfter': transaction.onlineBalanceAfter,
        'offlineBalanceAfter': transaction.offlineBalanceAfter,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await markForSync('transactions', transaction.transactionId, 'insert');
      print('Transaction marked for sync: ${transaction.transactionId}');
      SyncService.syncIfNeeded();

      // Get the event from both local and Firestore
      final event = await getEvent(transaction.eventId);
      final eventDoc =
          await _firestore.collection('events').doc(transaction.eventId).get();

      if (event != null && eventDoc.exists) {
        final eventData = eventDoc.data()!;

        // Handle Firestore transactions list
        List<String> firestoreTransactions = [];
        if (eventData['transactions'] != null) {
          if (eventData['transactions'] is String) {
            firestoreTransactions =
                eventData['transactions']
                    .toString()
                    .split(',')
                    .where((e) => e.isNotEmpty)
                    .toList();
          } else if (eventData['transactions'] is List) {
            firestoreTransactions = List<String>.from(
              eventData['transactions'],
            );
          }
        }

        if (!firestoreTransactions.contains(transaction.transactionId)) {
          firestoreTransactions.add(transaction.transactionId);

          double newOnlineAmount = event.onlineAmountOfEvent;
          double newOfflineAmount = event.offlineAmountOfEvent;

          if (transaction.isOnline) {
            newOnlineAmount +=
                transaction.isCredit ? transaction.amount : -transaction.amount;
          } else {
            newOfflineAmount +=
                transaction.isCredit ? transaction.amount : -transaction.amount;
          }

          // Update both local and Firestore
          await Future.wait([
            db.update(
              'events',
              {
                'transactions': firestoreTransactions.join(','),
                'onlineAmountOfEvent': newOnlineAmount,
                'offlineAmountOfEvent': newOfflineAmount,
                'updatedAt': DateTime.now().toIso8601String(),
              },
              where: 'eventId = ?',
              whereArgs: [transaction.eventId],
            ),
            _firestore.collection('events').doc(transaction.eventId).update({
              'transactions': firestoreTransactions,
              'onlineAmountOfEvent': newOnlineAmount,
              'offlineAmountOfEvent': newOfflineAmount,
              'updatedAt': DateTime.now().toIso8601String(),
            }),
          ]);
        }
      }

      print('Transaction inserted successfully: ${transaction.transactionId}');
    } catch (e) {
      print('Error inserting transaction: $e');
      throw e;
    }
  }

  Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'transactions',
        where: 'transactionId = ?',
        whereArgs: [transactionId],
      );

      if (result.isNotEmpty) {
        return TransactionModel(
          transactionId: result.first['transactionId'],
          userId: result.first['userId'],
          eventId: result.first['eventId'],
          isOnline: result.first['isOnline'] == 1,
          isCredit: result.first['isCredit'] == 1,
          amount: result.first['amount'],
          currency: result.first['currency'],
          paymentMethod: result.first['paymentMethod'],
          location: result.first['location'],
          dateTime: DateTime.parse(result.first['dateTime']),
          note: result.first['note'],
          imageUrl: result.first['imageUrl'],
          recurring: result.first['recurring'] == 1,
          recurringType: result.first['recurringType'],
          createdAt: DateTime.parse(result.first['createdAt']),
          updatedAt: DateTime.parse(result.first['updatedAt']),
          onlineBalanceAfter: result.first['onlineBalanceAfter'],
          offlineBalanceAfter: result.first['offlineBalanceAfter'],
        );
      }
      return null;
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> results = await db.query(
        'transactions',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'dateTime DESC',
      );

      return results
          .map(
            (result) => TransactionModel(
              transactionId: result['transactionId'],
              userId: result['userId'],
              eventId: result['eventId'],
              isOnline: result['isOnline'] == 1,
              isCredit: result['isCredit'] == 1,
              amount: result['amount'],
              currency: result['currency'],
              paymentMethod: result['paymentMethod'],
              location: result['location'],
              dateTime: DateTime.parse(result['dateTime']),
              note: result['note'],
              imageUrl: result['imageUrl'],
              recurring: result['recurring'] == 1,
              recurringType: result['recurringType'],
              createdAt: DateTime.parse(result['createdAt']),
              updatedAt: DateTime.parse(result['updatedAt']),
              onlineBalanceAfter:
                  (result['onlineBalanceAfter'] ?? 0).toDouble(),
              offlineBalanceAfter:
                  (result['offlineBalanceAfter'] ?? 0).toDouble(),
            ),
          )
          .toList();
    } catch (e) {
      print('Error getting user transactions: $e');
      return [];
    }
  }

  // Event operations
  Future<void> insertEvent(EventModel event) async {
    final Database db = await database;
    await db.insert('events', {
      'eventId': event.eventId,
      'nameOfEvent': event.nameOfEvent,
      'createdBy': event.createdBy,
      'transactions': event.transactions.join(','),
      'onlineAmountOfEvent': event.onlineAmountOfEvent,
      'offlineAmountOfEvent': event.offlineAmountOfEvent,
      'members': event.members.join(','),
      'currency': event.currency,
      'budget': event.budget,
      'createdAt': event.createdAt.toIso8601String(),
      'updatedAt': event.updatedAt.toIso8601String(),
    });
    await markForSync('events', event.eventId, 'insert');
  }

  Future<EventModel?> getEvent(String eventId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'events',
        where: 'eventId = ?',
        whereArgs: [eventId],
      );

      if (result.isNotEmpty) {
        print('Found event: ${result.first}'); // Debug print
        return EventModel(
          eventId: result.first['eventId'],
          nameOfEvent: result.first['nameOfEvent'],
          createdBy: result.first['createdBy'],
          transactions: List<String>.from(
            result.first['transactions'].toString().split(','),
          ),
          onlineAmountOfEvent: result.first['onlineAmountOfEvent'].toDouble(),
          offlineAmountOfEvent: result.first['offlineAmountOfEvent'].toDouble(),
          members: List<String>.from(
            result.first['members'].toString().split(','),
          ),
          currency: result.first['currency'],
          budget: result.first['budget']?.toDouble(),
          createdAt: DateTime.parse(result.first['createdAt']),
          updatedAt: DateTime.parse(result.first['updatedAt']),
        );
      }
      return null;
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  Future<List<EventModel>> getUserEvents(String userId) async {
    try {
      final db = await database;
      List<EventModel> allEvents = [];

      // Try to fetch from Firestore first
      try {
        final _firestore = firestore.FirebaseFirestore.instance;
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userEvents =
              (userData['events'] as String)
                  .split(',')
                  .where((e) => e.isNotEmpty)
                  .toList();

          // Fetch all events in parallel
          final eventFutures = userEvents.map(
            (eventId) => _firestore.collection('events').doc(eventId).get(),
          );
          final eventDocs = await Future.wait(eventFutures);

          for (var doc in eventDocs) {
            if (doc.exists) {
              final data = doc.data()!;
              final eventId = doc.id;

              final event = EventModel(
                eventId: eventId,
                nameOfEvent: data['nameOfEvent'] ?? '',
                createdBy: data['createdBy'] ?? '',
                transactions:
                    data['transactions'] is String
                        ? data['transactions']
                            .toString()
                            .split(',')
                            .where((e) => e.isNotEmpty)
                            .toList()
                        : List<String>.from(data['transactions'] ?? []),
                onlineAmountOfEvent:
                    (data['onlineAmountOfEvent'] ?? 0.0).toDouble(),
                offlineAmountOfEvent:
                    (data['offlineAmountOfEvent'] ?? 0.0).toDouble(),
                members:
                    data['members'] is String
                        ? data['members']
                            .toString()
                            .split(',')
                            .where((e) => e.isNotEmpty)
                            .toList()
                        : List<String>.from(data['members'] ?? []),
                currency: data['currency'] ?? 'USD',
                budget: (data['budget'] ?? 0.0).toDouble(),
                createdAt:
                    data['createdAt'] is firestore.Timestamp
                        ? (data['createdAt'] as firestore.Timestamp).toDate()
                        : DateTime.parse(data['createdAt']),
                updatedAt:
                    data['updatedAt'] is firestore.Timestamp
                        ? (data['updatedAt'] as firestore.Timestamp).toDate()
                        : DateTime.parse(data['updatedAt']),
              );

              // Insert or update event in local database
              await db.insert('events', {
                'eventId': event.eventId,
                'nameOfEvent': event.nameOfEvent,
                'createdBy': event.createdBy,
                'transactions': event.transactions.join(','),
                'onlineAmountOfEvent': event.onlineAmountOfEvent,
                'offlineAmountOfEvent': event.offlineAmountOfEvent,
                'members': event.members.join(','),
                'currency': event.currency,
                'budget': event.budget,
                'createdAt': event.createdAt.toIso8601String(),
                'updatedAt': event.updatedAt.toIso8601String(),
              }, conflictAlgorithm: ConflictAlgorithm.replace);

              // Fetch and store transactions for this event
              if (event.transactions.isNotEmpty) {
                final transactionFutures = event.transactions.map(
                  (transactionId) =>
                      _firestore
                          .collection('transactions')
                          .doc(transactionId)
                          .get(),
                );
                final transactionDocs = await Future.wait(transactionFutures);

                for (var transDoc in transactionDocs) {
                  if (transDoc.exists) {
                    final transData = transDoc.data()!;
                    await db.insert('transactions', {
                      'transactionId': transDoc.id,
                      'userId': transData['userId'],
                      'eventId': event.eventId,
                      'isOnline': transData['isOnline'] ? 1 : 0,
                      'isCredit': transData['isCredit'] ? 1 : 0,
                      'amount': transData['amount'],
                      'currency': transData['currency'],
                      'paymentMethod': transData['paymentMethod'],
                      'location': transData['location'],
                      'dateTime':
                          transData['dateTime'] is firestore.Timestamp
                              ? (transData['dateTime'] as firestore.Timestamp)
                                  .toDate()
                                  .toIso8601String()
                              : transData['dateTime'],
                      'note': transData['note'],
                      'imageUrl': transData['imageUrl'],
                      'recurring': transData['recurring'] ? 1 : 0,
                      'recurringType': transData['recurringType'],
                      'onlineBalanceAfter': transData['onlineBalanceAfter'],
                      'offlineBalanceAfter': transData['offlineBalanceAfter'],
                      'createdAt':
                          transData['createdAt'] is firestore.Timestamp
                              ? (transData['createdAt'] as firestore.Timestamp)
                                  .toDate()
                                  .toIso8601String()
                              : transData['createdAt'],
                      'updatedAt':
                          transData['updatedAt'] is firestore.Timestamp
                              ? (transData['updatedAt'] as firestore.Timestamp)
                                  .toDate()
                                  .toIso8601String()
                              : transData['updatedAt'],
                    }, conflictAlgorithm: ConflictAlgorithm.replace);
                  }
                }
              }

              // Update user's events list in local database
              final userResult = await db.query(
                'users',
                where: 'userId = ?',
                whereArgs: [userId],
              );

              if (userResult.isNotEmpty) {
                String currentEvents = userResult.first['events'].toString();
                List<String> eventsList =
                    currentEvents.isEmpty ? [] : currentEvents.split(',');

                if (!eventsList.contains(event.eventId)) {
                  eventsList.add(event.eventId);
                  await db.update(
                    'users',
                    {'events': eventsList.join(',')},
                    where: 'userId = ?',
                    whereArgs: [userId],
                  );
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching from Firestore: $e');
      }

      // Get all events from local database
      final List<Map<String, dynamic>> localResults = await db.query(
        'events',
        where: 'createdBy = ? OR members LIKE ?',
        whereArgs: [userId, '%$userId%'],
        orderBy: 'createdAt DESC',
      );

      allEvents =
          localResults
              .map(
                (result) => EventModel(
                  eventId: result['eventId'],
                  nameOfEvent: result['nameOfEvent'],
                  createdBy: result['createdBy'],
                  transactions:
                      result['transactions']?.toString().split(',') ?? [],
                  onlineAmountOfEvent: result['onlineAmountOfEvent'].toDouble(),
                  offlineAmountOfEvent:
                      result['offlineAmountOfEvent'].toDouble(),
                  members: result['members']?.toString().split(',') ?? [],
                  currency: result['currency'],
                  budget: result['budget']?.toDouble(),
                  createdAt: DateTime.parse(result['createdAt']),
                  updatedAt: DateTime.parse(result['updatedAt']),
                ),
              )
              .toList();

      return allEvents;
    } catch (e) {
      print('Error getting user events: $e');
      return [];
    }
  }

  Future<void> updateUserWithNewCurrency(
    String userId,
    String currencySymbol,
    String currencyName,
    double onlineAmount,
    double offlineAmount,
  ) async {
    final db = await database;

    await db.update(
      'users',
      {
        'currencySymbol': currencySymbol,
        'currencyName': currencyName,
        'onlineAmount': onlineAmount,
        'offlineAmount': offlineAmount,
      },
      where: 'userId = ?',
      whereArgs: [userId],
    );
    await markForSync('users', userId, 'update');
  }

  Future<void> updateEvent(
    String eventId,
    String newName,
    String newCurrency,
  ) async {
    try {
      final db = await database;
      await db.update(
        'events',
        {
          'nameOfEvent': newName,
          'currency': newCurrency,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'eventId = ?',
        whereArgs: [eventId],
      );
      await markForSync('events', eventId, 'update');
    } catch (e) {
      print('Error updating event: $e');
      throw Exception('Failed to update event');
    }
  }

  Future<void> updateEventBudget(String eventId, double newBudget) async {
    try {
      final db = await database;
      await db.update(
        'events',
        {'budget': newBudget, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'eventId = ?',
        whereArgs: [eventId],
      );
      await markForSync('events', eventId, 'update');
    } catch (e) {
      print('Error updating event budget: $e');
      throw Exception('Failed to update event budget');
    }
  }

  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      final db = await database;
      String idColumn;

      // Map collection names to their correct ID column names
      switch (collection) {
        case 'users':
          idColumn = 'userId';
          break;
        case 'transactions':
          idColumn = 'transactionId';
          break;
        case 'savings_goals':
          idColumn = 'goalId';
          break;
        case 'events':
          idColumn = 'eventId';
          break;
        default:
          throw Exception('Unknown collection: $collection');
      }

      final List<Map<String, dynamic>> result = await db.query(
        collection,
        where: '$idColumn = ?',
        whereArgs: [documentId],
      );

      if (result.isNotEmpty) {
        print('Found document in $collection: ${result.first}');
        return result.first;
      }
      return null;
    } catch (e) {
      print('Error getting document: $e');
      return null;
    }
  }

  Future<void> applyServerChanges(
    Map<String, dynamic> changes, {
    Transaction? transaction,
  }) async {
    final db = await database;
    final txn = transaction ?? db;

    for (var entry in changes.entries) {
      String collection = entry.key;
      Map<String, dynamic> documents = entry.value as Map<String, dynamic>;

      for (var doc in documents.entries) {
        String documentId = doc.key;
        Map<String, dynamic> data = doc.value as Map<String, dynamic>;

        await txn.insert(collection, {
          ...data,
          'id': documentId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<bool> inviteUserToEvent(String eventId, String userEmail) async {
    try {
      firestore.FirebaseFirestore _firestore =
          firestore.FirebaseFirestore.instance;
      final db = await database;

      final userQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: userEmail)
              .get();

      if (userQuery.docs.isEmpty) return false;

      final userId = userQuery.docs.first.id;
      final userDoc = userQuery.docs.first;

      // Check if user is already a member in Firestore
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      String membersString = eventDoc.data()?['members'] ?? '';
      List<String> members =
          membersString.isEmpty ? [] : membersString.split(',');

      if (members.contains(userId)) {
        return false;
      }

      // Add user to event members
      members.add(userId);
      await _firestore.collection('events').doc(eventId).update({
        'members':
            members.isEmpty
                ? ''
                : members.join(','), // Ensure empty string when no members
      });

      // Add event to user's events list
      String currentEvents = userDoc.data()?['events'] ?? '';
      List<String> eventsList =
          currentEvents.isEmpty ? [] : currentEvents.split(',');

      if (!eventsList.contains(eventId)) {
        eventsList.add(eventId);
        await _firestore.collection('users').doc(userId).update({
          'events':
              eventsList.isEmpty
                  ? ''
                  : eventsList.join(','), // Ensure empty string when no events
        });
      }

      // Update local database
      await updateEventMembers(eventId, members);

      return true;
    } catch (e) {
      print('Error inviting user: $e');
      return false;
    }
  }

  Future<void> updateEventMembers(String eventId, List<String> members) async {
    final db = await database;
    await db.update(
      'events',
      {
        'members': members.join(','),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
    await markForSync('events', eventId, 'update');
  }

  Future<bool> removeMemberFromEvent(String eventId, String userId) async {
    try {
      firestore.FirebaseFirestore _firestore =
          firestore.FirebaseFirestore.instance;

      // Get current event data
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      final userDoc = await _firestore.collection('users').doc(userId).get();

      // Handle members list in event
      final membersData = eventDoc.data()?['members'];
      String membersString = '';
      if (membersData is String) {
        membersString = membersData;
      } else if (membersData is List) {
        membersString = membersData.join(',');
      }
      List<String> members =
          membersString.isEmpty ? [] : membersString.split(',');
      members.remove(userId);

      // Handle events list in user
      final eventsData = userDoc.data()?['events'];
      String eventsString = '';
      if (eventsData is String) {
        eventsString = eventsData;
      } else if (eventsData is List) {
        eventsString = eventsData.join(',');
      }
      List<String> events = eventsString.isEmpty ? [] : eventsString.split(',');
      events.remove(eventId);

      // Update both documents
      await _firestore.collection('events').doc(eventId).update({
        'members': members.isEmpty ? '' : members.join(','),
      });

      await _firestore.collection('users').doc(userId).update({
        'events': events.isEmpty ? '' : events.join(','),
      });

      // Update local database
      await updateEventMembers(eventId, members);

      return true;
    } catch (e) {
      print('Error removing member from event: $e');
      return false;
    }
  }
}
