import 'package:flutter/material.dart';

void main() => runApp(const BudgetPlannerApp());

class BudgetPlannerApp extends StatelessWidget {
  const BudgetPlannerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const BudgetHome(),
    );
  }
}

class Transaction {
  final String title;
  final double amount;
  final String category;
  final bool isIncome;
  final String date;
  Transaction({
    required this.title,
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.date,
  });
}

class BudgetHome extends StatefulWidget {
  const BudgetHome({super.key});
  @override
  State<BudgetHome> createState() => _BudgetHomeState();
}

class _BudgetHomeState extends State<BudgetHome> {
  String _filter = 'All';
  final List<Transaction> _transactions = [
    Transaction(title: 'Salary', amount: 5000, category: 'Income', isIncome: true, date: 'Mar 1'),
    Transaction(title: 'Rent', amount: 1500, category: 'Housing', isIncome: false, date: 'Mar 1'),
    Transaction(title: 'Groceries', amount: 320, category: 'Food', isIncome: false, date: 'Mar 3'),
    Transaction(title: 'Netflix', amount: 15, category: 'Entertainment', isIncome: false, date: 'Mar 5'),
    Transaction(title: 'Freelance Work', amount: 800, category: 'Income', isIncome: true, date: 'Mar 7'),
    Transaction(title: 'Gas', amount: 60, category: 'Transport', isIncome: false, date: 'Mar 8'),
    Transaction(title: 'Gym Membership', amount: 50, category: 'Health', isIncome: false, date: 'Mar 10'),
    Transaction(title: 'Restaurant', amount: 85, category: 'Food', isIncome: false, date: 'Mar 12'),
  ];

  double get _totalIncome => _transactions.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  double get _totalExpenses => _transactions.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);
  double get _balance => _totalIncome - _totalExpenses;

  List<Transaction> get _filtered {
    if (_filter == 'All') return _transactions;
    if (_filter == 'Income') return _transactions.where((t) => t.isIncome).toList();
    if (_filter == 'Expenses') return _transactions.where((t) => !t.isIncome).toList();
    return _transactions.where((t) => t.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Summary',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SummaryPage(transactions: _transactions))),
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance card
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Balance', style: TextStyle(fontSize: 16)),
                  Text('\$${_balance.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _balance >= 0 ? Colors.green : Colors.red)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        const Text('Income', style: TextStyle(color: Colors.green)),
                        Text('\$${_totalIncome.toStringAsFixed(0)}'),
                      ]),
                      Column(children: [
                        const Text('Expenses', style: TextStyle(color: Colors.red)),
                        Text('\$${_totalExpenses.toStringAsFixed(0)}'),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: ['All', 'Income', 'Expenses', 'Food', 'Housing', 'Transport'].map((f) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: FilterChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              )).toList(),
            ),
          ),
          // Transaction list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No transactions found'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final tx = _filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.isIncome ? Colors.green[100] : Colors.red[100],
                          child: Icon(
                            tx.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                            color: tx.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(tx.title),
                        subtitle: Text('${tx.category} · ${tx.date}'),
                        trailing: Text(
                          '${tx.isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tx.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Transaction',
        onPressed: () async {
          final result = await Navigator.push<Map<String, dynamic>>(context,
              MaterialPageRoute(builder: (_) => const AddTransactionPage()));
          if (result != null) {
            setState(() => _transactions.add(Transaction(
              title: result['title'],
              amount: result['amount'],
              category: result['category'],
              isIncome: result['isIncome'],
              date: 'Mar 15',
            )));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});
  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'Food';
  bool _isIncome = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ['Food', 'Housing', 'Transport', 'Entertainment', 'Health', 'Income'].map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Income'),
              value: _isIncome,
              onChanged: (v) => setState(() => _isIncome = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleCtrl.text.isNotEmpty && _amountCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'title': _titleCtrl.text,
                      'amount': double.tryParse(_amountCtrl.text) ?? 0,
                      'category': _category,
                      'isIncome': _isIncome,
                    });
                  }
                },
                child: const Text('Save Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryPage extends StatelessWidget {
  final List<Transaction> transactions;
  const SummaryPage({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final expenses = transactions.where((t) => !t.isIncome).toList();
    final byCategory = <String, double>{};
    for (final tx in expenses) {
      byCategory[tx.category] = (byCategory[tx.category] ?? 0) + tx.amount;
    }
    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalExpenses = expenses.fold<double>(0, (s, t) => s + t.amount);
    final totalIncome = transactions.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Monthly Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Total Income: \$${totalIncome.toStringAsFixed(0)}'),
                  Text('Total Expenses: \$${totalExpenses.toStringAsFixed(0)}'),
                  Text('Savings: \$${(totalIncome - totalExpenses).toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Expenses by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...sorted.map((entry) {
            final pct = totalExpenses > 0 ? entry.value / totalExpenses : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('\$${entry.value.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: pct, minHeight: 8),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
