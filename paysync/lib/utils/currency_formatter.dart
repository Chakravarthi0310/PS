import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String currencyName) {
    final decimalPoints = _getDecimalPoints(currencyName);
    return NumberFormat.currency(
      symbol: _getCurrencySymbol(currencyName),
      decimalDigits: decimalPoints,
    ).format(amount);
  }

  static int _getDecimalPoints(String currencyName) {
    switch (currencyName) {
      case 'JPY' || '¥':
        return 0;
      case 'INR' || '₹':
        return 2;
      default:
        return 2;
    }
  }

  static String _getCurrencySymbol(String currencyName) {
    switch (currencyName) {
      case 'USD' || '\$':
        return '\$';
      case 'EUR' || '€':
        return '€';
      case 'GBP' || '£':
        return '£';
      case 'JPY' || '¥':
        return '¥';
      case 'INR' || '₹':
        return '₹';
      default:
        return '\$';
    }
  }
}
