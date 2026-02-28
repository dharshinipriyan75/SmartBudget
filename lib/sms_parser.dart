import 'sb_transaction.dart';

class SmsParser {
  SBTransaction? parse(String body) {
    final normalized = body.toLowerCase();

    // Step 1: Filter non-transaction messages
    if (!_isTransaction(normalized)) {
      return null;
    }

    final amount = _extractAmount(normalized);
    final type = _extractType(normalized);
    final merchant = _extractMerchant(normalized);
    final date = _extractDate(normalized);

    if (amount == null || type == null || date == null) {
      return null;
    }

    return SBTransaction(
      id: DateTime.now().millisecondsSinceEpoch,
      amount: amount,
      merchant: merchant,
      timestamp: date,
      type: type,
    );
  }

  bool _isTransaction(String text) {
    return text.contains("debit") ||
        text.contains("credit") ||
        text.contains("spent");
  }

  double? _extractAmount(String text) {
    final regex = RegExp(r'(rs\.?|inr|₹|by|with|for)\s?([\d,]+\.?\d*)');
    final match = regex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(2)!.replaceAll(",", ""));
    }
    return null;
  }

  String? _extractType(String text) {
    if (text.contains("debit")) return "debit";
    if (text.contains("credit")) return "credit";
    if (text.contains('spent')) return 'debit';
    return null;
  }

  String _extractMerchant(String text) {
    final regex = RegExp(
      r'(to|at|towards|from)\s+([a-z0-9&./]+)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);

    Set<String> merchants = {
      "swiggy",
      "zomato",
      "zepto",
      "ola",
      "uber",
      "amazon",
      "flipkart",
      "spotify",
    };

    if (match != null) {
      String merchant = match.group(2)!.toLowerCase();

      if (merchants.contains(merchant)) {
        return merchant;
      } else {
        return "miscellaneous";
      }
    }

    return "miscellaneous";
  }

  DateTime? _extractDate(String text) {
    final regex = RegExp(
      r'\b(\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\b',
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      final dateStr = match.group(0)!;

      final normalized = dateStr.replaceAll('-', '/');
      final parts = normalized.split('/');

      if (parts.length == 3 && parts[0].length == 4) {
        final day = int.parse(parts[2]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[0]);

        return DateTime(year, month, day);
      } else {
        final year = int.parse(parts[2]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[0]);

        return DateTime(year, month, day);
      }
    }
    return null;
  }
}
