import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_wallet/providers/wallet_provider.dart';
import 'package:smart_wallet/widgets/expense_chart.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<WalletProvider>().loadTransactions());
  }

  void _showSetBudgetDialog(String category) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Budget for $category'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Limit',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(controller.text) ?? 0.0;
              if (limit > 0) {
                context.read<WalletProvider>().setCategoryBudget(category, limit);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Limit'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Transaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Description / Payee',
                hintText: 'e.g., Swiggy, Jio Recharge, Auto Fare',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('Expense (Debit)')),
                DropdownMenuItem(value: 'income', child: Text('Income (Credit)')),
              ],
              onChanged: (val) {
                if (val != null) selectedType = val;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final title = titleController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (title.isNotEmpty && amount > 0) {
                  context.read<WalletProvider>().addTransaction(title, amount, selectedType);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Record', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final categoryTotals = wallet.getCategoryExpenseTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Wallet '),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Analytics Card
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          'Spending Analytics',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    wallet.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Text(
                            wallet.aiInsight,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: wallet.analyzeSpending,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Insights'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pie Chart Section
            if (categoryTotals.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ExpensePieChart(categoryTotals: categoryTotals),
              ),
              const SizedBox(height: 16),
            ],

            // Category Budgets Section
            if (categoryTotals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Category Budgets',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...categoryTotals.keys.map((cat) {
                      final spent = categoryTotals[cat] ?? 0.0;
                      final limit = wallet.budgets[cat] ?? 0.0;
                      final double progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                      final isOver = limit > 0 && spent > limit;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                                GestureDetector(
                                  onTap: () => _showSetBudgetDialog(cat),
                                  child: Text(
                                    limit > 0 ? 'Limit: ₹${limit.toStringAsFixed(0)}' : '+ Set Budget',
                                    style: TextStyle(
                                      color: limit > 0 ? Colors.indigo : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade300,
                              color: isOver ? Colors.red : (progress > 0.8 ? Colors.orange : Colors.green),
                              minHeight: 6,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Spent: ₹${spent.toStringAsFixed(2)}${limit > 0 ? ' of ₹${limit.toStringAsFixed(0)}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOver ? Colors.red : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Transactions History Header
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),

            // Transactions List
            wallet.transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No transactions logged.\nTap + to enter UPI or cash transactions.', textAlign: TextAlign.center),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: wallet.transactions.length,
                    itemBuilder: (context, i) {
                      final tx = wallet.transactions[i];
                      final isExpense = tx.type == 'expense';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
                          child: Icon(
                            isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${tx.category} • ${tx.date.split('T').first}'),
                        trailing: Text(
                          '${isExpense ? '-' : '+'}\u{20B9}${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}