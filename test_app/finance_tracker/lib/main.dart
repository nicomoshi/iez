import 'package:flutter/material.dart';

void main() {
  runApp(const FinanceTrackerApp());
}

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
  final String notes;
  final bool recurring;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.notes = '',
    this.recurring = false,
  });
}

class AppState extends ChangeNotifier {
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      description: 'March Salary',
      amount: 4500,
      date: DateTime(2026, 3, 1),
      category: 'Salary',
      type: TransactionType.income,
      notes: 'Monthly salary deposit',
    ),
    Transaction(
      id: '2',
      description: 'Grocery Store',
      amount: 85,
      date: DateTime(2026, 3, 18),
      category: 'Food',
      type: TransactionType.expense,
      notes: 'Weekly groceries',
    ),
    Transaction(
      id: '3',
      description: 'Electric Bill',
      amount: 120,
      date: DateTime(2026, 3, 15),
      category: 'Bills',
      type: TransactionType.expense,
      notes: 'Monthly electric bill',
    ),
    Transaction(
      id: '4',
      description: 'Netflix',
      amount: 15,
      date: DateTime(2026, 3, 1),
      category: 'Entertainment',
      type: TransactionType.expense,
      notes: 'Monthly subscription',
      recurring: true,
    ),
    Transaction(
      id: '5',
      description: 'Uber Ride',
      amount: 25,
      date: DateTime(2026, 3, 20),
      category: 'Transport',
      type: TransactionType.expense,
      notes: 'Ride to downtown',
    ),
    Transaction(
      id: '6',
      description: 'Freelance Project',
      amount: 800,
      date: DateTime(2026, 3, 10),
      category: 'Salary',
      type: TransactionType.income,
      notes: 'Web development project',
    ),
    Transaction(
      id: '7',
      description: 'New Shoes',
      amount: 95,
      date: DateTime(2026, 3, 12),
      category: 'Shopping',
      type: TransactionType.expense,
      notes: 'Running shoes',
    ),
  ];

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  double get totalBalance {
    double balance = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.income) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  double get totalIncome {
    double sum = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.income) sum += t.amount;
    }
    return sum;
  }

  double get totalExpenses {
    double sum = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.expense) sum += t.amount;
    }
    return sum;
  }

  void addTransaction(Transaction t) {
    _transactions.add(t);
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Map<String, double> get spendingByCategory {
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }
}

class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  final appState = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Finance Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          home: HomeScreen(appState: appState),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';

  List<Transaction> get _filteredTransactions {
    final txns = widget.appState.transactions;
    switch (_selectedFilter) {
      case 'Income':
        return txns.where((t) => t.type == TransactionType.income).toList();
      case 'Expenses':
        return txns.where((t) => t.type == TransactionType.expense).toList();
      case 'Recurring':
        return txns.where((t) => t.recurring).toList();
      default:
        return txns;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    final filtered = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Tracker'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Reports') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportsScreen(appState: state),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Reports',
                child: Text('Reports'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryItem('Total Balance', state.totalBalance, Colors.indigo),
                      _summaryItem('Income', state.totalIncome, Colors.green),
                      _summaryItem('Expenses', state.totalExpenses, Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Income', 'Expenses', 'Recurring'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? filter : 'All';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Transaction List
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final t = filtered[index];
                final isIncome = t.type == TransactionType.income;
                final amountStr = isIncome
                    ? '+${t.amount.toStringAsFixed(0)}'
                    : '-${t.amount.toStringAsFixed(0)}';
                return ListTile(
                  title: Text(t.description),
                  subtitle: Row(
                    children: [
                      Text(_formatDate(t.date)),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(t.category),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      if (t.recurring) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.repeat, size: 16),
                      ],
                    ],
                  ),
                  trailing: Text(
                    amountStr,
                    style: TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          transaction: t,
                          appState: widget.appState,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(appState: state),
            ),
          );
        },
        label: const Text('Add Transaction'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class DetailScreen extends StatelessWidget {
  final Transaction transaction;
  final AppState appState;

  const DetailScreen({
    super.key,
    required this.transaction,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;
    final amountStr = isIncome
        ? '+${t.amount.toStringAsFixed(0)}'
        : '-${t.amount.toStringAsFixed(0)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.description,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              amountStr,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Date', _formatDate(t.date)),
            _detailRow('Category', t.category),
            _detailRow('Type', isIncome ? 'Income' : 'Expense'),
            if (t.recurring) _detailRow('Recurring', 'Yes'),
            const SizedBox(height: 16),
            const Text(
              'Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              t.notes.isNotEmpty ? t.notes : 'No notes',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit not implemented')),
                      );
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      appState.deleteTransaction(t.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class AddTransactionScreen extends StatefulWidget {
  final AppState appState;
  const AddTransactionScreen({super.key, required this.appState});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'Salary';
  TransactionType _type = TransactionType.expense;

  final List<String> _categories = [
    'Salary',
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Type: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Income'),
                  selected: _type == TransactionType.income,
                  onSelected: (selected) {
                    if (selected) setState(() => _type = TransactionType.income);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Expense'),
                  selected: _type == TransactionType.expense,
                  onSelected: (selected) {
                    if (selected) setState(() => _type = TransactionType.expense);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final desc = _descriptionController.text.trim();
                final amountText = _amountController.text.trim();
                if (desc.isEmpty || amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }
                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                widget.appState.addTransaction(Transaction(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  description: desc,
                  amount: amount,
                  date: DateTime.now(),
                  category: _category,
                  type: _type,
                  notes: _notesController.text.trim(),
                ));
                Navigator.pop(context);
              },
              child: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  final AppState appState;
  const ReportsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final income = appState.totalIncome;
    final expenses = appState.totalExpenses;
    final balance = appState.totalBalance;
    final savingsRate = income > 0 ? (balance / income * 100) : 0.0;
    final spending = appState.spendingByCategory;
    final sortedCategories = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'March 2026 Summary',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _reportRow('Total Income', income.toStringAsFixed(0), Colors.green),
                    _reportRow('Total Expenses', expenses.toStringAsFixed(0), Colors.red),
                    const Divider(),
                    _reportRow('Net Balance', balance.toStringAsFixed(0), Colors.indigo),
                    const SizedBox(height: 8),
                    _reportRow(
                      'Savings Rate',
                      '${savingsRate.toStringAsFixed(1)}%',
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Spending by Category
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spending by Category',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...sortedCategories.map((entry) {
                      final pct = expenses > 0
                          ? (entry.value / expenses * 100)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key,
                                    style: const TextStyle(fontSize: 14)),
                                Text(
                                  '${entry.value.toStringAsFixed(0)} (${pct.toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
