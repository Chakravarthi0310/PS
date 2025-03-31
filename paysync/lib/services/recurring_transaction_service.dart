import 'package:paysync/database/database_helper.dart';
import 'package:paysync/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class RecurringTransactionService {
  static Future<DateTime> getNextTransactionDate(
    DateTime lastTransaction,
    String recurringType,
  ) {
    switch (recurringType) {
      case 'Daily':
        return Future.value(lastTransaction.add(Duration(days: 1)));
      case 'Weekly':
        return Future.value(lastTransaction.add(Duration(days: 7)));
      case 'Monthly':
        return Future.value(
          DateTime(
            lastTransaction.year,
            lastTransaction.month + 1,
            lastTransaction.day,
          ),
        );
      case 'Yearly':
        return Future.value(
          DateTime(
            lastTransaction.year + 1,
            lastTransaction.month,
            lastTransaction.day,
          ),
        );
      default:
        throw Exception('Invalid recurring type');
    }
  }

  static Future<void> scheduleNextTransaction(
    TransactionModel transaction,
  ) async {
    if (!transaction.recurring || transaction.recurringType == null) return;

    final nextDate = await getNextTransactionDate(
      transaction.dateTime,
      transaction.recurringType!,
    );

    // Get current user details
    final userDetails = await DatabaseHelper().getUser(transaction.userId);
    if (userDetails == null) return;

    // Calculate new balances
    final newOnlineBalance =
        transaction.isOnline
            ? (userDetails.onlineAmount +
                (transaction.isCredit
                    ? transaction.amount
                    : -transaction.amount))
            : userDetails.onlineAmount;

    final newOfflineBalance =
        !transaction.isOnline
            ? (userDetails.offlineAmount +
                (transaction.isCredit
                    ? transaction.amount
                    : -transaction.amount))
            : userDetails.offlineAmount;

    // Create next transaction
    final nextTransaction = TransactionModel(
      transactionId: Uuid().v4(),
      userId: transaction.userId,
      eventId: transaction.eventId,
      isOnline: transaction.isOnline,
      isCredit: transaction.isCredit,
      amount: transaction.amount,
      currency: transaction.currency,
      paymentMethod: transaction.paymentMethod,
      location: transaction.location,
      dateTime: nextDate,
      note: transaction.note,
      imageUrl: transaction.imageUrl,
      recurring: true,
      recurringType: transaction.recurringType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      onlineBalanceAfter: newOnlineBalance,
      offlineBalanceAfter: newOfflineBalance,
    );

    await DatabaseHelper().insertTransaction(nextTransaction);

    // Update user balances
    userDetails.onlineAmount = newOnlineBalance;
    userDetails.offlineAmount = newOfflineBalance;
    await DatabaseHelper().updateUser(userDetails);
  }
}
