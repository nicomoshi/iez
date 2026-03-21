import 'package:flutter/material.dart';

void main() => runApp(const ProjectBoardApp());

class ProjectBoardApp extends StatelessWidget {
  const ProjectBoardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Board',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const BoardHome(),
    );
  }
}

class BoardCard {
  String title;
  String assignee;
  String priority;
  String status; // Todo, In Progress, Done
  BoardCard({
    required this.title,
    required this.assignee,
    required this.priority,
    required this.status,
  });
}

class BoardHome extends StatefulWidget {
  const BoardHome({super.key});
  @override
  State<BoardHome> createState() => _BoardHomeState();
}

class _BoardHomeState extends State<BoardHome> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<BoardCard> _cards = [
    BoardCard(title: 'Design Login Page', assignee: 'Alice', priority: 'High', status: 'Todo'),
    BoardCard(title: 'Setup CI Pipeline', assignee: 'Bob', priority: 'High', status: 'Todo'),
    BoardCard(title: 'Write Unit Tests', assignee: 'Carol', priority: 'Medium', status: 'Todo'),
    BoardCard(title: 'API Authentication', assignee: 'Alice', priority: 'High', status: 'In Progress'),
    BoardCard(title: 'Database Schema', assignee: 'Bob', priority: 'Medium', status: 'In Progress'),
    BoardCard(title: 'Project Setup', assignee: 'Carol', priority: 'Low', status: 'Done'),
    BoardCard(title: 'Requirements Doc', assignee: 'David', priority: 'Low', status: 'Done'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<BoardCard> _forStatus(String status) => _cards.where((c) => c.status == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Stats',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => BoardStatsPage(cards: _cards))),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: 'Todo (${_forStatus("Todo").length})'),
            Tab(text: 'In Progress (${_forStatus("In Progress").length})'),
            Tab(text: 'Done (${_forStatus("Done").length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildColumn('Todo'),
          _buildColumn('In Progress'),
          _buildColumn('Done'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Card',
        onPressed: () async {
          final result = await Navigator.push<Map<String, String>>(context,
              MaterialPageRoute(builder: (_) => const AddCardPage()));
          if (result != null) {
            setState(() => _cards.add(BoardCard(
              title: result['title']!,
              assignee: result['assignee']!,
              priority: result['priority']!,
              status: 'Todo',
            )));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildColumn(String status) {
    final items = _forStatus(status);
    if (items.isEmpty) {
      return const Center(child: Text('No cards'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final card = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(card.title),
            subtitle: Text('${card.assignee} · ${card.priority}'),
            trailing: Icon(
              card.priority == 'High' ? Icons.priority_high :
              card.priority == 'Medium' ? Icons.remove : Icons.arrow_downward,
              color: card.priority == 'High' ? Colors.red :
                     card.priority == 'Medium' ? Colors.orange : Colors.green,
            ),
          ),
        );
      },
    );
  }
}

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});
  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _titleCtrl = TextEditingController();
  final _assigneeCtrl = TextEditingController();
  String _priority = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Card')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Card title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _assigneeCtrl,
              decoration: const InputDecoration(labelText: 'Assignee', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              items: ['High', 'Medium', 'Low'].map((p) =>
                  DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'title': _titleCtrl.text,
                      'assignee': _assigneeCtrl.text.isEmpty ? 'Unassigned' : _assigneeCtrl.text,
                      'priority': _priority,
                    });
                  }
                },
                child: const Text('Save Card'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardStatsPage extends StatelessWidget {
  final List<BoardCard> cards;
  const BoardStatsPage({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final byStatus = <String, int>{};
    final byPriority = <String, int>{};
    for (final c in cards) {
      byStatus[c.status] = (byStatus[c.status] ?? 0) + 1;
      byPriority[c.priority] = (byPriority[c.priority] ?? 0) + 1;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Board Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Total Cards: ${cards.length}'),
                  ...byStatus.entries.map((e) => Text('${e.key}: ${e.value}')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('By Priority', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...['High', 'Medium', 'Low'].map((p) => ListTile(
            title: Text(p),
            trailing: Chip(label: Text('${byPriority[p] ?? 0}')),
          )),
        ],
      ),
    );
  }
}
