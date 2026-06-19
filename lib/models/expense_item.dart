import 'category.dart';

class ExpenseItem {
  Category? category;
  String price;
  String comment;

  ExpenseItem({this.category, this.price = '', this.comment = ''});

  bool get isValid => category != null && price.isNotEmpty && parsedPrice > 0;

  double get parsedPrice {
    final cleaned = price.replaceAll(',', '.').trim();
    // Ewaluacja wyrażeń: 12+3, 50-10
    try {
      return _evalExpr(cleaned);
    } catch (_) {
      return 0;
    }
  }

  double _evalExpr(String expr) {
    final parts = RegExp(r'[+\-]?[0-9]*\.?[0-9]+').allMatches(expr);
    return parts.fold(0.0, (sum, m) => sum + double.parse(m.group(0)!));
  }
}
