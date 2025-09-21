class CurrencyIconMapper {
  static const Map<String, String> _currencyIcons = {
    'AVAX': 'assets/images/currencies/avax.png',
    'BNB': 'assets/images/currencies/bnb.png',
    'ETH': 'assets/images/currencies/eth.png',
    'MATIC': 'assets/images/currencies/matic.png',
    'SOL': 'assets/images/currencies/sol.png',
    'USDC': 'assets/images/currencies/usdc.png',
    'USDT': 'assets/images/currencies/usdt.png',
    'XOF': 'assets/images/currencies/xof.png',
  };

  /// Returns the local asset path for a given currency code
  /// Falls back to null if no icon is found for the currency
  static String? getIconPath(String currencyCode) {
    return _currencyIcons[currencyCode.toUpperCase()];
  }

  /// Returns true if a local icon exists for the given currency code
  static bool hasIcon(String currencyCode) {
    return _currencyIcons.containsKey(currencyCode.toUpperCase());
  }

  /// Returns all available currency codes that have local icons
  static List<String> getAvailableCurrencies() {
    return _currencyIcons.keys.toList();
  }
}