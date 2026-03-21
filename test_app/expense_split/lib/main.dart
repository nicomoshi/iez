import 'package:flutter/material.dart';

void main() {
  runApp(const ExpenseSplitApp());
}

class ExpenseSplitApp extends StatelessWidget {
  const ExpenseSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Split',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const GroupListScreen(),
    );
  }
}

class Person {
  final String name;
  double balance;
  Person({required this.name, this.balance = 0});
}

class Expense {
  final String description;
  final double amount;
  final String paidBy;
  final List<String> splitWith;
  final DateTime date;

  Expense({
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitWith,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final List<Person> _members = [
    Person(name: 'Alice'),
    Person(name: 'Bob'),
    Person(name: 'Charlie'),
  ];

  final List<Expense> _expenses = [
    Expense(description: 'Dinner', amount: 90, paidBy: 'Alice', splitWith: ['Alice', 'Bob', 'Charlie']),
    Expense(description: 'Taxi', amount: 30, paidBy: 'Bob', splitWith: ['Alice', 'Bob']),
    Expense(description: 'Movie tickets', amount: 45, paidBy: 'Charlie', splitWith: ['Alice', 'Bob', 'Charlie']),
  ];

  double get _totalExpenses => _expenses.fold(0, (sum, e) => sum + e.amount);

  Map<String, double> get _balances {
    final balances = <String, double>{};
    for (final m in _members) {
      balances[m.name] = 0;
    }
    for (final e in _expenses) {
      final share = e.amount / e.splitWith.length;
      balances[e.paidBy] = (balances[e.paidBy] ?? 0) + e.amount;
      for (final p in e.splitWith) {
        balances[p] = (balances[p] ?? 0) - share;
      }
    }
    return balances;
  }

  void _addExpense() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String paidBy = _members.first.name;
    Set<String> splitWith = _members.map((m) => m.name).toSet();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (descController.text.isNotEmpty && amount != null) {
                if (splitWith.isEmpty) splitWith = _members.map((m) => m.name).toSet();
                setState(() {
                  _expenses.add(Expense(
                    description: descController.text,
                    amount: amount,
                    paidBy: paidBy,
                    splitWith: splitWith.toList(),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addMember() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _members.add(Person(name: controller.text)));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balances = _balances;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expense Split'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses', icon: Icon(Icons.receipt_long)),
              Tab(text: 'Balances', icon: Icon(Icons.account_balance_wallet)),
              Tab(text: 'Members', icon: Icon(Icons.people)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Expenses Tab
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${_totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: _expenses.isEmpty
                      ? const Center(child: Text('No expenses yet'))
                      : ListView.builder(
                          itemCount: _expenses.length,
                          itemBuilder: (ctx, i) {
                            final e = _expenses[i];
                            return ListTile(
                              leading: CircleAvatar(child: Text(e.paidBy[0])),
                              title: Text(e.description),
                              subtitle: Text('Paid by ${e.paidBy} · Split ${e.splitWith.length} ways'),
                              trailing: Text(
                                '\$${e.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            // Balances Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Who Owes What', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...balances.entries.map((entry) {
                  final color = entry.value >= 0 ? Colors.green : Colors.red;
                  final label = entry.value >= 0 ? 'is owed' : 'owes';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: Icon(
                          entry.value >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: color,
                        ),
                      ),
                      title: Text(entry.key),
                      subtitle: Text('$label \$${entry.value.abs().toStringAsFixed(2)}'),
                      trailing: Text(
                        '${entry.value >= 0 ? '+' : ''}\$${entry.value.toStringAsFixed(2)}',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Settle Up'),
                        content: const Text('Mark all balances as settled?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          FilledButton(
                            onPressed: () {
                              setState(() => _expenses.clear());
                              Navigator.pop(ctx);
                            },
                            child: const Text('Settle'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Settle Up'),
                ),
              ],
            ),
            // Members Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${_members.length} Members', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._members.map((m) => Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(m.name[0])),
                        title: Text(m.name),
                        subtitle: Text('Balance: \$${(balances[m.name] ?? 0).toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            if (_members.length > 2) {
                              setState(() => _members.remove(m));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Need at least 2 members')),
                              );
                            }
                          },
                        ),
                      ),
                    )),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addMember,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Member'),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addExpense,
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
        ),
      ),
    );
  }
}
