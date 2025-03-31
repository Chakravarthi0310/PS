class CurrencyConverter {
  // Exchange rates (as of a fixed date, you might want to use an API for real-time rates)
  static final Map<String, double> _ratesInUSD = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 149.45,
    'INR': 83.12,
  };

  static String _getCurrencyCode(String currencyInput) {
    switch (currencyInput) {
      case 'USD' || '\$':
        return 'USD';
      case 'EUR' || '€':
        return 'EUR';
      case 'GBP' || '£':
        return 'GBP';
      case 'JPY' || '¥':
        return 'JPY';
      case 'INR' || '₹':
        return 'INR';
      default:
        return currencyInput;
    }
  }

  static double convert(double amount, String fromCurrency, String toCurrency) {
    final fromCode = _getCurrencyCode(fromCurrency);
    final toCode = _getCurrencyCode(toCurrency);

    if (!_ratesInUSD.containsKey(fromCode) || !_ratesInUSD.containsKey(toCode)) {
      return amount;
    }

    double amountInUSD = amount / _ratesInUSD[fromCode]!;
    return amountInUSD * _ratesInUSD[toCode]!;
  }

  // Add method to get all supported currencies
  static List<String> getSupportedCurrencies() {
    return _ratesInUSD.keys.toList();
  }

  // Add method to get currency symbol
  static String getSymbol(String currencyCode) {
    switch (_getCurrencyCode(currencyCode)) {
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
        return currencyCode;
    }
  }
}