import '../database/database_helper.dart';

class LocalAnalyticsService {
  /// Local rule-based categorization tailored for Indian payment descriptions
  String predictCategory(String title) {
    final lower = title.toLowerCase();
    
    if (lower.contains('swiggy') || lower.contains('zomato') || lower.contains('food') || lower.contains('grocery') || lower.contains('blinkit') || lower.contains('zepto') || lower.contains('dhaba') || lower.contains('cafe')) {
      return 'Food & Dining';
    } else if (lower.contains('uber') || lower.contains('ola') || lower.contains('rapido') || lower.contains('fuel') || lower.contains('petrol') || lower.contains('auto') || lower.contains('metro') || lower.contains('irctc')) {
      return 'Transport';
    } else if (lower.contains('recharge') || lower.contains('jio') || lower.contains('airtel') || lower.contains('electricity') || lower.contains('rent') || lower.contains('bill')) {
      return 'Bills & Recharges';
    } else if (lower.contains('salary') || lower.contains('stipend') || lower.contains('upi cashback') || lower.contains('interest')) {
      return 'Income';
    } else if (lower.contains('amazon') || lower.contains('flipkart') || lower.contains('myntra') || lower.contains('shopping')) {
      return 'Shopping';
    } else if (lower.contains('movie') || lower.contains('bookmyshow') || lower.contains('hotstar') || lower.contains('prime')) {
      return 'Entertainment';
    }
    
    return 'General';
  }

  /// Calculates real-time spending insights in Indian Rupees (₹)
  Future<String> generateFinancialInsights() async {
    final transactions = await DatabaseHelper().getAllTransactions();

    if (transactions.isEmpty) {
      return 'No transactions logged yet. Add your daily UPI or cash expenses to view insights.';
    }

    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryExpenses = {};

    for (var tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        categoryExpenses[tx.category] = (categoryExpenses[tx.category] ?? 0) + tx.amount;
      }
    }

    String highestCategory = 'None';
    double highestAmount = 0;
    categoryExpenses.forEach((category, amount) {
      if (amount > highestAmount) {
        highestAmount = amount;
        highestCategory = category;
      }
    });

    final double savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100) : 0;

    StringBuffer insight = StringBuffer();
    insight.writeln('• Total Outflow: ₹${totalExpense.toStringAsFixed(2)} | Total Inflow: ₹${totalIncome.toStringAsFixed(2)}');
    
    if (highestAmount > 0) {
      insight.writeln('• Highest spending area: $highestCategory (₹${highestAmount.toStringAsFixed(2)})');
    }
    
    if (totalIncome > 0) {
      insight.writeln('• Current Savings Ratio: ${savingsRate.toStringAsFixed(1)}%');
    } else if (totalExpense > 0) {
      insight.writeln('• Alert: Expenses recorded without corresponding income entries.');
    }

    return insight.toString();
  }
}