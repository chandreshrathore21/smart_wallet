import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/ai_services.dart';

class WalletProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final LocalAnalyticsService _analyticsService = LocalAnalyticsService();

  List<TransactionModel> _transactions = [];
  Map<String, double> _budgets = {};
  String _aiInsight = 'Tap button to generate local financial summary.';
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  Map<String, double> get budgets => _budgets;
  String get aiInsight => _aiInsight;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions() async {
    _transactions = await _dbHelper.getAllTransactions();
    final budgetList = await _dbHelper.getAllBudgets();
    _budgets = {for (var b in budgetList) b.category: b.monthlyLimit};
    notifyListeners();
  }

  Future<void> addTransaction(String title, double amount, String type) async {
    _isLoading = true;
    notifyListeners();

    final category = _analyticsService.predictCategory(title);
    final tx = TransactionModel(
      title: title,
      amount: amount,
      category: category,
      type: type,
      date: DateTime.now().toIso8601String(),
    );
    await _dbHelper.insertTransaction(tx);

    _isLoading = false;
    await loadTransactions();
  }

  Future<void> setCategoryBudget(String category, double limit) async {
    await _dbHelper.setBudget(BudgetModel(category: category, monthlyLimit: limit));
    await loadTransactions();
  }

  Future<void> analyzeSpending() async {
    _isLoading = true;
    notifyListeners();

    _aiInsight = await _analyticsService.generateFinancialInsights();

    _isLoading = false;
    notifyListeners();
  }

  Map<String, double> getCategoryExpenseTotals() {
    Map<String, double> totals = {};
    for (var tx in _transactions) {
      if (tx.type == 'expense') {
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
      }
    }
    return totals;
  }
}